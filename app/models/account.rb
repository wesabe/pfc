class Account < ActiveRecord::Base
  concerned_with :uploads
  concerned_with :sample
  concerned_with :status

  scope :visible, :conditions => {:status => Status::VISIBLE}
  scope :for_user, lambda {|user| {:conditions => {:account_key => user.account_key}} }

  belongs_to :user, :foreign_key => 'account_key', :primary_key => 'account_key'
  belongs_to :financial_inst
  belongs_to :account_cred

  has_many :txactions,
           :include => [:merchant, :taggings, :txaction_type, :account],
           :conditions => ["txactions.status = ?", Txaction::Status::ACTIVE],
           :order => 'date_posted desc, sequence, txactions.created_at desc'
  # REVIEW: not sure if there's a better name, but the above txactions association
  # loads the merchant, taggings, txaction_type, and account, and there are times where that's not needed
  has_many :simple_txactions,
           :class_name => "Txaction",
           :conditions => ["txactions.status = ?", Txaction::Status::ACTIVE],
           :order => 'date_posted desc, sequence, txactions.created_at desc'
  has_many :all_txactions,
           :class_name => "Txaction",
           :dependent => :destroy
  has_many :account_balances,
           :order => 'balance_date desc',
           :conditions => ['account_balances.status = ?', Constants::Status::ACTIVE],
           :dependent => :destroy
  has_one :last_balance,
          :class_name => 'AccountBalance',
          :order => 'account_balances.balance_date desc, account_balances.created_at desc',
          :conditions => ['account_balances.status = ?', Constants::Status::ACTIVE]

  attr_accessor :untagged_amount
  attr_accessor :newly_created  # used by ofx2importer

  attr_protected :id_for_user, :guid

  before_create :generate_guid
  before_validation :generate_id_for_user, :on => :create
  before_validation :generate_name, :on => :create
  before_create :truncate_account_number
  before_validation :fix_id_for_user

  validates_uniqueness_of :id_for_user, :scope => :account_key
  validates_presence_of :name
  validate :currency_is_not_blank_or_yaml

  URI_PATTERN = %r{^/accounts/(\d+)$}

  #---------------------------------------------------------------------------
  # public class methods
  #

  def self.find_or_create(account)
    if existing_account = find(:first, :order => "status ASC",
      :conditions => ["account_key = ? and account_number = ? and account_type_id = ? \
                       and status != ? and financial_inst_id = ?",
                       account.account_key, last4(account.account_number), account.account_type_id,
                       Constants::Status::DELETED, account.financial_inst_id])
      return existing_account
    else
      # FIXME: this is to try to debug "Validation failed" exceptions
      account.save
      raise "Generate name didn't work: #{account.inspect}" if account.new_record?
      return account
    end
  end

  # find account by account number. just match on last 4 digits
  def self.find_account(user, account_number, account_type, financial_inst_id)
    for_user(user).
      where(:account_number => account_number,
            :account_type_id => account_type.id,
            :financial_inst_id => financial_inst_id).
      visible.
      first
  end

  # find account by account number hash
  def self.find_account_by_account_number_hash(user, account_number_hash, account_type, financial_inst_id)
    for_user(user).
      where(:account_number_hash => account_number_hash,
            :account_type_id => account_type.id,
            :financial_inst_id => financial_inst_id).
      visible.
      first
  end

  def self.find_by_uri(uri)
    find_by_id_for_user(uri[%r{^/accounts/([^/]+)$}, 1]) if uri
  end

  # Return last 4 word characters of account number.
  # If a regex is provided, use that to find the "last 4" digits. Up to 6 characters
  # (the size of the accounts.account_number column) can be stored if a regex is provided
  def self.last4(acct_number, regex = nil)
    acct_number = acct_number.to_s.gsub(/\W/,'') # always strip non-word characters
    if regex.present? && m = acct_number.match(/#{regex}/)
      # if the regex doesn't specify any groupings, this is bad, so best to just explode
      if m.length < 2
        raise ArgumentError, "Regex provided, but no groupings specified"
      end

      return m[1..-1].join.last(6) # concatenate all captured groups
    else
      return acct_number.last(4)
    end
  end

  #---------------------------------------------------------------------------
  # public instance methods
  #

  def destroy_deferred
    safe_delete
    Resque.enqueue(DestroyAccount, self.id)
  end

  # override destroy method to set the status to DISABLED if this is an SSU account; otherwise, delete it outright
  def destroy
    _run_destroy_callbacks do
      if new_record? || !ssu?
        super
      elsif account_cred.accounts.count == 1
        super.tap do # delete ourselves first to avoid a loop -- destroying the cred will also destroy any disabled accounts
          account_cred.destroy
        end
      else
        self.class.update_all(["status = ?", Constants::Status::DISABLED], ["id = ?", id])
        false # stop the callback chain
      end
    end
  end

  # set the status of this account and all its txactions to DELETED
  def safe_delete
    update_attribute(:status, Constants::Status::DELETED)
    Txaction.safe_delete(all_txactions)
  end

  # override AR method so we can return a currency object
  def currency
    currency_name = read_attribute('currency')
    Currency.new(currency_name) if currency_name
  end

  def uri
    "/accounts/#{id_for_user}"
  end

  # override AR method so we can set with a Currency object
  def currency=(cur)
    if cur
      write_attribute(:currency, cur.to_s)
    else
      write_attribute(:currency, nil)
    end
  end

  # account type is no longer an AR model, so return account_type the old fashioned way
  def account_type
    AccountType.find(account_type_id)
  end

  def account_type=(obj)
    if obj.is_a?(AccountType)
      self.account_type_id = obj.id
    else
      raise ActiveRecord::AssociationTypeMismatch.new("AccountType expected, got #{obj.class}")
    end
  end

  # return the name of the FI associated with this account, if any. This is a convenience method for
  # financial_inst.name, since some account types (just cash accounts right now) don't have an FI
  def financial_inst_name
    financial_inst.name if financial_inst
  end

  def wesabe_id
    financial_inst.wesabe_id if financial_inst
  end

  def new_txaction
    Txaction.new(:account => self, :status => Constants::Status::ACTIVE)
  end

  # return the current balance for this account
  def balance
    return nil unless has_balance?

    return calculate_balance
  end

  def calculate_balance
    return nil unless has_balance?

    if manual_account? && (most_recent = simple_txactions.first)
      # manual accounts differ in that the last_balance is probably not the balance as of the most recent
      # transaction, so calculate the balance of the most recent txaction
      new_balance = most_recent.calculate_balance!
    else
      last_bal = last_balance(true) # make sure we get the uncached last_balance
      new_balance = (last_bal && last_bal.balance) || 0
    end

    return new_balance
  end

  def money_balance
    return nil unless has_balance?

    return Money.new(balance, currency)
  end

  # return our best guess for the date that the last balance was posted on
  def balance_date
    upload_or_balance = (last_upload || last_balance)
    if upload_or_balance
      upload_or_balance.created_at
    else
      updated_at
    end
  end

  # set the balance for this account
  def balance=(amount)
    raise ArgumentError, "Cannot set balance on account with type #{account_type.name}" unless has_balance?
    # adjust balance date for the user's time zone
    tz = User.current && User.current.time_zone
    balance_date = tz ? Time.now.in_time_zone(tz) : Time.now
    AccountBalance.create!(:account => self, :balance => Currency.normalize(amount).to_d, :balance_date => balance_date)
  end

  def negate_balance!
    update_attribute(:negate_balance, !negate_balance)
    last_balance.update_attribute(:balance, -last_balance.balance) if last_balance
  end

  def last_ssu_job
    account_cred && account_cred.last_ssu_job
  end

  def ssu_candidate?(user)
    financial_inst && !account_cred_id && financial_inst.ssu_support?(user)
  end

  def ssu?
    account_cred_id && last_ssu_job && last_ssu_job.status
  end

  def has_disabled_txactions?
    Txaction.find_by_account_id_and_status(id, Constants::Status::DISABLED)
  end

  def enable_disabled_txactions
    txactions = Txaction.find_all_by_account_id_and_status(id, Constants::Status::DISABLED)
    Txaction.change_status(txactions, Constants::Status::ACTIVE)
  end

  # For the admin tool "Remove all transactions on this account before...",
  # which disables all txactions for a user's account before the end_date.
  # Disabled transactions are not recreated if they are uploaded again.
  def disable_txactions_before_date(end_date)
    Txaction.change_status((self.txactions.find(:all, :conditions => ["date_posted < ?", end_date])), Constants::Status::DISABLED)
  end

  def to_json(options={})
    { 'id' => id_for_user,
      'name' => name,
      'status' => status,
      'hasBalance' => has_balance?,
      'balance' => {
        'USD' => CurrencyExchangeRate.convert_to_usd(balance, currency),
        currency.name => balance,
        'currency' => currency.name },
      'archived' => archived?,
      'active' => active?
    }.to_json
  end

  # Determines whether the last upload tied to a job or credential created this account.
  #
  # @param job_or_cred [SsuJob, AccountCred]
  #   The job or credential to test this account against.
  #
  # @return [Boolean]
  #   +true+ if this account was just created while running the job (or the) cred's latest
  #   job, and +false+ otherwise.
  def newly_created_by?(job_or_cred)
    job = job_or_cred.is_a?(AccountCred) ? job_or_cred.last_ssu_job : job_or_cred
    (uploads.count == 1) && job.accounts.include?(self)
  end

  def cash_account?
    account_type_id == AccountType::CASH
  end

  def brokerage_account?
    account_type_id == AccountType::BROKERAGE
  end

  def investment_account?
    account_type_id == AccountType::INVESTMENT
  end

  # return true if this is a manual account type (cash or manual)
  # REVIEW: this is a bit confusing, but my alternative, editable?, didn't quite make sense
  def manual_account?
    [AccountType::CASH, AccountType::MANUAL].include?(account_type_id)
  end

  # return true if this account keeps a balance
  def has_balance?
    account_type.has_balance?
  end

  def editable_balance?
    has_balance? && (manual_account? || financial_inst.bad_balance?)
  end

  def has_uploads?
    account_type.has_uploads?
  end

  def to_param
    id_for_user.to_s
  end

  def to_s
    name
  end

private

  # generate a guid for this account. called from before_create
  def generate_guid
    begin
      self.guid = ActiveSupport::SecureRandom.hex(64)
    end while self.class.find_by_guid(guid)
  end

  def generate_id_for_user
    self.id_for_user = ( user.accounts.maximum(:id_for_user)+1 rescue 1 )
  end

  # FIXME: pulled from OFX2Importer.generate_account_name. The new InvestmentStatement uses this. This should be DRYed up.
  # called from before_validation_on_create
  def generate_name
    unless name || manual_account?
      self.name = financial_inst.name
      self.name += " - #{account_type.name}" if account_type.name
    end
  end

  # make sure we're saving the right 4 digits. called from before_create
  def truncate_account_number
    self.account_number = self.class.last4(account_number) if account_number
  end

  def fix_id_for_user
    accounts = user.accounts.find_all_by_id_for_user(self.id_for_user)
    generate_id_for_user if accounts.size > 1 || ( accounts.size == 1 && accounts.first != self )
  end

  def currency_is_not_blank_or_yaml
    currency_name = read_attribute(:currency)
    Currency.new(currency_name) # raises Currency::UnknownCurrencyException if bad currency
    errors.add("currency", "invalid currency") if currency_name.blank?
  end
end
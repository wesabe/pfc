class Txaction < ActiveRecord::Base
  include AbstractTxaction

  concerned_with :currency
  concerned_with :dates
  concerned_with :tags
  concerned_with :transfers
  concerned_with :attachments
  concerned_with :merchants
  concerned_with :notices

  belongs_to :txaction_type

  scope :for_user, lambda{|user| with_account_key(user.account_key) }
  scope :with_account_key, lambda {|account_key| { :include => :account,
    :conditions => {"accounts.account_key" => account_key} } }
  scope :with_sign, lambda {|sign| {:conditions => {-1 => 'amount < 0', 1 => 'amount > 0', 0 => 'amount = 0'}[sign.to_i]} }

  scope :active, :conditions => {:status => Status::ACTIVE}
  scope :posted_between, lambda {|range|
    {:conditions => ["date_posted #{range.exclude_end?? '<' : '<='} ? AND date_posted > ?", range.end, range.begin]}}

  scope :before, lambda {|txaction|
    {:conditions => ['date_posted < :date_posted OR (account_id = :account_id AND date_posted = :date_posted AND sequence > :sequence)',
                    {:date_posted => txaction.date_posted, :sequence => txaction.sequence, :account_id => txaction.account_id}]}}

  scope :after, lambda {|txaction|
    {:conditions => ['date_posted > :date_posted OR (account_id = :account_id AND date_posted = :date_posted AND sequence < :sequence)',
                    {:date_posted => txaction.date_posted, :sequence => txaction.sequence, :account_id => txaction.account_id}]}}

  attr_accessor :rational_tag, :merchant_comparison
  attr_accessor :bulk_update # to avoid doing account calculations on bulk updates

  validates_presence_of :account

  #----------------------------------------------------------------------------
  # Class methods
  #

  # generate balances for a list of txactions
  # We do this because calculation is expensive so we only want to do it for
  # the chunk of txactions that is going to be displayed
  # this is separated from generate_ratings because there are times when we
  # don't show the balance, so no need to generate
  def self.generate_balances!(txactions)
    if txactions.any? && txactions.first.calculate_balance!
      balance = txactions.first.balance - txactions.first.amount
      for txaction in txactions[1..-1]
        txaction.balance = balance
        balance -= txaction.amount
      end
    end
  end

  # return txactions for the given date range
  # start_date and end_date are expected.
  def self.find_within_dates(txobject, params)
    params[:end_date] ||= Time.now

    cc = ConditionsConstructor.new('date_posted >= ?', params[:start_date])
    cc.add('date_posted < ?', params[:end_date])
    self.find_for_user_with_conditions(txobject, params, cc.conditions)
  end

  # return txactions for the given object posted in the given year and month
  def self.find_by_year_and_month(txobject, params)
    cc = ConditionsConstructor.new('YEAR(date_posted) = ?', params[:year])
    cc.add('MONTH(date_posted) = ?', params[:month])
    self.find_for_user_with_conditions(txobject, params, cc.conditions)
  end

  # get transactions associated with a particular upload guid
  def self.find_by_user_and_upload_guid(txobject, user, upload_guid)
    upload = Upload.first(:conditions => ["guid = ?", upload_guid])
    cc = ConditionsConstructor.new("txactions.upload_id = ?", upload.id)
    find_for_user_with_conditions(txobject, {:user => user}, cc.conditions)
  end

  def self.find_for_user_with_conditions(txobject, params, conditions)
    includes = [:account, {:taggings => :tag}, :merchant]

    cc = ConditionsConstructor.new()
    cc.add('accounts.account_key = ?', params[:user].account_key)
    cc.add('accounts.status != ?', Account::Status::DELETED)
    cc.add(conditions)

    if params[:unedited]
      cc.add('txactions.merchant_id is null')
    elsif params[:untagged]
      cc.add('txactions.tagged = 0')
      includes = [:account]
    elsif params[:transfers]
      cc.add('txactions.transfer_txaction_id IS NOT NULL')
    end

    txobject.txactions.find(:all,
      :include => includes,
      :conditions => cc.conditions,
      :order => 'date_posted desc, sequence')
  end

  # if the amount contains symbols that indicate that it is a basic calculation, eval it
  def self.calculate_amount(expr)
    expr = expr.to_s.dup
    # check to see if this is a calculation; if so, split it and normalize the individual amounts
    if expr =~ /[()*\/+-]/
      expr.gsub!(/([^()*\/+-]+)/) {|a| Currency.normalize(a)}
      parser = SimpleCalc.new
      expr = parser.parse(expr)
    end
    Currency.normalize(expr)
  rescue ParseError
    Currency.normalize(expr)
  end

  def self.rationalize!(user, txactions)
    # 2: find all the filter tags and remove those txactions
    filters = user.filter_tags
    txactions.delete_if{|t| (t.tags & filters).any? }

    # 3: create the list of tags with total spending per tag
    tags_priority = {}
    tags_priority.default = 0
    txactions.each do |tx|
      tx.tags.each{|tag| tags_priority[tag] += tx.usd_amount(:tag => tag).abs }
    end
    tags_priority = tags_priority.to_a

    # 4: sort the list of tags by value per tag and then frequency of use on wesabe
    tags_priority.sort! do |x,y|
      # try comparing values first
      case y[1] <=> x[1]
      when -1
        -1
      when 1
        1
      when 0
        # if values are the same, then pick the more popular one
        y[0].txaction_taggings.count <=> x[0].txaction_taggings.count
      end
    end
    tags_priority.map!{|k,v| k }

    # 5: replace the array of tags on each txaction with the highest-priority tag
    txactions.each do |tx|
      priority_tag = tags_priority.detect{|n| tx.tags.include?(n) }
      tx.rational_tag = [tx.taggings.detect{|n| n.tag == priority_tag }]
      tx.rational_tag.first.name = priority_tag.name if tx.rational_tag.first
    end

    return txactions
  end

  # Changes status on lists of txactions, if there is an identical txaction already existing
  # with the deleted status, it (really) deletes it then tries again.
  def self.change_status(txactions, desired_status)
   txaction_ids = txactions.map(&:id).compact
   return if txaction_ids.empty?

   give_up = false
   begin
     update_all(["status = ?", desired_status], ["id in (?)", txaction_ids])
   rescue ActiveRecord::StatementInvalid
     raise if give_up
     give_up = true
     # a deleted copy of one or more of these txactions already exists, so delete those outright and try again
     # account_id isn't strictly necessary...just being paranoid
     if desired_status == Status::DELETED
       delete_all(["account_id in (?) and wesabe_txid in (?) and status = ?", txactions.map(&:account_id).uniq, txactions.map(&:wesabe_txid), desired_status])
       retry
     end
   end
  end

  # Sets lists of txactions to deleted status
  def self.safe_delete(txactions)
    self.change_status(txactions, Status::DELETED)
  end

  #----------------------------------------------------------------------------
  # Instance methods
  #

  # A public, opaque, uniqe identifier. Returns a string. To be used by API clients for determining identity comparisons
  # of downloaded txactions (e.g., is this an existing txaction or a new txaction for the same amount at the same
  # merchant on the same day).
  #
  # Example:
  #
  #   @txaction = Txaction.find(:first)
  #   @txaction.guid #=> "2c99edbddedf5a5fd1546fab956119cb3726f2851779da4382a44c23f6c30880"
  def guid
    Digest::SHA256.hexdigest(self.id.to_s + "UasYPG9pKNEe1HzP2gYQB4Clg88Eed54")
  end

  # save this transaction, but skip the callback that updates account calculations
  def bulk_update_save!
    self.bulk_update = true
    save!
  end

  # "delete" a txaction safely (set its status to DELETED), handling a unique index violation exception
  def safe_delete
    self.class.safe_delete([self])
    self.status = Status::DELETED
  end

  # return the name that should be displayed
  def display_name(include_slash_hack = true)
    display_name =
      if merchant
        merchant.name
      elsif cleaned_name && memo.blank? && (raw_name.blank? || raw_name =~ /UNKNOWN/)
        cleaned_name
      else
        # don't display both raw_name and memo if raw_name is a subset of memo
        name = memo && (memo =~ /^#{Regexp.escape(raw_name)}/i) ? memo : full_raw_name
        # if no name or memo field, remove the slash
        name.gsub(/^\/|\/$/,'')
        name.gsub(/\s+/,' ') # collapse multiple spaces
      end

    # append a slash if no merchant is set or the merchant is flagged as unedited
    # this gives us a means to determine if the user has truly edited the merchant name
    if include_slash_hack && (!merchant || merchant.unedited?) &&
        !display_name.blank? && display_name.last != "/" && !manual_txaction? && !is_check?
      display_name << "/"
    end
    display_name
  end

  # if the date_posted isn't set for some reason, return the fi_date_posted
  # def date_posted
  #   read_attribute(:date_posted) || fi_date_posted
  # end

  def cash_txaction?
    account.cash_account?
  end

  def manual_txaction?
    account.manual_account?
  end

  def activate!
    update_attribute :status, Status::ACTIVE
  end

  # the raw name that we display to the user before a transaction is edited
  def full_raw_name
    # this is FI-dependent because some banks (right now just one) put useful information in the txid
    if account && (account.wesabe_id == "us-003380")
      # 1st National Bank of Steamboat Springs
      fields = [raw_name, memo, txid]
    else
      fields = [raw_name, memo]
    end
    fields.compact.join(' / ')
  end

  # titlecase the transaction name and remove multiple spaces
  def titlecase_name
    if !merchant || merchant.unedited?
      self.display_name.titlecase.gsub(/\s+/," ")
    else
      self.display_name
    end
  end

  # return the amount associated with this transaction. If a tag is passed, get the amount associated with that
  # tag -- split_amount or full txaction amount
  def amount(args = {})
    if args[:tag]
      tag = args[:tag].kind_of?(Tag) ? args[:tag] : Tag.find_by_name(args[:tag])
      return 0 unless tag

      tagging = taggings.loaded? ? taggings.to_a.find{ |t| t.tag_id == tag.id } :
      taggings.find_by_tag_id(tag.id)
      return 0 unless tagging

      tagging.split_amount || read_attribute(:amount) #attributes["amount"]
    else
      read_attribute(:amount)
    end
  end

  def money_amount(args = {})
    Money.new(amount(args), currency)
  end

  # return the usd_amount associated with this transaction. If a tag is passed, get the amount associated with that
  # tag -- usd_split_amount or full txaction amount
  def usd_amount(args = {})
    if args[:tag]
      tag = args[:tag].kind_of?(Tag) ? args[:tag] : Tag.find_by_name(args[:tag])
      return 0 unless tag

      tagging = taggings.loaded? ? taggings.to_a.find{ |t| t.tag_id == tag.id } :
      taggings.find_by_tag_id(tag.id)
      return 0 unless tagging

      tagging.usd_split_amount || read_attribute(:usd_amount)
    else
      read_attribute(:usd_amount)
    end
  end

  def usd_money_amount(args = {})
    Money.new(usd_amount(args), Currency.usd)
  end

  def sign
    read_attribute(:sign) || ((amount < 0) ? -1 : (amount > 0) ? 1 : 0)
  end

  # calculate the balance for this transaction by summing up the amounts of all previous
  # transactions and subtracting that from the current account balance. We need to do this because
  # the balance that [some? most?] banks give us is the current total balance, and not all
  # transactions that contributed to that balance are necessarily available yet. So if I have
  # $1000 in my account and go deposit $500 and then download my bank data, it will show that I
  # have a balance of $1500, but that $500 deposit transaction might not show up in the statement
  # until sometime later
  def calculate_balance!
    return if cash_txaction? # cash txactions don't have balances

    # manual transaction balances are more complicated to calculate because the last account balance
    # isn't necessarily the balance at the time of the most recent transaction, which is the assumption
    # made with uploaded accounts
    if manual_txaction?
      # get the last balance and calculate backwards or forwards from there
      last_balance = account.last_balance

      # if the last_balance is in the future, calculate backwards from there
      if last_balance.balance_date > date_posted
        txaction_sum = account.txactions.
                        active.
                        posted_between(date_posted...(last_balance.balance_date)).
                        sum('amount').to_d
        self.balance = last_balance.balance - txaction_sum
      else
        # last balance is in the past, so calculate forwards
        # get transactions that were posted on the same date as the last_balance, but later
        txaction_sum = account.txactions.
                        active.
                        posted_between(last_balance.balance_date..date_posted).
                        sum('amount').to_d
        self.balance = last_balance.balance + txaction_sum
      end
    else # non-manual transaction
      txaction_sum = account.txactions.
                      active.
                      after(self).
                      sum('amount').to_d
      self.balance = self.account.balance - txaction_sum
    end
    self.balance
  end

  # return true if this txaction is a check
  def is_check?
    check_num &&
      (txaction_type.name == "CHECK" ||
        (raw_name =~ /CHECK\b|Unknown Payee|Withdrawal Draft|FED CLEARING DEBIT|\b(Share)?DRAFT\b/i) ||
        (memo && memo =~ /\bCLEARED CHECK\b/i) ||
        (raw_name =~ /^\d+$/)) ? true : false
  end

  # merge one txaction onto another (mark the current txaction as deleted and link to the provided txaction)
  def merge_onto!(txaction)
    Txaction.transaction do
      # merge transfer buddy unless the txaction we're merging onto already has one
      if transfer_buddy && txaction.transfer_buddy.nil?
        buddy = transfer_buddy
        clear_transfer_buddy!
        txaction.set_transfer_buddy!(buddy)
      end
      txaction.merged_with_txaction = self
      txaction.save!
      update_attributes!(:merged_with_txaction_id => txaction.id)
      safe_delete
    end
  end

  # return true if the txaction is a type that should be edited independently from similarly-named txactions
  # (e.g. checks, unknown, generic electronic deposits/withdrawals)
  def edit_independently?
    if defined?(@edit_independently)
      @edit_independently
    else
      is_check? ||
        (raw_name == 'ACH PAYMENT' && memo.nil? && check_num.nil?) ||
        filtered_name && (
          filtered_name =~ /UNKNOWN(?:PAYEE)?$/ ||
          filtered_name == "CHECK" ||
          (txaction_type_id == 2 && filtered_name =~ /ATMWITHDRAWAL/) ||
          (filtered_name =~ /^(FEDCLEARINGDEBIT)+$ |
                             POSDEB$ |
                             DBTCRD$ |
                             DEBIT$ |
                             DDAPOINTOFSALEDEBIT$ |
                             DEBITPIN$ |
                             ATM$ |
                             DEPOSIT$ |
                             ^(WITHDRAWAL)+$ | SACADO$ |
                             [^(ATM)]WITHDRAWAL$ |
                             (ELECTRONIC|INTERNET)(DEPOSIT|WITHDRAWAL|WD) |
                             (ATM|INSTANTTELLER)DEPOSIT |
                             ^(TRANSFER(IN|OUT))+$ |
                             SHAREDRAFT |
                             ^(DEPOSITHOME)+$ | # USAA Deposit@Home |
                             (PAYPAL|ONLINE|WWW).*?(PAYMENT$|TRANSFER$|INSTXFER$|ECHECK$)/x)
        )
    end
  end

  def edit_independently=(edit_independently)
    @edit_independently = edit_independently
  end

  # reverse (mm/dd <-> dd/mm) ambiguous date_posted in the transaction
  def swap_ambiguous_date_posted!
    if date_posted.ambiguous_date?
      self.date_posted = date_posted.swap_month_and_day
      wesabe_txid_parts = wesabe_txid.split(/:/)
      wesabe_txid_parts[1].gsub!(/(\d{4})(\d{2})(\d{2})/,'\1\3\2')
      self.wesabe_txid = wesabe_txid_parts.join(':')
      save!
    end
  end

  # generate the filtered name of this transaction and clean up certain kinds of txaction names...right now, just checks
  def generate_filtered_and_cleaned_names!
    if is_check?
      cleaned_check_num = check_num || ref_num
      cleaned_check_num.gsub!(/^0+/,'') # remove leading zeros from check num
      self.cleaned_name = "CHECK # #{check_num}"
    end

    # FI-specific rules for filtered_name
    # REVIEW: if FI-specific rules get any more complicated, we should move them to separate class[es].
    filter_str =
      case account.financial_inst && account.financial_inst.wesabe_id
    when 'us-003380' # 1st National Bank of Steamboat Springs
      [raw_name, memo, txid].join('/')
    else
      [raw_name, memo].join('/')
    end
    self.filtered_name = TxactionFilter.filter(filter_str)
    self.filtered_name += "/#{cleaned_name}" if cleaned_name

    # if the name and memo fields are blank, give the txaction a meaningful filtered name and cleaned name
    # using the transaction type
    if (filtered_name == 'UNKNOWN PAYEE/') && txaction_type.display_name
      self.filtered_name += txaction_type.display_name.upcase
      self.cleaned_name ||= txaction_type.display_name.upcase
    end
  end

  include ExportHelper
  def to_json(options = {})
    txaction_to_json(self, options)
  end

end
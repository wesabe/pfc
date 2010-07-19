class User < ActiveRecord::Base
  acts_as_taggable

  concerned_with :current_user
  concerned_with :roles
  concerned_with :time
  concerned_with :messages
  concerned_with :merchants

  has_many :accounts,          :foreign_key => 'account_key', :primary_key => 'account_key'
  has_many :account_creds,     :foreign_key => 'account_key', :primary_key => 'account_key'
  has_many :attachments,       :foreign_key => 'account_key', :primary_key => 'account_key'
  has_many :inbox_attachments, :foreign_key => 'account_key', :primary_key => 'account_key'

  has_many :merchant_users, :dependent => :destroy
  has_many :account_merchant_tag_stats, :dependent => :destroy, :foreign_key => :account_key, :primary_key => :account_key
  belongs_to :country
  has_many :targets

  has_one :user_preferences, :class_name => 'UserPreferences', :dependent => :destroy
  has_many :financial_insts, :foreign_key => "creating_user_id"

  has_many :merchant_aliases

  has_one  :profile, :class_name => "UserProfile"

  has_one :snapshot, :dependent => :destroy

  attr_protected :role, :admin
  attr_accessor :new_password
  attr_accessor :allow_import
  attr_accessor :password, :password_confirmation

  before_create :set_default_currency, :update_last_web_login
  before_validation :generate_keys, :on => :create
  before_validation :generate_uid, :set_username
  after_validation :generate_anonymous_name_if_necessary, :on => :create
  before_validation :generate_normalized_name
  after_validation :hash_password
  before_save :update_username
  after_save '@new_password = @changed_password = @allow_import = false'

  validates_presence_of :email, :username, :uid, :message => "can't be blank"
  validates_uniqueness_of :username, :if => :new_record?
  validates_uniqueness_of :uid, :if => :new_record?
  validates_uniqueness_of :email, :message => "already in use"
  validates_presence_of :password, :if => :validate_password?
  validates_confirmation_of :password, :if => :validate_password?, :message => "doesn't match confirmation"
  validates_format_of :name, :with => /[a-z0-9]/i,
    :message => 'must contain at least one alphanumeric character',
    :if => Proc.new {|user| !user.name.blank?}
  validates_inclusion_of :status, :in => [
    Constants::Status::ACTIVE,
    Constants::Status::DELETED,
    Constants::Status::PENDING  # used when user's password is reset by admin and they need to change it on next login
  ]
  validates_email_veracity_of :email, :domain_check => false

  validate :check_normalized_name
  validate :check_default_currency

  def check_normalized_name
    # validate uniqueness of normalized name, but error goes to the name field
    if normalized_name && !normalized_name.blank?
      if id
        user = User.find(:first, :conditions => ["normalized_name = ? and id <> ?", normalized_name, id])
      else
        user = User.find(:first, :conditions => ["normalized_name = ?", normalized_name])
      end
      errors.add("name","'#{name}' has already been taken") if user
    end
  end

  def check_default_currency
    # validate default currency
    if currency = read_attribute(:default_currency)
      unless Currency.known?(currency)
        errors.add('default_currency', 'is not a valid currency')
      end
    end
  end

  def authenticated_by(password)
    self.account_key = generate_account_key(password)
    self.save! if changes.include?(:account_key)
    return self
  end

  #---------------------------------------------------------------------------
  # constants
  #
  #

  # length of salt used to hash with password
  SALT_LENGTH = 16

  WESABE_USER_ID = 0 # user id to use to represent Wesabe-generated content (e.g. MerchantComparisons)

  # make sure the user's role is set to USER by default
  def initialize(params = {})
    super
    self.role ||= Role::USER
  end

  #---------------------------------------------------------------------------
  # public instance methods
  #

  # convenience method for generating an account key
  def generate_account_key(password)
    self.class.generate_account_key(uid, password)
  end

  def after_login(controller)
    # record that the user has logged in
    UserLogin.create(:user => self)
    # trigger automatic updates if necessary
    User::AccountUpdateManager.login!(self, controller, :force => true)
  end

  # convert the name to a slug, unless that doesn't exist (e.g., the user has been deleted and my fixes to that code
  # don't work, mysterious data integrity problems, flying cows did it) in which case just use the ID like usual to
  # keep things from generating exceptions.
  def to_param
    if name
      Sluggability.make_slug(name)
    else
      id.to_s
    end
  end

  # override AR method so we can return a currency object
  def default_currency
    Currency.new(read_attribute(:default_currency))
  rescue Currency::UnknownCurrencyException
    nil
  end

  # override AR method so we can set with a Currency object
  def default_currency=(cur)
    write_attribute(:default_currency, cur.to_s)
  end

  def default_currency_set?
    not read_attribute(:default_currency).nil?
  end

  # set the default currency based on the country before create
  def set_default_currency
    self.default_currency = country.currency.name if country && !default_currency_set?
  end

  def cached_country
    Country.find(country_id)
  end

  # change the user's password
  def change_password!(newpass)
    User.transaction do
      logger.debug("changing password for user #{uid}")
      self.password = newpass
      self.password_confirmation = newpass
      @new_password = true
      @changed_password = true
      save!
    end
  end

  # delete a user; sets the user's status to deleted, but actually deletes
  # all of the user's accounts, txactions and photos. Public data such as
  # recommendations and goals are preserved.
  def destroy
    # delete accounts, txactions, account_balances, accounts_uploads
    accounts.each {|a| a.send_later(:destroy)}

    # destroy all associations that should be destroyed
    self.class.reflect_on_all_associations.each do |a|
      # I'm not bothering with :delete_all or :nullify because I'm not using them; if we make this
      # more generic down the road we should add those
      if (a.options[:dependent] == :destroy)
        to_delete = send(a.name)
        to_delete = [to_delete] unless to_delete.is_a?(Array)
        to_delete.each{|obj| obj.destroy if obj }
      end
    end

    # delete raw upload data; make sure that the account_key isn't empty or something like "../../../"
    # the statement files themselves are probably deleted already, since destroying accounts will destroy
    # the upload data. We still need to get rid of the statement_dir itself, though, so it doesn't
    # hurt to rm-rf it
    if account_key && account_key =~ /[0-9a-f]{64}/
      statement_dir = Upload.statement_dir(account_key)
      FileUtils.rm_r(statement_dir, :force => true) if File.exists?(statement_dir)
    end

    # delete user photos
    if photo_key && photo_key =~ /\w+/
      FileUtils.rm(Dir.glob(full_image_path('*', '*')), :force => true)
    end

    # Come up with an anonymous name so comment links will still work.
    self.name = nil
    generate_anonymous_name

    # clear out any private information from the user record. we don't actually delete the user record
    # because the user may have comments/discussions
    deleted_username = "deleted_user_#{id}"
    while User.find_by_username(deleted_username)
      deleted_username += ('a'..'z').to_a.random
    end

    # clear out data from user record
    self.attributes = {
      :username => deleted_username,
      :name => name,
      :status => Constants::Status::DELETED,
      :salt => nil, :password_hash => nil, :postal_code => nil, :country_id => nil,
      :photo_key => nil, :feed_key => nil, :goals_key => nil, :email => nil,
      :encrypted_account_key => nil
    }
    save(:validate => false)
  end

  # user name to display; basically, just show "Anonymous" if the name has not been set
  def display_name
    self.name.blank? ? 'Anonymous' : self.name
  end

  def to_s
    display_name
  end

  def anonymous?
    name.blank? || name =~ /^Anonymous( [0-9a-f]{5})?$/i
  end

  # return the active, enabled account with the given id_for_user
  def active_account_by_id_for_user(id_for_user)
    Account.find(:first, :include => :financial_inst,
      :conditions => ["account_key = ? AND id_for_user = ? AND accounts.status NOT IN ( ? )",
                      account_key, id_for_user, [Constants::Status::DELETED, Constants::Status::DISABLED]])
  end

  def active_account_by_uri_for_user(uri_for_user)
    active_account_by_id_for_user(uri_for_user[Account::URI_PATTERN, 1])
  end

  def active_account_by_id_or_uri_for_user(id_or_uri_for_user)
    if id_or_uri_for_user.to_s =~ Account::URI_PATTERN
      return active_account_by_uri_for_user(id_or_uri_for_user)
    else
      return active_account_by_id_for_user(id_or_uri_for_user)
    end
  end
  alias account active_account_by_id_or_uri_for_user

  # return the account with the given id_for_user
  def account_by_id_for_user(id_for_user)
    Account.find(:first, :include => :financial_inst,
      :conditions => ["account_key = ? AND id_for_user = ?", account_key, id_for_user])
  end

  # return true if the user has any active accounts
  def has_accounts?
    !!Account.find(:first, :select => "id",
                   :conditions => ["account_key = ? and status not in (?)",
                                    account_key,
                                    [Constants::Status::DELETED, Constants::Status::DISABLED]])
  end

  def active_accounts
    sorted_accounts_with_status(Constants::Status::ACTIVE)
  end

  def archived_accounts
    sorted_accounts_with_status(Constants::Status::ARCHIVED)
  end

  def disabled_accounts
    sorted_accounts_with_status(Constants::Status::DISABLED)
  end

  def sorted_accounts_with_status(status)
    conditions = ConditionsConstructor.new
    conditions.add "account_key = ?", account_key
    conditions.add "accounts.status = ?", status unless status.nil?
    Account.find(:all, :include => :financial_inst, :conditions => conditions.join).
      sort_by {|account| [account.position, account.name.downcase]}
  end

  def account_creds
    AccountCred.find_all_by_account_key(account_key)
  end

  def account_creds_in_limbo
    AccountCred.find_all_by_account_key(account_key, :include => [:accounts, :financial_inst]).
      find_all{|ac| ac.accounts.empty? || ac.failed? }
  end

  def ssu_jobs
    SsuJob.find_all_by_account_key(account_key, :conditions => ["expires_at < ?", Time.now])
  end

  def pending_ssu_accounts
    active_accounts.select {|a| a.account_cred && a.account_cred.pending?}
  end

  # transactions for this user, optionally constrained by the given conditions
  # recognized options: :start_date, :end_date, :limit, :rationalize
  def txactions(options = {})
    acct_ids = account_ids
    if acct_ids.any?
      conditions = ["txactions.account_id in (?) and txactions.status = ?", acct_ids, Constants::Status::ACTIVE]
      if options[:start_date]
        conditions[0] << " and date_posted >= ?"
        conditions << options[:start_date]
      end
      if options[:end_date]
        conditions[0] << " and date_posted <= ?"
        conditions << options[:end_date]
      end
      if options[:year] && options[:month]
        conditions[0] << " and YEAR(date_posted) = ? and MONTH(date_posted) = ?"
        conditions << options[:year] << options[:month]
      end
      transactions = Txaction.find(:all,
        :include => [:merchant, :taggings, :txaction_type, :account],
        :conditions => conditions,
        :order => 'txactions.date_posted desc, txactions.sequence',
        :limit => options[:limit])
      if options[:rationalize] == "true"
        Txaction.rationalize!(self, transactions)
      end
      transactions
    else
      []
    end
  end

  def untagged_txaction_stats(start_date, end_date, type = nil)
    cc = ConditionsConstructor.new("account_id IN (?)", account_ids)
    cc.add("status = ?", Constants::Status::ACTIVE)
    cc.add("tagged = ?", false)
    cc.add("transfer_txaction_id IS NULL")
    cc.add("date_posted >= ?", start_date)
    cc.add("date_posted <= ?", end_date)
    cc.add( (type == :earnings) ? "amount > 0" : "amount < 0" )
    conditions = self.class.send(:sanitize_sql_for_conditions, cc.conditions)

    number = Txaction.count_by_sql("SELECT COUNT(*) FROM txactions WHERE #{conditions}")
    if number.zero?
      return nil
    else
      amount = Txaction.count_by_sql("SELECT ABS(SUM(amount)) FROM txactions WHERE #{conditions}")
      return { :number => number, :amount => amount }
    end
  end

  # return an array of account ids for this user. This is a bit faster than using #accounts to get
  # the account list and mapping out the ids, as it only selects the id column
  def account_ids(include_hidden = false)
    accounts(include_hidden).map(&:id)
  end

  def all_account_ids
    account_ids(true)
  end

  def invalidate_account_ids_cache
    @account_ids = @all_account_ids = nil
  end

  # get all uploads for this user
  def uploads
    Upload.uploads_for_user(self)
  end

  def target_tags
    Tag.find_by_sql %{
      SELECT tags.*, targets.tag_name as user_name
      FROM tags, targets
      WHERE targets.tag_id = tags.id AND targets.user_id = #{id};
    }
  end

  # get all tags (actually, taggings) used by the user
  # if all is specified, don't group tags by normalized name (see Tag.tags_for_user)
  def tags(all = nil)
    Tag.tags_for_user(self, all)
  end

  def filter_tags
    Tag.filter_tags_for_user(self)
  end

  # update the user with tags to filter from reports. This update is
  # destructive for previously assigned tags.
  def apply_filter_tags(list)
    # clear previous filter tags
    taggings.to_a.find_all {|t| t.kind == Tag::Kind::REPORT_FILTER}.each do |tagging|
      self.taggings.delete(tagging)
      tagging.destroy
    end
    self.reload

    Tag.parse_to_tags(list).each do |tag|
      # add the tagging
      self.taggings << Tagging.create(:taggable => self,
                                      :name => tag.name,
                                      :kind => Tag::Kind::REPORT_FILTER,
                                      :tag => tag)
    end
    self.reload
  end

  def update_last_web_login
    self.last_web_login ||= Time.now
  end

  # return true if the user is in a PENDING state (their password has been reset
  # and they need to change it on next login)
  def pending?
    status == Constants::Status::PENDING
  end

  def active?
    status == Constants::Status::ACTIVE
  end

  # set a user's PENDING status (true => PENDING, false => ACTIVE)
  def pending!(state)
    update_attribute(:status, state ? Constants::Status::PENDING : Constants::Status::ACTIVE )
  end

  has_image :column => :photo_key, :default => 'default_user_icon.jpg', :processor => ImageProcessing::Thumbnailer.new(:thumb => 48, :profile => 96)
  self.image_subdirectory = 'user_photos'

  # return true if the user can edit this transaction
  def can_edit_txaction?(txaction)
    txaction.account.account_key == account_key
  end

  # return the last upload for any of this user's accounts
  def last_upload
    return if (acct_ids = account_ids).empty?
    Upload.find(:first,
                :joins => "JOIN accounts_uploads ON accounts_uploads.upload_id = uploads.id",
                :conditions => ["accounts_uploads.account_id IN (?)", acct_ids],
                :order => "uploads.created_at DESC")
  end

  # convenience method to return the last upload time (used by /user/list)
  def last_upload_time
    last_upload.created_at if last_upload
  end

  def last_upload_client
    "#{last_upload.client_name}/#{last_upload.client_version}" if last_upload
  end

  def generate_anonymous_name
    begin
      self.name = 'Anonymous ' + ActiveSupport::SecureRandom.hex(5)
      generate_normalized_name
    end until !User.find(:first, :conditions => ["normalized_name = ?", normalized_name])
  end

  def generate_anonymous_name_if_necessary
    generate_anonymous_name if name.blank? && errors.empty?
  end

  # Strips everything which isn't a letter or a digit, strips all whitespace, and downcases the name.
  # e.g., "Bjørn Øgler 88 & Friends" #=> "bjørnøgler88andfriends"
  # REVIEW: I think we want [^\p{Alnum}] here instead. Might need to run a migration if we change this, though.
  def self.normalize_name(name)
    Oniguruma::ORegexp.new('[[:^alnum:]]', "i", "utf8").gsub(name.gsub(/&/,'and'), "").mb_chars.strip.downcase.to_s
  end

  # called by before_validate to generate a normalized name for this user
  def generate_normalized_name
    if new_record? || name_changed?
      # strip any leading/trailing/multiple spaces from the name
      self.name = name.to_s.squeeze(" ").strip
      self.normalized_name = self.class.normalize_name(name)
    end
  end

  def update_username
    self.username ||= email
  end

  # create preferences if it doesn't exist
  def preferences
    user_preferences || create_user_preferences(:preferences => {})
  end

  # convenience method to overwrite all preferences
  def preferences=(prefs)
    raise TypeError, 'value must be a Hash' unless prefs.is_a?(Hash)
    preferences.update_attribute('preferences', prefs)
  end

  def associate_transfers
    txactions.inject(0) do |count, txaction|
      txaction.attach_matching_transfer ? count + 1 : count
    end
  end

  # return the most recent txactions_updated_at time from the user's accounts
  def txactions_updated_at
    updated_at = Account.where(["account_key = ? AND status = ?", account_key, Constants::Status::ACTIVE]).
                  maximum(:txactions_updated_at)
    return updated_at || Time.now # if no accounts, updated at time is now
  end

  def account_data_cache_key
    {:at => txactions_updated_at.to_i, :user => id}
  end


  # Returns +true+ if +candidate+ is the user's password, +false+ otherwise.
  def valid_password?(candidate)
    return self.class.generate_password_hash(salt, candidate) == password_hash
  end

  #---------------------------------------------------------------------------
  # public class methods
  #


  # Given a username or email and password, finds the user and checks the password's
  # validity. Returns a +User+ instance with an +account_key+ if the credentials
  # are valid, returns +nil+ if the user was not found or the password was
  # invalid, and raises +Authentication::LoginThrottle::UserThrottleError+ if
  # that user account is throttled.
  def self.authenticate(username_or_email, password)
    if user = find_by_username_or_email(username_or_email) # uid for backwards compatibility with usernames

      throttle = Authentication::LoginThrottle.new(user)
      if throttle.allow_login?
        if user.valid_password?(password)
          logger.info("authentication succeeded for #{username_or_email}  (#{user.id})")
          throttle.successful_login!
          user = user.authenticated_by(password)
          return user
        else
          logger.info("authentication failed for #{username_or_email} (#{user.id}) -- bad password")
          throttle.failed_login!
          return nil # same as no user found
        end
      else
        logger.info("authentication failed for #{username_or_email} (#{user.id}) -- user is throttled")
        throttle.failed_login!
        throttle.raise_throttle_error
      end
    else
      return nil
    end
  end

  # find a user by name, normalizing it in the process
  def self.find_with_normalized_name(name)
    if name.blank? || name.strip.blank?
      return nil
    else
      find_by_normalized_name(normalize_name(name))
    end
  end

  def self.find_by_username_or_email(username_or_email)
    ordering = "last_web_login desc"
    users = where(:email => username_or_email).order(ordering).limit(1) |
              where(:username => username_or_email).order(ordering).limit(1)
    return users.sort_by(&:last_web_login).last
  end

  # Absolutely nothing from the database gets shared here.
  def to_xml(options = {})
    options[:indent] ||= 2
    xml = options[:builder] ||= ::Builder::XmlMarkup.new(:indent => options[:indent])
    xml.instruct! unless options[:skip_instruct]
    xml.dasherize!
    xml.user do
      xml.name(display_name)
      xml.profile_path(profile_path)
    end
  end

  def to_json(options = {})
    super(options.merge(:only => [:name], :methods => [:profile_path]))
  end

  #---------------------------------------------------------------------------
  # private instance methods
  #

private

  def profile_path
    '/profile/' + to_param
  end

  # return true if we are generating a new password
  def new_password?
    @new_password || (!self.password_hash? && !@allow_import)
  end

  # only validate password if we have a new one or are changing it
  # and don't validate if we're importing (so we can set null password_hash)
  def validate_password?
    new_password? && !@allow_import
  end

  # write the password_hash attribute only if we are
  # generating a new password (new user or change password)
  def hash_password
    if new_password?
      salt = self.class.generate_salt
      write_attribute("salt", salt)
      write_attribute("password_hash", self.class.generate_password_hash(salt, @password))
    end
  end

  def generate_uid
    self.uid = UID.generate if self.uid.blank?
  end

  # if the username is not set, set it to the email address
  def set_username
    self.username = email if self.username.blank?
  end

  def generate_keys
    self.feed_key = random_and_unique_str(:feed_key) unless feed_key?
    self.goals_key = random_and_unique_str(:goals_key) unless goals_key?
  end

  def random_and_unique_str(attribute)
    chars, key = [('a'..'z').to_a,('0'..'9').to_a,'_'].flatten, nil
    while key.blank? || User.count(:conditions => ["#{attribute} = ?", key]) > 0
      key = ""
      1.upto(16) do
        key << chars.random
      end
    end
    return key
  end

  #---------------------------------------------------------------------------
  # private class methods
  #

private_class_method

  # generate password hash from password and salt
  def self.generate_password_hash(salt, password)
    password ||= ""
    salt ||= ""
    Digest::SHA256.hexdigest(salt + password)
  end

  # generate a salt to has the password with
  def self.generate_salt
    [Array.new(SALT_LENGTH){rand(256).chr}.join].pack("m").chomp[0..SALT_LENGTH-1]
  end

  # generate the account_key with the uid and password
  def self.generate_account_key(uid, password)
    Digest::SHA256.hexdigest(Digest::SHA256.hexdigest(uid + password) + password)
  end
end

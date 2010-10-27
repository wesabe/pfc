class User < ActiveRecord::Base
  acts_as_taggable

  concerned_with :current_user
  concerned_with :roles
  concerned_with :time
  concerned_with :messages
  concerned_with :merchants

  has_many :account_creds,     :foreign_key => 'account_key', :primary_key => 'account_key'
  has_many :attachments,       :foreign_key => 'account_key', :primary_key => 'account_key'
  has_many :inbox_attachments, :foreign_key => 'account_key', :primary_key => 'account_key'

  has_many :merchant_users, :dependent => :destroy
  has_many :account_merchant_tag_stats, :dependent => :destroy, :foreign_key => :account_key, :primary_key => :account_key
  has_many :targets

  has_one :user_preferences, :class_name => 'UserPreferences', :dependent => :destroy
  has_many :financial_insts, :foreign_key => "creating_user_id"

  has_many :merchant_aliases

  has_one  :profile, :class_name => "UserProfile"

  has_one :snapshot, :dependent => :destroy

  attr_protected :role, :admin

  before_validation :generate_keys, :on => :create
  before_validation :generate_uid, :set_username
  after_validation :generate_anonymous_name_if_necessary, :on => :create
  before_validation :generate_normalized_name
  before_save :update_username

  validates_presence_of :email, :username, :uid, :message => "can't be blank"
  validates_uniqueness_of :username, :if => :new_record?
  validates_uniqueness_of :uid, :if => :new_record?
  validates_uniqueness_of :email, :message => "already in use"
  validates_format_of :name, :with => /[a-z0-9]/i,
    :message => 'must contain at least one alphanumeric character',
    :if => Proc.new {|user| !user.name.blank?}
  validates_email_veracity_of :email, :domain_check => false

  validate :check_normalized_name

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

  # make sure the user's role is set to USER by default
  def initialize(params = {})
    super
    self.role ||= Role::USER
  end

  #----------------------------------------------------------------------------
  # Accounts / Account Key
  #

  has_many :accounts, :foreign_key => 'account_key', :primary_key => 'account_key', :dependent => :destroy

  before_create :set_account_key

  # convenience method for generating an account key
  def set_account_key
    if @password
      self.account_key = self.class.generate_account_key(uid, @password)
    else
      errors.add :password, 'cannot be blank'
    end
  end

  #----------------------------------------------------------------------------
  # Other representations (e.g. URL, JSON, XML)
  #

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

  def to_s
    display_name
  end

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

  def display_name
    return 'Anonymous' if anonymous?

    name
  end

  def anonymous?
    name.blank? || name =~ /^Anonymous( [0-9a-f]{5})?$/i
  end

  #----------------------------------------------------------------------------
  # Currency & Country
  #

  belongs_to :country

  before_create :set_default_currency
  validate :check_default_currency

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

  def has_default_currency?
    read_attribute(:default_currency).present?
  end

  # set the default currency based on the country before create
  def set_default_currency
    self.default_currency = country.currency.name if country unless has_default_currency?
  end

  def check_default_currency
    # validate default currency
    if currency = read_attribute(:default_currency)
      unless Currency.known?(currency)
        errors.add('default_currency', 'is not a valid currency')
      end
    end
  end

  #----------------------------------------------------------------------------
  # Password
  #

  public

  attr_accessor :password, :password_confirmation

  def change_password!(newpass)
    User.transaction do
      logger.debug("changing password for user #{uid}")
      clear_password
      self.password = newpass
      self.password_confirmation = newpass
      save!
    end
  end

  # Returns +true+ if +candidate+ is the user's password, +false+ otherwise.
  def valid_password?(candidate)
    return self.class.generate_password_hash(salt, candidate) == password_hash
  end

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

  private

  validates_presence_of :password, :if => :validate_password?
  validates_confirmation_of :password, :if => :validate_password?, :message => "doesn't match confirmation"

  def validate_password?
    new_password?
  end

  def new_password?
    self.password_hash.blank?
  end

  def clear_password
    self.password_hash = nil
  end

  after_validation :hash_password, :if => :new_password?

  def hash_password
    salt = self.class.generate_salt
    write_attribute(:salt, salt)
    write_attribute(:password_hash, self.class.generate_password_hash(salt, @password))
  end

  SALT_LENGTH = 16
  def self.generate_salt
    [Array.new(SALT_LENGTH){rand(256).chr}.join].pack("m").chomp[0..SALT_LENGTH-1]
  end

  # generate password hash from password and salt
  def self.generate_password_hash(salt, password)
    password ||= ""
    salt ||= ""
    Digest::SHA256.hexdigest(salt + password)
  end

  #----------------------------------------------------------------------------
  # Logging in
  #

  public

  def after_login(controller)
    # record that the user has logged in
    UserLogin.create(:user => self)
    # trigger automatic updates if necessary
    User::AccountUpdateManager.login!(self, controller, :force => true)
  end

  private

  before_create :update_last_web_login

  def update_last_web_login
    self.last_web_login ||= Time.now
  end

  #----------------------------------------------------------------------------
  # Destroying
  #

  private

  after_destroy :remove_uploads_directory

  def remove_uploads_directory
    if account_key && account_key =~ /[0-9a-f]{64}/
      statement_dir = Upload.statement_dir(account_key)
      FileUtils.rm_r(statement_dir, :force => true) if File.exists?(statement_dir)
    end
  end

  after_destroy :remove_user_photos

  def remove_user_photos
    if photo_key && photo_key =~ /\w+/
      FileUtils.rm(Dir.glob(full_image_path('*', '*')), :force => true)
    end
  end

  #----------------------------------------------------------------------------
  # TODO: Break this up / move it into sections
  #

  public

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

  def destroy_deferred
    Resque.enqueue(User::DestroyUser, self.id)
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
    Normalizer.alnum.normalize(name.gsub(/&/, 'and'))
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

  #---------------------------------------------------------------------------
  # private instance methods
  #

private

  def profile_path
    '/profile/' + to_param
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

  # generate the account_key with the uid and password
  def self.generate_account_key(uid, password)
    Digest::SHA256.hexdigest(Digest::SHA256.hexdigest(uid + password) + password)
  end
end

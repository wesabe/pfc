# A bank, credit union, credit card provider, or other financial institution.
class FinancialInst < ActiveRecord::Base
  has_many :accounts
  has_many :account_creds
  has_many :ssu_jobs, :through => :account_creds
  has_many :all_ssu_jobs, :through => :account_creds

  validates_presence_of :name, :wesabe_id

  validates_each :homepage_url, :login_url, :allow_nil => true, :allow_blank => true do |record, attr, value|
    unless value =~ %r{^https?://}
      record.errors.add attr, '- the url needs to start with http:// or https://'
    end
  end

  belongs_to :creating_user,  :class_name => "User"
  belongs_to :mapped_to,      :class_name => "FinancialInst"
  belongs_to :country

  before_validation :generate_wesabe_id
  before_destroy :check_for_existing_active_accounts

  serialize :login_fields

  scope :for_user, lambda { |user|
    {:conditions =>
      ["((status = ?) OR (status = ? AND creating_user_id = ?)) AND (id != ?)",
        Status::ACTIVE, Status::UNAPPROVED, user.id, UNKNOWN_FI_ID]
    }
  }

  # The primary key for the stub FI which is assigned to txactions with unknown
  # financial institutions.
  UNKNOWN_FI_ID = 1

  # statuses used
  # moved here from Constants
  class Status < OptionSet
    ACTIVE = 0
    DELETED = 1
    HIDDEN = 2
    UNAPPROVED = 4
  end

  # format of dates that this FI uses in its statements
  class DateFormat
    MMDDYYYY = 0 # US-format
    DDMMYYYY = 1 # most of the rest of the world
  end

  # values for ssu_support column
  class SSUSupport < OptionSet
    NONE = 0
    GENERAL = 1
    TESTER = 2
  end

  DEFAULT_LOGIN_FIELDS = [
    {:key => 'username', :type => 'text', :label => 'Username'},
    {:key => 'password', :type => 'password', :label => 'Password'} ].freeze

  def active?
    return status == Status::ACTIVE
  end

  def hidden?
    return status == Status::HIDDEN
  end

  # Returns an array of name/id tuples for FI date formats, suitable for use
  # with the +select+ helper.
  def self.date_format_options
    [['US (MM-DD-YYYY)', FinancialInst::DateFormat::MMDDYYYY], ['International (DD-MM-YYYY)', FinancialInst::DateFormat::DDMMYYYY]]
  end

  # TODO: This should raise an ActiveRecord::RecordNotFound, not return nil.
  #       Unfortunately, there's a lot of clients to this method which expect
  #       nil as a return value.
  # Finds a FinancialInst by its id, name, or Wesabe ID from the approved list,
  # or the user's unapproved list.
  #
  #   FinancialInst.find_for_user(1, @user.id) #=> <FI>
  #   FinancialInst.find_for_user("Bank Of Mars", @user)
  #   FinancialInst.find_for_user("us-10291", @user)
  def self.find_for_user(id_or_name_or_wesabe_id, user)
    if id_or_name_or_wesabe_id.blank?
      return nil
    else
      id = id_or_name_or_wesabe_id
      c = ConditionsConstructor.new
      c.add "id = ? OR name = ? OR wesabe_id = ?", id, id, id

      if user
         if user.admin?
           # don't care what the status is
         else
           c.add "(status in (?)) OR (status = ? AND creating_user_id = ?)",
            [Status::ACTIVE, Status::HIDDEN], Status::UNAPPROVED, user.id
         end
      else
        # just looking for public FIs
        c.add "status = ?", Status::ACTIVE
      end

      active, unapproved = find(:all, :conditions => c.join).
        # FIXME: MySQL should be doing this, not us.
        # MySQL considers the condition "id = '1abc'" to be the same as "id = 1",
        # which seems just idiotic.
        select {|fi| [fi.id.to_s, fi.name, fi.wesabe_id].include?(id.to_s)}.
        partition {|fi| fi.active? || fi.hidden?}
      # favor active over unapproved
      if active.any?
        return active.first
      elsif unapproved.any?
        return unapproved.first
      end
    end
  end

  # Find a FinancialInst by its id, name, or Wesabe ID from the approved list.
  #
  #   FinancialInst.find_public(1)                => #<FinancialInst id: 1 ...>
  #   FinancialInst.find_public("Bank of Mars")   => #<FinancialInst name: "Bank of Mars" ...>
  #   FinancialInst.find_public("us-10291")       => #<FinancialInst wesabe_id: "us-10291" ...>
  def self.find_public(id_or_name_or_wesabe_id)
    find_for_user(id_or_name_or_wesabe_id, nil)
  end

  # Returns a paginated array of unapproved FIs in chronological order
  def self.paginated_find_all_unapproved(page, options)
    paginate(:all, :page => page, :per_page => options[:per_page] || 100, :order => "created_at ASC", :conditions => ["status = ?", Status::UNAPPROVED])
  end

  # Returns an array of unapproved FIs in chronological order.
  def self.find_all_unapproved
    find_all_by_status(Status::UNAPPROVED, :order => "created_at ASC")
  end

  # FIs that the user has created. Excludes the FI with an ID of 1.
  def self.all_names_for_user(user)
    for_user(user).order(:name).map(&:name)
  end

  # Removes the +from+ FI into the +to+ FI.
  #
  #   FinancialInst.merge(mistaken_fi, canonical_fi)
  def self.merge(from, to)
    from = from.id if from.is_a?(FinancialInst)
    to = to.id if to.is_a?(FinancialInst)

    FinancialInst.transaction do
      FinancialInst.update_all(['mapped_to_id = ?, status = ?', to, Status::DELETED], ['id = ?', from])
      Account.update_all(['financial_inst_id = ?', to], ['financial_inst_id = ?', from])
    end
  end

  # Returns an array of name/id tuples for all financial institutions. Suitable
  # for use with the +select+ helper.
  #
  #     <%= select :account, :financial_inst_id, FinancialInst.ids_and_names %>
  def self.ids_and_names
    select(:id, :name, :wesabe_id, :homepage_url, :login_url).
      where(['id != ? AND status = ?', UNKNOWN_FI_ID, Status::ACTIVE]).
      order(:name).map do |fi|
        site = (URI.parse(fi.url).host rescue nil) || "none"
        ["#{fi.name} [#{site}] (#{fi.wesabe_id})", fi.id]
      end
  end

  # Returns an array of the connection type options
  def self.connection_type_options
    ["Manual", "Automatic", "Mechanized"]
  end

  # Returns the model's attributes as an XML document.
  def to_xml(options = {})
    fields = %w{ wesabe_id name connection_type homepage_url login_url updated_at }
    case connection_type
    when "Automatic"
      fields += %w{ username_label password_label ofx_url ofx_org ofx_fid ofx_broker }
    when "Mechanized"
      fields += %w{ date_format statement_days username_label password_label }
    end
    return super(options.update(:only => fields))
  end

  # Returns the name of the FI's country. If the FI has no country set, returns
  # <tt>"None"</tt>.
  def country_name
    country_id && country ? country.name : "None"
  end

  # Returns the login URL or the homepage URL, depending on which the FI has.
  def url
    [login_url, homepage_url].find {|url| not url.blank?}
  end

  def help_text(type=:default, value=:nil)
    type = type.respond_to?(:to_sym) ? type.to_sym : type.to_s.to_sym unless type.is_a?(Symbol)

    if value == :nil
      # getter
      value = self.help_text_hash
      return value.has_key?(type) ? value[type] : value[:default]
    else
      # setter
      oldvalue = self.help_text_hash

      value = YAML.load(value) if value.is_a?(String)
      value = {type => value} if value.is_a?(String)
      value = oldvalue.merge(value || {})

      write_attribute(:help_text, value)
    end
  end

  def help_text_hash
    value = read_attribute(:help_text)
    value = YAML.load(value) if value.is_a?(String)
    value = {:default => value} if value.is_a?(String)
    value ||= {}
  end

  def help_text=(value)
    help_text(:default, value)
  end

  # Returns what this +FinancialInst+ calls the username (for use in forms).
  #
  #   @bank_of_america.username_label # => "Online ID"
  #
  # @return [String, nil]
  #   The label to use when asking for this +FinancialInst+'s username, or
  #   +nil+ if it does not use a special label.
  #
  def username_label
    field = login_field(:username)
    field ? field[:label] : read_attribute(:username_label)
  end

  # Sets what this +FinancialInst+ calls the username (for use in forms).
  #
  def username_label=(label)
    self.login_fields ||= DEFAULT_LOGIN_FIELDS.dup
    login_field(:username)[:label] = label
  end

  # Returns what this +FinancialInst+ calls the password (for use in forms).
  #
  #   @bank_of_america.password_label # => "Passcode"
  #
  # @return [String, nil]
  #   The label to use when asking for this +FinancialInst+'s username, or
  #   +nil+ if it does not use a special label.
  #
  def password_label
    field = login_field(:password)
    field ? field[:label] : read_attribute(:password_label)
  end

  # Sets what this +FinancialInst+ calls the password (for use in forms).
  #
  def password_label=(label)
    self.login_fields ||= DEFAULT_LOGIN_FIELDS.dup
    login_field(:password)[:label] = label
  end

  def login_field(key)
    login_fields && login_fields.find{|field| field[:key] == key.to_s}
  end

  # Returns true if the FI uses the DD/MM/YYYY format in its statements. Returns
  # false if the MM/DD/YYYY format is used.
  def date_format_ddmmyyyy?
    statement_date_format == DateFormat::DDMMYYYY
  end

  # Returns true if the FI is approved; false otherwise.
  def approved
    active?
  end
  alias_method :approved?, :approved

  # If +is_approved+ is true, the instance's +status+ will be set to +ACTIVE+.
  # Otherwise, the instance's +status+ will be set to +UNAPPROVED+.
  def approved=(is_approved)
    if is_approved && is_approved != 0 && is_approved != "0"
      self.status = Status::ACTIVE
    else
      self.status = Status::UNAPPROVED
    end
  end

  def to_s
    name
  end

  def to_param
    wesabe_id
  end

  def presenter
    FinancialInstPresenter.new(self)
  end

  # return true if ssu is supported for this FI. If a user is provided, check for that user
  def ssu_support?(user = nil)
    ssu_support == SSUSupport::GENERAL
  end
private

  # Generates an options hash for AR.find-alikes which will find all FIs usable
  # by a given user.
  def self.options_for_all_user_fis(user)
    for_user(user)
  end

  # If the FI has a country, but doesn't have a wesabe ID, generate a new one.
  def generate_wesabe_id
    if country && wesabe_id.nil? && id != UNKNOWN_FI_ID
      if last_id = FinancialInst.where(["wesabe_id LIKE ?", "#{country.code}-%"]).maximum(:wesabe_id)
        num = last_id.split("-", 2).last.to_i + 1
      else
        num = 100
      end
      self.wesabe_id = "%s-%06d" % [country.code, num]
    end
  end

  # Checks for existing accounts, returns false if there are existing accounts,
  # which halts the callback chain.
  # REVIEW: This is kind of a strange way to enforce referential integrity. Database constraints would make way more sense.
  def check_for_existing_active_accounts
    return accounts.count == 0
  end

end

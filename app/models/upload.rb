require 'pathname'

# represents a single user FI statement upload
class Upload < ActiveRecord::Base
  belongs_to :client_platform
  belongs_to :upload_format
  belongs_to :financial_inst
  has_many :txactions,
           :conditions => ['status = ?', Constants::Status::ACTIVE]
  has_many :all_txactions, :class_name => 'Txaction', :dependent => :destroy
  has_many :account_balances,
           :conditions => ['status = ?', Constants::Status::ACTIVE]
  has_many :all_account_balances, :class_name => 'AccountBalance', :dependent => :destroy
  has_and_belongs_to_many :accounts

  attr_accessor :user_id, :account_key, :from_ssu
  attr_accessor :raw_request, :statement, :converted_statement, :original_format
  attr_accessor :account_name, :account_number, :account_type, :balance
  attr_accessor :fi_id, :fi_wesabe_id, :fi_name
  attr_accessor :currency
  attr_accessor :bulk_update
  attr_accessor :account_cred_id

  before_create :generate_guid
  before_destroy :delete_statement_file

  # valid types for status column
  unless defined?(Status)
    class Status
      ACTIVE = 0
      DELETED = 1
      FATAL_ERROR = 2
      NO_INPUT_ERROR = 3
      PARSE_ERROR = 4
      UNSUPPORTED_FORMAT_ERROR = 5
      UNKNOWN_ERROR = 6
      TIMEOUT_ERROR = 7
    end
  end

  # client_name strings used for various client types
  class ClientTypes
    SSU = ["Wesabe-ServerSideUploader"]
    WEB = ["OFX2Importer", "Wesabe-WebUploader"]
  end

  def from_ssu?
    from_ssu
  end

  # # exceptions
  # class OFXConversionException < Exception; end
  # class UnsupportedStatementType < Exception; end

  # save an uploaded statement to the filesystem and return an Upload object
  # We jump through a lot of hoops here to just store ids and not actual objects because we may need
  # to store the Upload object in memcache (if it is a QIF upload and we need to go back and get more information),
  # and the less serialization of models we need to do, the better

  # FIXME: this is really ugly. Must rewrite. In fact, the whole upload process is a freakin' mess.
  def self.generate(params = {})
    upload = new
    upload.currency = params[:currency] || params[:user].default_currency.name
    upload.user_id = params[:user].id
    upload.account_key = params[:user].account_key
    params.delete(:user)

    upload.raw_request = params[:raw_request]
    upload.statement = params[:statement]
    upload.account_cred_id ||= params[:account_cred_id]
    upload.bulk_update = true

    # if we're passed an account, use it
    if params[:account]
      upload.fi_id = params[:account].financial_inst.id
      upload.fi_wesabe_id = params[:account].financial_inst.wesabe_id
      upload.fi_name = params[:account].financial_inst.name
      upload.account_name = params[:account].name
      upload.account_type = params[:account].account_type.raw_name
      upload.account_number = params[:account].account_number
      params.delete(:account)
    else
      if params[:financial_inst_id]
        upload.fi_id = params[:financial_inst_id]
        fi = FinancialInst.find(upload.fi_id)
        upload.fi_wesabe_id = fi.wesabe_id
        upload.fi_name = fi.name
      elsif params[:wesabe_id]
        # find the FI. If it has been remapped to another FI, use that instead
        if fi = FinancialInst.find_by_wesabe_id(params[:wesabe_id])
          fi = FinancialInst.find(fi.mapped_to_id) if fi.mapped_to_id
          upload.fi_id = fi.id
          upload.fi_wesabe_id = fi.wesabe_id
          upload.fi_name = fi.name
        else
          upload.fi_id = FinancialInst::UNKNOWN_FI_ID
          upload.fi_wesabe_id = ""
          upload.fi_name = FinancialInst.find(upload.fi_id).name
        end
        params.delete(:wesabe_id)
      end
      upload.account_name = params[:account_name]
    end

    upload.balance ||= params[:balance]
    upload.account_number ||= params[:account_number]
    upload.account_type ||= params[:account_type]
    upload.client_name ||= params[:client_name]
    upload.client_version ||= params[:client_version]
    upload.client_platform_id ||= params[:client_platform_id]

    upload.financial_inst_id = upload.fi_id

    upload.save_statement
    upload.convert_to_ofx2

    format_name = params[:upload_format] || upload.original_format
    upload.upload_format_id = UploadFormat.find_or_create_by_name(format_name).id

    upload.save!
    return upload
  end

  def destroy
    _run_destroy_callbacks do
      if new_record?
        super
      else
        # destroy AccountUploads manually, since we get into a loop if we use :dependent => :destroy
        transaction do
          AccountUpload.delete_all(["upload_id = ?", id])
          super
        end
      end
    end
  end

  # just destroy the upload for the given account if there are more than one accounts associated wth this upload
  def destroy_for_account(account)
    if accounts.size == 1
      destroy
    else
      transaction do
        Txaction.destroy_all(["account_id = ? and upload_id = ?", account.id, id])
        AccountBalance.delete_all(["account_id = ? and upload_id = ?", account.id, id])
        AccountUpload.delete_all(["account_id = ? and upload_id = ?", account.id, id])
      end
    end
  end

  # delete the associated file (called from before_destroy)
  def delete_statement_file
    begin
      File.delete(filepath) if filepath && File.file?(filepath)
    rescue Errno::ENOENT => e
      logger.error("[delete_statement_file] #{e.message}")
    end
    true # don't want to break the callback chain
  end

  # return true if the upload is owned by the given user
  def owned_by_user?(user)
    accounts.first.account_key == user.account_key
  end

  # convenience method to return the user (with account_key) associated with this upload
  def user
    if user_id
      user = User.find(user_id)
      user.account_key = account_key
      return user
    end
  end

  # convert the upload to ofx2
  def convert_to_ofx2
    # assume that balances are negative for credit cards and credit lines, unless overridden by '+'
    if balance # make sure nil balance stays that way--QIF uploads with no balance are computed
      if account_type && account_type =~ /Credit/i && balance !~ /^\s*\+/
        self.balance = -Currency.normalize(balance).to_d.abs
      else
        self.balance = Currency.normalize(balance).to_d
      end
    end

    output = MakeOFX2.convert(statement,
                              :account_number => account_number,
                              :account_type => account_type,
                              :balance => balance,
                              :currency => currency,
                              :financial_inst => FinancialInst.find(financial_inst_id))

    self.converted_statement = output
    # extract the statement format from the output
    if m = output.match(/-- Converted from: (.*?) --/)
      self.original_format = m[1]
    else
      self.original_format = "OFX/2"
    end

    logger.info("conversion succeeded. format: #{original_format}")

  rescue MakeOFX2::FatalError => e
    self.status = Status::FATAL_ERROR
    self.upload_format = UploadFormat.find_or_create_by_name('UNKNOWN')
    report_exception(e)
  rescue MakeOFX2::NoInputError => e
    self.status = Status::NO_INPUT_ERROR
    self.upload_format = UploadFormat.find_or_create_by_name('UNKNOWN')
    report_exception(e)
  rescue MakeOFX2::ParseError => e
    self.status = Status::PARSE_ERROR
    if m = e.debug_data.match(/exception during '(.*?)'/)
      format = m[1]
    else
      format = 'UNKNOWN'
    end
    self.upload_format = UploadFormat.find_or_create_by_name(format)
    e.statement_type = upload_format
    report_exception(e)
  rescue MakeOFX2::UnsupportedFormatError => e
    self.status = Status::UNSUPPORTED_FORMAT_ERROR
    if m = e.debug_data.match(/source format '(.*?)'/)
      format = m[1]
    else
      format = 'UNKNOWN'
    end
    self.upload_format = UploadFormat.find_or_create_by_name(format)
    # only send exception message if format is unknown
    report_exception(e)
  rescue MakeOFX2::TimeoutError => e
    status = Status::TIMEOUT_ERROR
    self.upload_format = UploadFormat.find_or_create_by_name('UNKNOWN')
    report_exception(e)
  rescue MakeOFX2::UnknownError => e
    status = Status::UNKNOWN_ERROR
    self.upload_format = UploadFormat.find_or_create_by_name('UNKNOWN')
    report_exception(e)
  end

  # reverse (mm/dd <-> dd/mm) any ambiguous dates in the transactions in this upload
  def swap_ambiguous_dates!
    Txaction.transaction do
      txactions.each { |t| t.swap_ambiguous_date_posted! }
    end
  end

  def txaction_count_for_account(account)
    txactions.count(:conditions => ["account_id = ?", account.id])
  end

  def self.uploads_for_user(user)
    find(:all, :include => 'accounts',
      :conditions => ['accounts.account_key = ? and uploads.status = ?', user.account_key, Constants::Status::ACTIVE],
      :order => 'uploads.created_at desc')
  end

  # store the uploaded file on the file system
  # FIXME: need to rejigger things so that if the statement uploaded is represented
  # as a Tempfile (vs. StringIO), we just copy the file to the new location, rather than read it in to a ruby string
  # first. See http://cleanair.highgroove.com/articles/2006/10/03/mini-file-uploads
  def save_statement
    # store file in directory defined in environments/api.rb
    user_dir = self.class.statement_dir(user.account_key)
    FileUtils.mkdir_p(user_dir) # create the dir and all parent dirs

    # find available filename
    # FIXME: race condition here, although highly unlikely
    # (user would have to be running multiple uploaders simultaneously, or multiple users
    # uploading to the same account); still this should be done atomically
    timestamp = Time.now.strftime("%Y%m%d%H%M%S")
    serial = 1
    while File.exists?(filename = ("%s-%02d.dat" % [timestamp, serial])) do
      serial += 1
    end

    # write the file
    self.filepath = user_dir + filename
    File.open(filepath, "w") { |f| f << CGI::unescapeHTML((raw_request || statement).to_s) }
    logger.info("saved upload to '#{filepath}'")
  end

  # given an account_key, return the path to the directory where statements should be stored
  # break it up into pieces to avoid hitting the 32,000 subdir limit in ext3
  def self.statement_dir(account_key)
    Pathname.new(File.join(ApiEnv::PATH[:statement_files], account_key[0..2], account_key[3..5], account_key))
  end

  def filepath
    value = read_attribute(:filepath)
    return nil if value.nil?

    akey = self.account_key || begin
      account = accounts.first
      account && account.account_key
    end
    return nil if akey.nil?

    Upload.statement_dir(akey) + File.basename(value)
  end

  # return true if this is an investment upload
  def investment_statement?
    !!(converted_statement =~ /<INVSTMTMSGSRSV1>/)
  end

  private

  def report_exception(ex)
    subject = "fixofx failed importing #{upload_format.name} statement from #{fi_name} (#{fi_wesabe_id}) with #{ex.class}"
    logger.error(subject + " [filepath: #{filepath}]")
    raise ex
  end

  # generate a guid for this upload. called from before_create
  def generate_guid
    begin
      self.guid = UID.generate(8)
    end while self.class.find_by_guid(guid)
  end
end
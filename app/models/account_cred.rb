require 'net/http'
require 'net/https'

class AccountCred < ActiveRecord::Base
  belongs_to :user, :primary_key => 'account_key', :foreign_key => 'account_key'
  belongs_to :financial_inst
  has_many :ssu_jobs,
    :conditions => "expires_at > NOW()",
    :order => "created_at DESC"
  has_many :all_ssu_jobs,
    :class_name => "SsuJob",
    :order => "created_at DESC",
    :dependent => :destroy
  has_one :last_ssu_job,
    :class_name => "SsuJob",
    :order => "created_at DESC"
  has_many :accounts,
    :conditions => ["accounts.status IN (?)", [Constants::Status::ACTIVE, Constants::Status::DISABLED]]
  has_many :disabled_accounts, :class_name => "Account",
    :conditions => ["accounts.status = ?", Constants::Status::DISABLED]
    # destroy dependencies for accounts are handled in #clear_accounts

  validates_presence_of :account_key, :cred_guid, :cred_key, :financial_inst_id
  validates_uniqueness_of :cred_guid

  before_destroy :delete_cred_from_ssu_service, :clear_accounts

  alias_attribute :credkey, :cred_key
  alias_attribute :credguid, :cred_guid

  def to_param
    cred_guid
  end

  def to_json(options = nil)
    { :id => cred_guid,
      :accounts => account_ids_for_user,
      :job => last_ssu_job && last_ssu_job.presenter.internal_data
    }.to_json
  end

  def account_ids_for_user
    accounts.map(&:id_for_user)
  end

  def successful?
    last_ssu_job && last_ssu_job.successful?
  end

  def failed?
    last_ssu_job && last_ssu_job.failed?
  end

  def pending?
    last_ssu_job && last_ssu_job.pending?
  end

  def begin_job(user)
    begin
      # posts to ssu.wesabe.com/jobs
      job_guid = post(URI.join(SSU_INTERNAL_URI, "/jobs").to_s,
        :user_id => user.id,
        :credguid => cred_guid,
        :credkey => cred_key,
        :fid => financial_inst.wesabe_id)

      return job_guid
    rescue SsuError => e
      logger.error(e.message)
      logger.error("Job would have been for credguid=#{cred_guid}, fid=#{financial_inst.wesabe_id}")

      return nil
    end
  end

  def destroyable_by?(user)
    user.admin? || self.user == user
  end

protected

  def post(base_uri, form_data = {})
    url = URI.parse(base_uri)
    req = Net::HTTP::Post.new(url.path)
    req.set_form_data(form_data)
    res = handle_auth_and_make_request(req, url)

    unless (res.code == '200') && (res.body =~ /\w{8}-\w{4}-\w{4}-\w{4}-\w{12}/)
      raise SsuError, "POSTing to SSU failed with status code #{res.code} and body:\n#{res.body}"
    end

    return res.body
  end

  def delete_cred_from_ssu_service
    url = URI.join(SSU_INTERNAL_URI, "/creds/#{cred_guid}")
    req = Net::HTTP::Delete.new(url.path)
    res = handle_auth_and_make_request(req, url)

    raise Exception, "error deleting creds from SSU. Got status #{res.code} and body:\n" +
      "#{res.body}" unless %w[200 404].include?(res.code)
  end

  def handle_auth_and_make_request(req, url)
    req.basic_auth url.user, url.password if url.user && url.password

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme=='https')
    http.request(req)
  rescue Errno::ETIMEDOUT, Timeout::Error
    raise SsuError, "timeout connecting to #{url} via #{HTTP_PROXY_HOST}:#{HTTP_PROXY_PORT}"
  rescue Errno::ECONNREFUSED
    raise SsuError, "Couldn't connect to SSU service at #{url}"
  end

  def clear_accounts
    # Eliminate disabled accounts from the database
    Account.delete(disabled_accounts.map(&:id))

    # Remove ssu status results and disassociate accounts
    Account.update_all("account_cred_id = NULL", ["account_cred_id = ?", id])
  end

end
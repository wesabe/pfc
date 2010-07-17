class SsuJob < ActiveRecord::Base
  class Status
    SUCCESSFUL        = 200
    PENDING           = 202
    BAD_REQUEST       = 400
    UNAUTHENTICATED   = 401
    UNAUTHORIZED      = 403
    GENERAL_ERROR     = 500
    CONNECTION_ERROR  = 503
    TIMEOUT           = 504
  end

  belongs_to :account_cred
  belongs_to :user, :primary_key => 'account_key', :foreign_key => 'account_key'

  validates_presence_of :account_key, :job_guid, :status, :account_cred

  serialize :account_ids
  serialize :data

  alias_attribute :jobid, :job_guid

  before_save :update_accounts

  scope :pending,    :conditions => {:status => Status::PENDING}
  scope :complete,   :conditions => ['status <> ?', Status::PENDING]
  scope :failed,     :conditions => ['status NOT IN (?)', [Status::PENDING, Status::SUCCESSFUL]]
  scope :successful, :conditions => {:status => Status::SUCCESSFUL}
  scope :signups,    :conditions => 'ssu_jobs.id = (SELECT MIN(j2.id) FROM ssu_jobs j2 WHERE j2.account_cred_id = ssu_jobs.account_cred_id)'

  def accounts
    user.accounts.where(:id_for_user => account_ids)
  end

  def expired?
    expires_at <= Time.now
  end

  def complete?
    !pending?
  end

  def successful?
    status == Status::SUCCESSFUL
  end

  def failed?
    !successful? && !pending?
  end

  def pending?
    status == Status::PENDING
  end

  def denied?
    [Status::UNAUTHENTICATED, Status::UNAUTHORIZED].include?(status)
  end

  def succeeded_at
    updated_at if successful?
  end

  def update_status(params)
    ## generate the UPDATE conditions
    update_conditions_constructor = ConditionsConstructor.new
    # only update myself
    update_conditions_constructor.add('id = ?', id)
    # only update incomplete jobs
    update_conditions_constructor.add('status = ?', Status::PENDING)
    # only update if this is newer than the db version
    update_conditions_constructor.add('version < ? OR version IS NULL', params[:version].to_i)

    ## generate the UPDATE data
    data = ActiveSupport::JSON.decode(params[:data].to_s)[params[:result]] unless params[:data].blank?
    updates = {:status => params[:status], :result => params[:result], :version => params[:version]}
    updates[:data] = data.to_yaml if data

    ## update associated accounts
    self.update_accounts(true)

    ## do the UPDATE
    self.class.update_all(updates, update_conditions_constructor.conditions)

    ## return the updated version
    return reload
  end

  def to_json(options = nil)
    raise NotImplementedError, "Intentionally left out to encourage the use of SsuJobPresenter instead"
  end

  def presenter
    SsuJobPresenter.new(self)
  end

  def update_accounts(save=false)
    self.account_ids = account_cred.accounts.map(&:id_for_user)
    self.class.update_all({:account_ids => self.account_ids.to_yaml}, {:id => self.id}) if save
  end

  # Class methods
  def self.start(user, cred)
    case cred.last_ssu_job && cred.last_ssu_job.status
    when Status::PENDING
      return false unless cred.last_ssu_job.expired?
    when Status::UNAUTHENTICATED, Status::UNAUTHORIZED
      return false
    end
    job_guid = cred.begin_job(user)
    return unless job_guid
    create! :account_cred => cred,
           :account_key => user.account_key,
           :job_guid => job_guid,
           :expires_at => 1.hour.from_now,
           :status => Status::PENDING,
           :result => "started",
           :created_at => Time.now
  end
end
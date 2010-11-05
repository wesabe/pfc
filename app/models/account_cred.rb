require 'net/http'
require 'net/https'

class AccountCred < ActiveRecord::Base
  belongs_to :user, :primary_key => 'account_key', :foreign_key => 'account_key'
  belongs_to :financial_inst
  has_many   :jobs, :class_name => 'SsuJob'
  has_many   :accounts

  has_one    :last_job, :class_name => 'SsuJob', :order => 'created_at DESC'

  scope :for_user, lambda {|user| {:conditions => {:account_key => user.account_key}} }

  validates_presence_of :account_key, :financial_inst_id

  def enqueue_sync
    if jobid = SSU::SyncJob.enqueue(self, user)
      SsuJob.create!(
        :status       => SsuJob::Status::PENDING,
        :account_key  => account_key,
        :job_guid     => jobid,
        :version      => 0,
        :account_cred => self
      )
    end
  end

  def creds
    ActiveSupport::JSON.decode(read_attribute(:creds))
  end

  def creds=(creds)
    creds = ActiveSupport::JSON.encode(creds) unless creds.nil? || creds.is_a?(String)
    write_attribute(:creds, creds)
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

  def destroyable_by?(user)
    user.admin? || self.user == user
  end

  def as_json(options=nil)
    raise NotImplementedError, "use present(account_cred) instead"
  end
end

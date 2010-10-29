require 'net/http'
require 'net/https'

class AccountCred < ActiveRecord::Base
  belongs_to :user, :primary_key => 'account_key', :foreign_key => 'account_key'
  belongs_to :financial_inst
  has_many   :jobs, :class_name => 'SsuJob'

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
end

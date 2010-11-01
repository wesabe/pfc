class StatementImport
  @queue = :normal

  attr_reader :user
  attr_reader :financial_inst
  attr_reader :statement
  attr_reader :jobid

  def self.perform(user_id, fid, statement, jobid=nil)
    user = User.find(user_id)
    new(user, FinancialInst.find_for_user(fid, user), statement, jobid).import
  end

  def initialize(user, financial_inst, statement, jobid=nil)
    @user, @financial_inst, @statement, @jobid = user, financial_inst, statement, jobid
  end

  def import
    User.with_current_user(user) do
      upload = Upload.generate(
        :user               => user,
        :account_type       => nil,
        :statement          => statement,
        :client_name        => 'StatementImport',
        :client_version     => nil,
        :client_platform_id => nil,
        :financial_inst_id  => financial_inst.id
      )

      Importer.import(upload)
    end
  end

  private

  def ssu_job
    @ssu_job ||= jobid && SsuJob.find_by_job_guid(jobid)
  end
end

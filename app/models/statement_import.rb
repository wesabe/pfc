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
      upload.reload

      if account_cred.nil?
        warn { "has no account credentials" }
      elsif upload.accounts.empty?
        warn { "no accounts to associate!" }
      else
        upload.accounts.each do |account|
          account = Account.find(account.id) # work around read-only attributes
          info { "associating #{account} with account credentials" }
          account.account_cred = account_cred
          account.save
        end
      end
    end
  end

  private

  def ssu_job
    @ssu_job ||= jobid && SsuJob.find_by_job_guid(jobid)
  end

  def account_cred
    ssu_job && ssu_job.account_cred
  end

  %w[debug info warn error].each do |level|
    class_eval <<-RUBY
    def #{level}(text=nil)
      Rails.logger.#{level} { "StatementImport(\#{jobid || 'no job'}) \#{text || yield}" }
    end
    RUBY
  end
end

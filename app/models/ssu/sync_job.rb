require 'timeout'

module SSU
  class SyncJob
    @queue = :normal

    attr_writer   :jobid

    attr_accessor :fid
    attr_accessor :user_id
    attr_accessor :cookies

    attr_reader :creds
    attr_reader :status
    attr_reader :statements

    def jobid
      @jobid ||= self.class.make_jobid
    end

    def profile
      @profile ||= SSU::Profile.with_name(jobid)
    end

    def self.enqueue(account_cred, user)
      Resque.enqueue(
        self,
        jobid = make_jobid,
        account_cred.financial_inst.wesabe_id,
        user.id,
        account_cred.creds,
        account_cred.cookies
      )

      return jobid
    end

    def self.make_jobid
      UUID.create.to_s
    end

    def self.perform(jobid, fid, user_id, creds, cookies)
      job = new

      job.jobid   = jobid

      job.fid     = fid
      job.user_id = user_id
      job.creds   = creds
      job.cookies = cookies

      job.perform
    end

    def perform
      daemon.start
      begin
        start_sync

        Timeout.timeout(10*60) do
          wait_for_sync_to_finish
        end

        daemon.stop
      rescue Timeout::Error
        logger.error "SyncJob(#{jobid}) Sync timed out, stopping the daemon"
        daemon.stop

        ssu_job && ssu_job.update_attributes(
          :status => SsuJob::Status::GENERAL_ERROR,
          :result => "ssu.timeout"
        )
      rescue Object
        unless Rails.env.development?
          daemon.stop rescue logger.warn "SyncJob(#{jobid}) Unable to stop daemon!"
        end

        ssu_job && ssu_job.update_attributes(
          :status => SsuJob::Status::GENERAL_ERROR,
          :result => "ssu.sync.exception"
        )

        raise
      end
    end

    def creds=(creds)
      if creds != @creds
        @creds = creds

        if paused?
          @last_resumed_version = status['version']
          daemon.request('job.resume', :creds => creds)
        end
      end
    end

    def paused?
      status &&
      (@last_resumed_version.nil? || @last_resumed_version < status['version']) &&
      status['result'] &&
      status['result'].starts_with?('suspended')
    end

    def stop
      daemon.stop
    end

    def start_sync
      logger.info { "SyncJob(#{jobid}) Starting sync" }
      daemon.request('job.start',
        :jobid   => jobid,
        :fid     => fid,
        :creds   => creds,
        :user_id => user_id,
        :cookies => cookies
      )
    end

    def daemon
      @daemon ||= SSU::Daemon.new(profile)
    end

    def daemon=(daemon)
      @daemon = daemon
    end

    def logger
      @logger ||= Rails.logger
    end

    def logger=(logger)
      @logger = logger
    end

    def complete?
      status && status.fetch('completed')
    end

    private

    def wait_for_sync_to_finish
      logger.info { "SyncJob(#{jobid}) Waiting for sync to finish" }

      while daemon.running?
        self.status = daemon.request('job.status')
        self.statements = daemon.request('statement.list');

        if complete?
          return
        elsif paused? && account_cred
          # attempt to update the creds
          self.creds = account_cred.reload.creds
        end

        sleep 1
      end

      logger.warn { "SyncJob(#{jobid}) SSU Daemon quit unexpectedly!" }
      ssu_job && ssu_job.update_attributes(:status => 500, :result => 'ssu.error.quit')
    end

    def status=(status)
      if @status.nil? || (@status['version'] < status['version'])
        logger.info { "SyncJob(#{jobid}) Status changed to #{status['status']} #{status['result']}" }
        @status = status

        if ssu_job
          ssu_job.update_attributes(
            :result  => status['result'],
            :status  => status['status'],
            :data    => status['data'],
            :version => status['version']
          )

          ssu_job.account_cred.update_attributes(
            :cookies => status['cookies']
          )
        end
      else
        logger.debug { "SyncJob(#{jobid}) Status has not changed" }
      end
    end

    def statements=(statements)
      logger.debug { "SyncJob(#{jobid}) Available statements: #{statements.join(', ')}" } unless statements.blank?

      @statements ||= []
      statements_to_process = statements - @statements
      @statements = statements

      statements_to_process.each do |statement|
        logger.info { "SyncJob(#{jobid}) Adding statement #{statement} to the import queue" }
        Resque.enqueue(StatementImport, user_id, fid, daemon.request('statement.read', statement), jobid)
      end
    end

    def ssu_job
      @ssu_job ||= SsuJob.find_by_job_guid(jobid)
    end

    def account_cred
      ssu_job && ssu_job.account_cred
    end
  end
end

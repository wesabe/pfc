module SSU
  class SyncJob
    @queue = :normal

    attr_writer   :jobid

    attr_accessor :fid
    attr_accessor :user_id
    attr_accessor :creds
    attr_accessor :cookies

    def jobid
      @jobid ||= UUID.create.to_s
    end

    def profile
      @profile ||= SSU::Profile.with_name(jobid)
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
      start_sync
      wait_for_sync_to_finish
      daemon.stop
    end

    def stop
      daemon.stop
    end

    def start_sync
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

    private

    def wait_for_sync_to_finish
      last_version = 0

      while daemon.running?
        if status = daemon.request('job.status')
          this_version = status['version']
          if last_version < this_version
            last_version = this_version
            ssu_job.update_attributes(
              :result => status['result'],
              :status => status['status'],
              :data   => status['data']
            )
          end
        end

        sleep 1
      end
    end

    def ssu_job
      @ssu_job ||= SsuJob.find_by_job_guid(jobid)
    end
  end
end
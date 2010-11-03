if Service.config.nil?
  raise "No services.yml configuration file found or no configuration for #{Rails.env} environment found"
end

if Pfc::Application.standalone?
  start_service = proc do |name|
    begin
      service = Service.get(name)
      service.start unless service.running?
    rescue => e
      Rails.logger.warn <<-EOS
  Unable to start #{name} -- maybe you didn't include the options needed to start it for you in #{Service.config_path}:
    start_command: A command-line invocation to start #{name}
    pid_file: A file that the pid for #{name} will be stored (e.g. /var/run/#{name}.pid)
    log_file: A file that #{name} will write its logs to (e.g. /var/log/#{name}.log)
    start_timeout: # of seconds to wait for #{name} to start listening for requests
    log_file_activity_timeout: # of seconds to wait for #{name} to start writing to its log file
    daemonize_for_me: true (unless the wrapper script you're using will daemonize it)

  Here's the actual exception that occurred:
    #{e}
    #{e.backtrace.join("\n  ")}
      EOS
    end
  end

  start_service[:brcm]
  start_service[:redis]
else
  Rails.logger.info "If you're running this as a personal copy on your own machine, you can start with STANDALONE=1 to bring up the necessary services automatically."
end

if Service.config.nil?
  raise "No services.yml configuration file found or no configuration for #{RAILS_ENV} environment found"
end

if Pfc::Application.standalone?
  begin
    brcm = Service.get(:brcm)
    brcm.start unless brcm.running?
  rescue => e
    Rails.logger.warn <<-EOS
Unable to start BRCM -- maybe you didn't include the options needed to start it for you in #{Service.config_path}:
  start_command: A command-line invocation to start BRCM (e.g. sh -c "/path/to/brcm/script/server --pid /tmp/brcm.pid >> /tmp/brcm.log")
  pid_file: A file that the pid for BRCM will be stored (e.g. /tmp/brcm.pid)
  log_file: A file that BRCM will write its logs to (e.g. /tmp/brcm.log)
  start_timeout: # of seconds to wait for BRCM to start listening for requests (might want to pick 20+ depending on your machine)
  log_file_activity_timeout: # of seconds to wait for BRCM to start writing to its log file (best to make this the same as start_timeout)
  daemonize_for_me: true (unless the wrapper script you're using will daemonize it)

Here's the actual exception that occurred:
  #{e}
  #{e.backtrace.join("\n  ")}
    EOS
  end
else
  Rails.logger.info "If you're running this as a personal copy on your own machine, you can start with STANDALONE=1 to bring up the necessary services automatically."
end

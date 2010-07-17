desc "Analyzes PFC's source code with Flog. High Flog scores mean more complicated code."
task :flog do
  require "flog"
  flogger = Flog.new
  flogger.process_files(FileList["app/**/*.rb"] + FileList["lib/**/*.rb"])
  flogger.report
end
require 'thor/tasks'

class Default < Thor
  # Set up standard Thortasks
  spec_task(Dir["spec/**/*_spec.rb"])
  spec_task(Dir["spec/**/*_spec.rb"], :name => "rcov", :rcov =>
    {:exclude => %w(spec /Library /Users task.thor lib/getopt.rb)})
end

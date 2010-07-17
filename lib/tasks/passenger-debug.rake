# from http://duckpunching.com/passenger-mod_rails-for-development-now-with-debugger
task :restart do
  system("touch tmp/restart.txt")
  system("touch tmp/debug.txt") if ENV["DEBUG"] == 'true'
end

namespace :restart do
  task :debug do
    ENV["DEBUG"] = 'true'
    Rake::Task["restart"].invoke
  end
end

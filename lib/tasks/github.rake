namespace :github do
  task :update_gists do
    require 'open-uri'

    Dir['public/gists/*.js'].each do |gist|
      File.open(gist, 'w') do |file|
        url = "http://gist.github.com/#{File.basename(gist)}"
        puts "Updating #{File.basename(gist)} from #{url}..."
        file << open(url).read
        puts "`- done"
      end
    end
  end
end

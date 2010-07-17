def find_and_replace_in_source_files(find, replace)
  puts "Search and replace #{find.inspect} => #{replace.inspect}"

  extensions = %w[.rhtml .rxml .erb .builder .rb .css .js .rake]
  files = Dir["**/*"]

  files.each do |file_name|
    next if (file_name =~ /^vendor/) || !extensions.include?(File.extname(file_name))
    text = File.open(file_name, 'r'){ |file| file.read }
    if text.gsub!(find, replace)
      puts "rewriting #{file_name}..."
      File.open(file_name, 'w'){|file| file.write(text)}
    end
  end
end

namespace :source do

  desc "Replace all tabs in source code files with two spaces"
  task :detab do
    find_and_replace_in_source_files("\t", "  ")
  end

  desc "Remove trailing whitespace on the ends of lines"
  task :detrail do
    find_and_replace_in_source_files(/ +$/, '')
  end

  desc "Replace all instances of {pattern} with {result}"
  task :gsub, :pattern, :result do |t, args|
    find_and_replace_in_source_files(Regexp.new(args[:pattern] || ENV['PATTERN']), args[:result] || ENV['RESULT'])
  end

end

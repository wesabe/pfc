require 'open3'
require 'readline'
require 'cgi'


desc "Validate the source files."
task :validate => %w[validate:javascript]

module WesabeValidation
  class ScriptError
    include Comparable

    attr_accessor :message, :lineno, :file

    def initialize(file, lineno, message)
      self.file, self.lineno, self.message = file, lineno, message
    end

    def lineno=(lineno)
      @lineno = lineno.to_i
    end

    def file=(file)
      @file = File.expand_path(file)
    end

    def each_context_line
      first = [lineno-2, 1].max
      last  = [first+4, lines.size].min

      (first..last).each do |ln|
        yield ln, lines[ln-1]
      end
    end

    def lines
      @lines ||= content.to_a
    end

    def content
      @content ||= File.read(file)
    end

    def <=>(other)
      self.lineno <=> other.lineno
    end

    def error?
      # if lint says it's an error, then it's an error
      return true if message =~ /^lint error/

      # look for warnings that should be treated as errors

      # IE chokes on extra commas in Array and Object initializers
      return true if message =~ /(extra|trailing) comma/

      # didn't see anything errorish
      return false
    end
  end
end

def present_script_errors(errors)
  errors_by_file = begin
    result = Hash.new {|hash, key| hash[key] = []}
    errors.each {|error| result[error.file] << error}
    result.each {|_,v| v.sort!}
  end

  errors_by_file.each do |file, errors|
    puts
    puts "\e[1;36m#{File.basename(file)}\e[0;36m in #{File.dirname(file)}\e[0m"
    puts

    loop do
      break if errors.empty?

      errors.each_with_index do |error, i|
        puts "#{i+1}. \e[0;31m#{error.message}\e[0m"

        error.each_context_line do |lineno,line|
          print "\e[1m" if lineno == error.lineno
          puts "   #{lineno}\t#{line}"
          print "\e[0m" if lineno == error.lineno
        end

        puts
      end

      break if RAILS_ENV == 'test'
      index = Readline.readline("go to (1..#{errors.size})> ").to_i
      break if index.zero?
      if (1..errors.size).include?(index)
        error = errors.delete_at(index-1)
        `open "txmt://open?url=#{CGI.escape("file://#{error.file}")}&line=#{error.lineno}"`
      end
    end
  end
end

class WesabeValidation::JSLIgnoreManager
  IGNORE_FILE_NAME = '.jslignore'

  def ignored_files
    @ignored_files ||= {}
  end

  def ignore?(file)
    ensure_ignore_files_are_loaded_for(file)
    return ignored_files.include?(File.expand_path(file))
  end

  def ensure_ignore_files_are_loaded_for(file)
    file = File.expand_path(file)
    return unless File.exist?(file)

    if File.file?(file)
      ensure_ignore_files_are_loaded_for(File.dirname(file))
    elsif File.directory?(file)
      load_ignore_file_for_directory(file)
      parent = File.expand_path(File.join(file, '..'))
      ensure_ignore_files_are_loaded_for(parent) if file != parent # not root?
    end
  end

  def load_ignore_file_for_directory(dir)
    ignore_file = File.join(dir, IGNORE_FILE_NAME)
    if File.exist?(ignore_file)
      File.open(ignore_file) do |file|
        until file.eof?
          pattern = File.join(dir, file.gets.chomp)
          Dir[pattern].each do |file_to_ignore|
            ignored_files[file_to_ignore] = true
          end
        end
      end
    end
  end
end

namespace :validate do
  task :javascript do
    has_errors = false
    ignore_manager = WesabeValidation::JSLIgnoreManager.new

    Dir['public/javascripts/**/*.js'].each do |file|
      next if ignore_manager.ignore?(file)

      out = `jsl -process "#{file}"`
      if [1, 3].include?($?.exitstatus) # javascript warnings and errors
        base = Dir.pwd
        messages = out.scan(%r{^(.*#{Regexp.escape(file)})\((\d+)\): (.*)$\s*(.*)$})
        errors = messages.inject([]) do |list, message|
          se = WesabeValidation::ScriptError.new(file, message[1], message[2])
          list << se if se.error?
          list
        end

        has_errors ||= (not errors.empty?)
        present_script_errors(errors)
      end
    end

    exit(1) if has_errors && RAILS_ENV == 'test'
  end
end

class Snapshot < Thor
  desc 'import (PATH|HOST)', 'import Wesabe snapshot from a file or from a host (requires email/password)'
  method_options %w(quiet -q)    => false
  method_options %w(email -u)    => :string
  method_options %w(password -p) => :string
  def import(path_or_host)
    load_env

    if File.exist?(path_or_host)
      user = Importer::Wesabe.import(path_or_host, options.merge(:verbose => !options[:quiet]))
    else
      host = path_or_host
      host = 'www.wesabe.com' if host == 'wesabe.com'

      begin
        Socket.gethostbyname(host)
        user = RemoteSnapshot.import!(host, options[:email], options[:password], options)
      rescue SocketError
        abort "No file or host named #{path_or_host} could be found!"
      rescue ArgumentError => e
        $stderr.puts("#{File.basename($0)}: error: #{e}")
        help(:import)
      end
    end

    puts "You can now log in as #{user.email} with this Wesabe installation." if user unless options[:quiet]
  end

  desc 'export EMAIL PATH', 'export a Wesabe snapshot for the user with the given email to the given path'
  def export(email, path)
    load_env

    user = User.find_by_email(email)
    abort "No user found for #{email}" if user.nil?

    user.snapshot.destroy if user.snapshot
    snapshot = ::Snapshot.create!(:user => user)

    puts "building snapshot..."
    snapshot.build

    puts "$ cp #{snapshot.archive} #{path}"
    FileUtils.cp snapshot.archive, path
  end

  no_tasks do
    def load_env
      require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')
    end
  end
end
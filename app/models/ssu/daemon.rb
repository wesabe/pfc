require 'daemon_controller'
require 'active_support/json'

module SSU
  class Daemon
    attr_reader :profile

    class Error < RuntimeError; end

    def initialize(profile)
      @profile = profile
    end

    def start
      profile.make
      return if controller.running?
      profile.clean
      controller.start
    end

    def stop
      controller.stop
    end

    def running?
      controller.running?
    end

    def request(action, body=nil)
      response = connection.request(action, body)
      case response['status']
      when 'ok'
        return response[action]
      when 'error'
        raise Error, response['error']
      else
        raise Error, "invalid response from SSU: #{response.inspect}"
      end
    end

    private

    def controller
      ENV['DISPLAY'] = ':0'
      # do not restart for updates
      ENV['NO_EM_RESTART'] = '1'
      # I have no idea why this fixes the Segmentation fault,
      # but I guess xulrunner requires HOME to be set
      ENV['HOME'] ||= Dir.pwd

      @controller ||= DaemonController.new(
        :identifier       => "Server-Side Uploader (#{profile.path})",
        :start_command    => xulrunner_command,
        :ping_command     => lambda { host && port && connection },
        :pid_file         => profile.pid_path.to_s,
        :log_file         => profile.log_path.to_s,
        :daemonize_for_me => true
      )
    end

    def xulrunner_command
      args = "-profile #{profile.path} -no-remote"
      if !Rails.env.test? && RUBY_PLATFORM =~ /darwin/i
        "#{self.class.root}/script/server -- #{args}"
      else
        "xulrunner #{ini_path} #{args}"
      end
    end

    def connection
      @connection ||= Connection.new(host, port)
    end

    def ini_path
      self.class.root + 'application/application.ini'
    end

    def host
      '127.0.0.1'
    end

    def port
      config['port']
    end

    def pid
      config['pid']
    end

    def config
      return {} unless profile.config_path.exist?

      ActiveSupport::JSON.decode(profile.config_path.read)
    end

    def self.root
      @@root ||= Rails.root.join('vendor/ssu')
    end

    def self.root=(root)
      @@root = Pathname(root)
    end

    class Connection
      def initialize(host, port)
        @host, @port = host, port
        socket
      end

      def socket
        @socket = nil if @socket && @socket.closed?
        @socket ||= TCPSocket.new(@host, @port)
      end

      def request(action, body=nil)
        write(:action => action, :body => body)
        return read['response']
      end

      def read
        body = socket.readline
        begin
          return ActiveSupport::JSON.decode(body.chomp)
        rescue
          Rails.logger.warn { "SSU(#{$$}) Unable to parse JSON response: #{body}" }
          raise
        end
      end

      def write(body)
        socket.puts(ActiveSupport::JSON.encode(body))
      end

      def close
        @socket.close unless @socket.nil? || @socket.closed?
      end
    end
  end
end

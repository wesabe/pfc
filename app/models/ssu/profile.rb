require 'pathname'

module SSU
  class Profile
    attr_reader :path

    def initialize(path)
      @path = Pathname(path)
    end

    def make
      path.mkpath
    end

    def destroy
      path.rmtree
    end

    def config_path
      path.join('config')
    end

    def pid_path
      path.join('pid')
    end

    def log_path
      path.join('wuff_log.txt')
    end

    def statements_path
      path.join('statements')
    end

    def archive
      (path.children - [config_path, pid_path, log_path, statements_path]).each do |child|
        child.rmtree
      end
    end

    def clean
      path.children do |child|
        child.rmtree
      end
    end

    def self.with_name(name)
      new(Rails.root.join('tmp/profiles', name))
    end
  end
end

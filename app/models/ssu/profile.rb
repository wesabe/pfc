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

    def created_at
      path.ctime
    end

    def updated_at
      path.mtime
    end

    def id
      path.basename.to_s
    end

    def inspect
      "#<#{self.class}:#{path}>"
    end

    def to_s
      inspect
    end

    def ==(other)
      other.is_a?(self.class) && (self.path == other.path)
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
      new(root_path.join(name))
    end

    def self.all
      root_path.children.map {|path| new(path) }
    end

    def self.root_path
      Rails.root.join('tmp/profiles')
    end
  end
end

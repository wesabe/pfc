class Normalizer
  def self.alnum(replacement=nil)
    filter('[^\p{Alnum}]', 'i', replacement)
  end

  def self.filter(regexp, flags=nil, replacement=nil)
    if java?
      JRubyNormalizer.new(regexp, flags, replacement)
    elsif oniguruma?
      OnigurumaNormalizer.new(regexp, flags, replacement)
    elsif rubinius?
      RubiniusNormalizer.new(regexp, flags, replacement)
    else
      CompatibleNormalizer.new(regexp, flags, replacement)
    end
  end

  def self.java?
    if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
      require 'java'
      return true
    else
      return false
    end
  end

  def self.oniguruma?
    begin
      require 'oniguruma'
    rescue LoadError
    end

    def self.oniguruma?
      defined?(Oniguruma)
    end

    oniguruma?
  end

  def self.rubinius?
    defined?(RUBY_ENGINE) && RUBY_ENGINE == 'rbx'
  end

  class BaseNormalizer
    attr_reader :replacement, :regexp

    def initialize(regexp, replacement)
      @regexp      = regexp
      @replacement = replacement || ''
    end

    def normalize(string)
      downcase(replace(string)).to_s.
        squeeze(replacement).
        sub(/^(?:#{Regexp.escape(replacement)})+/, '').
        sub(/(?:#{Regexp.escape(replacement)})+$/, '').
        strip
    end

    def replace(string)
      string.gsub(regexp, replacement)
    end

    def downcase(string)
      string.downcase
    end

    def gsub(string, replacement)
      old_replacement, @replacement = @replacement, replacement
      return normalize(string)
    ensure
      @replacement = old_replacement
    end
  end

  class NativeOnigurumaNormalizer < BaseNormalizer
    def initialize(regexp, flags, replacement)
      super(Regexp.new(regexp, flags), replacement)
    end
  end

  class RubiniusNormalizer < NativeOnigurumaNormalizer
  end

  class JRubyNormalizer < NativeOnigurumaNormalizer
    def replace(string)
      java.lang.String.new(string.gsub(regexp, replacement))
    end

    def downcase(jstring)
      jstring.toLowerCase
    end
  end

  class OnigurumaNormalizer < BaseNormalizer
    def initialize(regexp, flags, replacement)
      super(Oniguruma::ORegexp.new(regexp, flags, 'utf8'), replacement)
    end

    def replace(string)
      regexp.gsub(string, replacement).mb_chars
    end

    def downcase(ostring)
      ostring.downcase
    end
  end

  class CompatibleNormalizer < BaseNormalizer
    def initialize(regexp, flags, replacement)
      super(Regexp.new(regexp.gsub(/\\p\{(\w+)\}/) { chars_in_class($1) }, flags), replacement)
    end

    def chars_in_class(klass)
      case klass.downcase
      when 'alnum'
        'a-zA-Z0-9'
      when 'alpha'
        'a-zA-Z'
      when 'ascii'
        '\x00-\x7F'
      when 'blank'
        ' \t'
      when 'cntrl'
        '\x00-\x1F\x7F'
      when 'digit'
        '0-9'
      when 'graph'
        '\x21-\x7E'
      when 'lower'
        'a-z'
      when 'print'
        '\x20-\x7E'
      when 'punct'
        '!"#$%&\'()*+,\\-./:;<=>?@[\\\\\\]^_`{|}~'
      when 'space'
        ' \t\r\n\v\f'
      when 'upper'
        'A-Z'
      when 'word'
        'A-Za-z0-9_'
      when 'xdigit'
        'A-Fa-f0-9'
      end
    end
  end
end
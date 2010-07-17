module OFX
  class Element
    attr_accessor :content

    def initialize(path, content = '')
      @path = path.dup
      @content = content
    end

    def name
      @path.last
    end

    def path
      @path.join('/')
    end

    def finalize!
      @content.strip!
    end

    def to_s
      "#{path}: #{content}"
    end

    # return true if the element's path includes the given element name
    def include?(element)
      @path.include?(element)
    end

    # return true if this element has content
    def content?
      !@content.blank?
    end
  end
end

class SimplePresenter < ActiveSupport::BasicObject
  attr_reader :presentable, :renderer
  alias_method :controller, :renderer

  def initialize(presentable, renderer)
    raise ArgumentError, "you have to present something" unless presentable
    raise ArgumentError, "you have to have a renderer" unless renderer
    @presentable = presentable
    @renderer = renderer
  end

  def inspect
    "#<#{self.class}: presentable is a #{@presentable.class}, renderer is a #{@renderer.class}>"
  end

  def method_missing(sym, *args, &block)
    return @presentable.__send__(sym, *args, &block)  if @presentable.respond_to?(sym)
    return @renderer.__send__(sym, *args, &block)     if @renderer.respond_to?(sym)
    raise NoMethodError, "#{self.class} could not find method `#{sym}`"
  end

  def self.namespaced_constant(name)
    return nil unless name
    name.split("::").inject(::Object) do |l,r|
      begin
        l.const_get(r)
      rescue
        return nil
      end
    end
  end

  def self.reveal(method_id)
    class_eval <<-EOS
      def #{method_id}(*args)
        Object.instance_method(:#{method_id}).bind(self).call(*args)
      end
    EOS
  end

  module Helper
    def present(presentable, presenter=nil)
      presenter ||= presenter_class_for(presentable)
      return presenter.new(presentable, self)
    end

    def presenter_class_for(presentable)
      presenter_options = ["SimplePresenter"]

      if presentable.is_a?(Array)
        presenter_options.unshift("ArrayPresenter")
        presenter_options.unshift("#{presentable.class}Presenter")
        classes = presentable.map{|n| n.class }.uniq
        presenter_options.unshift("#{classes.first}ArrayPresenter") if classes.size == 1
      else
        presenter_options.unshift("#{presentable.class}Presenter")
      end

      return presenter_options.map{|o| SimplePresenter.namespaced_constant(o) }.compact.first
    end
  end
end

[:methods, :class].each do |sym|
  SimplePresenter.reveal(sym)
end

require 'presenters/array_presenter'

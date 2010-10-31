class ArrayPresenter < SimplePresenter
  def as_json(options=nil)
    presentable.map {|object| object.as_json(options) }
  end

  def method_missing(sym, args = nil)
    return nil if presentable.empty?
    super(sym, args)
  end
end

class ArrayPresenter < SimplePresenter
  def method_missing(sym, args = nil)
    return nil if presentable.empty?
    super(sym, args)
  end
end

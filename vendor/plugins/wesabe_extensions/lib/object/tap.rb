class Object
  def tap
    yield self
    self
  end unless Object.new.respond_to?(:tap)
end

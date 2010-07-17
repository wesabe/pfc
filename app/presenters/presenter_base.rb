class PresenterBase
  cattr_accessor :view

  def view
    self.class.view
  end

  def presenter
    self
  end
end

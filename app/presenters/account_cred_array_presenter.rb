class AccountCredArrayPresenter < ArrayPresenter
  def as_json(options=nil)
    presentable.map {|cred| AccountCredPresenter.new(cred, renderer).as_json(options) }
  end
end

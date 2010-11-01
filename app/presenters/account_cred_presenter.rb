class AccountCredPresenter < SimplePresenter
  def as_json(options=nil)
    {:uri => credential_path(presentable),
     :accounts => accounts.map {|account| account_path(account) },
     :last_job => last_job && present(last_job).as_json(options)}
  end
end

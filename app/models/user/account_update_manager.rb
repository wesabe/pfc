class User::AccountUpdateManager
  attr_reader :user, :controller, :options

  def initialize(user, controller, options = {})
    @user = user
    @controller = controller
    @options = options
  end

  def login!
    user.account_creds.each do |ac|
      ac.enqueue_sync
    end if ssu_enabled?
  end

  def ssu_enabled?
    !controller ||
     controller.ssu_enabled?
  end

  def self.login!(user, controller, options={})
    new(user, controller, options).login!
  end
end

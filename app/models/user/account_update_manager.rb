class User::AccountUpdateManager
  attr_reader :user, :controller, :options

  def initialize(user, controller, options = {})
    @user = user
    @controller = controller
    @options = options
  end

  def login!
    return unless ssu_enabled?

    user.account_creds.each do |ac|
      last_job = ac.last_job
      ac.enqueue_sync if last_job.nil? || (last_job.updated_at < 3.hours.ago)
    end
  end

  def ssu_enabled?
    !controller ||
     controller.ssu_enabled?
  end

  def self.login!(user, controller, options={})
    new(user, controller, options).login!
  end
end

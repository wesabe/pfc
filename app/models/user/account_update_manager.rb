class User::AccountUpdateManager
  attr_reader :user, :controller, :options

  def initialize(user, controller, options = {})
    @user = user
    @controller = controller
    @options = options
  end

  def login!
    # start SSU jobs for any account updated more than six hours ago
    begin
      user.account_creds.each do |ac|
        if update?(ac)
          SsuJob.start(user, ac)
        elsif destroy?(ac)
          ac.destroy
        end
      end if ssu_enabled?
    rescue SsuError => e
      $stderr.puts e
    end
  end

  def update?(cred)
    options[:force] ||
    !cred.last_ssu_job ||                         # There is no previous job or
     cred.last_ssu_job.created_at < 6.hours.ago   # the previous job is earlier than 6 hours ago
  end

  def destroy?(cred)
    !cred.accounts.any? && cred.financial_inst.ssu_support?(user)
  end

  def ssu_enabled?
    !controller ||
     controller.ssu_enabled?
  end

  def self.login!(user, controller, options={})
    new(user, controller, options).login!
  end
end

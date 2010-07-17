# An exponentially increasing timeout for failed user logins.
#
# === Failed Login Policy
#
# The first three failed login attempts on a user's account are free. The fourth
# failed login attempt imposes a 15-second penalty, during which no login
# attempts for that user account can succeed. The fifth failed login attempt,
# whether during the penalty period or not, imposes a 30-second penalty. Further
# failed attempts double the penalty period length, up to 15 minutes.
#
# If a login attempt is successful, all these counters are zeroed and the
# account returns to normal. Otherwise, the counters are cleared only if 24
# hours pass without a failed login attempt.
#
# If an unauthenticated session is in a timeout period, the login page should
# mention this to prevent further unintentional failed logins.
#
# If an API request is sent during a penalty period with invalid credentials,
# a 403 Forbidden response should be sent.
#
#
# === Usage
#
#   @user = User.find_by_username(params[:username)
#   @throttle = Authentication::LoginThrottle.new(@user)
#   if @throttle.allow_login? && @user.valid_password?(params[:password)
#     @throttle.successful_login!
#     # authorize session, redirect to home page
#   else
#     @throttle.failed_login!
#     # redirect to login with explanation
#   end
#
class Authentication::LoginThrottle

  class UserThrottleError < StandardError
    attr_reader :retry_after

    def initialize(message, retry_after)
      @retry_after = retry_after
      super(message)
    end
  end

  INITIAL_TIMEOUT = 15.seconds
  MAXIMUM_TIMEOUT = 15.minutes
  FREE_LOGIN_ATTEMPTS = 5

  # Creates a new login throttle for +user+.
  def initialize(user)
    @user = user
    @number_of_bad_logins = get_bad_login_counter
  end

  # Returns +true+ if the user's current login attempt should be allowed,
  # +false+ if it should be denied.
  def allow_login?
    return (not is_throttled?)
  end

  # Registers a failed login attempt for the user.
  def failed_login!
    @number_of_bad_logins = increment_bad_login_counter
    throttle_user if should_throttle?
  end

  # Registers a successful login attempt for the user.
  def successful_login!
    unthrottle_user
    clear_bad_login_counter
  end

  def raise_throttle_error
    raise UserThrottleError.new("user #{@user.username} (#{@user.id}) is throttled", calculate_penalty)
  end

private

  def logger
    return ActiveRecord::Base.logger
  end

  def should_throttle?
    return @number_of_bad_logins >= FREE_LOGIN_ATTEMPTS
  end

  def throttle_user
    penalty = calculate_penalty
    logger.info("throttling user #{@user.id} for #{penalty} seconds")
    Rails.cache.write(throttle_key, penalty.from_now, :expire_in => penalty)
  end

  def unthrottle_user
    logger.info("unthrottling user #{@user.id}")
    Rails.cache.delete(throttle_key)
  end

  def calculate_penalty
    unfree_login_attempts = @number_of_bad_logins - FREE_LOGIN_ATTEMPTS - 1
    penalty = INITIAL_TIMEOUT * (2**unfree_login_attempts)
    return penalty > MAXIMUM_TIMEOUT ? MAXIMUM_TIMEOUT : penalty
  end

  def ensure_login_counter_exists
    Rails.cache.write(bad_logins_key, "0", :expires_in => 1.day, :raw => true) unless
      Rails.cache.exist?(bad_logins_key)
  end

  def clear_bad_login_counter
    Rails.cache.delete(bad_logins_key)
  end

  def get_bad_login_counter
    ensure_login_counter_exists
    return Rails.cache.read(bad_logins_key, :raw => true).to_i
  end

  def increment_bad_login_counter
    ensure_login_counter_exists
    return Rails.cache.increment(bad_logins_key)
  end

  def is_throttled?
    return Rails.cache.exist?(throttle_key)
  end

  def throttle_key
    return "throttle:#{@user.id}"
  end

  def bad_logins_key
    return "badlogins:#{@user.id}"
  end
end

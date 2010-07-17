module Authentication::ControllerMethods
  TIMEOUT = 60.minutes

  def self.included(receiver)
    receiver.send(:helper_method, :current_user)
    receiver.send(:hide_action, :current_user)
    receiver.send(:helper_method, :current_user_id)
    receiver.send(:hide_action, :current_user_id)
  end

  class Error
    UNAUTHORIZED = "You are not authorized to view the page you requested"
    TIMEOUT = "We hadn't heard from you in a while, so we logged you out for security reasons. Please log in again."
  end

  def current_user
    if session[:user].blank? || time_left <= 0
      return nil
    else
      @current_user = User.find(session[:user]) unless @current_user && @current_user.id == session[:user]
      @current_user.account_key = session[:account_key]
      @current_user.timezone_offset = session[:timezone_offset]
      User.current = @current_user
      return @current_user
    end
  end

protected

  # return just the current user_id
  def current_user_id
    session[:user]
  end

  def clear_current_user(options = { :clear_cookies => true, :clear_intended_uri => true })
    logger.info("*** clearing current user; session: #{session.inspect}")
    intended_uri = session[:intended_uri]
    reset_session # die, freak
    session[:intended_uri] = intended_uri unless options[:clear_intended_uri]
    User.current = @current_user = nil
  end

  def set_current_user(user, options = { :update_login_timestamp => false })
    if session
      # store the user in the session
      session[:user] = user.id
      session[:account_key] = user.account_key
      session[:timezone_offset] = -params[:tz_offset].to_i if params[:tz_offset] # need to negate because JS's Date#getTimezoneOffset() returns UTC - local time (in min)
      reset_session_timeout(true)
    end

    User.current = @current_user = user

    if options[:update_login_timestamp]
      user.last_web_login = Time.now
      user.save(:validate => false)
    end

    # set a wesabe_member cookie so that when they come back to the accounts page,
    # we show the login page instead of the promo page
    cookies[:wesabe_member] = { :value => "1", :expires => 10.years.from_now }
  end

  # check if a user is logged in; if not, save the controller and action they
  # were trying to reach an redirect to the login page
  def check_authentication
    # try to authenticate with basic auth first
    begin
      if user = authenticate_with_http_basic { |user, pass| if user && pass ; User.authenticate(user, pass) || :bad_password ; else nil ; end }
        # REVIEW: This creates a session each time someone requests a page using basic auth. We should revisit this.
        # REVIEW: I hate that we're doing something differently in development
        if user == :bad_password && ::Rails.production?
          render :text => "Wrong username or password", :status => :unauthorized
          return false
        elsif user != :bad_password
          set_current_user(user)
          return true
        end
      end
    rescue Authentication::LoginThrottle::UserThrottleError => e
      response.headers['Retry-After'] = e.retry_after
      render(
        :text => 'Too many failed login attempts. This account is temporarily disabled. Please try again later.',
        :status => 503,
        :layout => false
      )
      return false
    end

    # save intended_uri, except for login pages, and xhr or .xml requests
    if request.get? && !request.xhr? && request.fullpath !~ /(\/user\/(login|logout|timeout|ping))|(\.xml)/
      logger.debug("setting the intended URI: #{request.fullpath}")
      session[:intended_uri] = request.fullpath
    end

    if current_user
      begin
        logger.debug("Clearing out the intended URI since we're already going there")
        session[:intended_uri] = nil

        reset_session_timeout

        return true
      rescue => e
        logger.error("Authentication Exception: #{e}")
        return false
      end
    end
    logger.info("*** [check_authentication] no current user; current_user: #{current_user.inspect}")

    # make sure this isn't a stale session
    if session[:expires_at] && time_left <= 0
      redirect_to login_url
      return false
    end

    respond_to do |format|
      format.html do
        if ( accounts_url == url_for(params) && !cookies[:wesabe_member] )
          redirect_to(login_url)
        elsif cookies[:wesabe_member]
          redirect_to(login_url)
        else
          redirect_to(signup_url)
        end
      end
      format.json { render_not_authorized }
      format.js   { render_not_authorized }
      format.xml  { render_not_authorized }
      format.xls  { render_not_authorized }
      format.csv  { render_not_authorized }
      format.qif  { render_not_authorized }
      format.ofx  { render_not_authorized }
      format.ofx2 { render_not_authorized }
    end

    return false
  end

  def render_not_authorized
    if request.xhr?
      redirect_to(login_url)
    else
      headers["WWW-Authenticate"] = %(Basic realm="RESTRICTED")
      render :nothing => true, :status => 401
    end
  end

  def time_left
    ((session[:expires_at] || Time.now) - Time.now).to_i
  end

  # reset session timeout. If force = true, reset it even if the session has
  # expired
  def reset_session_timeout(force = false)
    unless session.blank? || (time_left < 0 && !force)
      session[:expires_at] = TIMEOUT.from_now
      logger.info("*** reset_session_timeout for #{session[:id]}; session[:expires_at]: #{session[:expires_at]}")
    end
  end
end

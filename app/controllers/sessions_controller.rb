# REVIEW: Move this to resource routing.
class SessionsController < ApplicationController
  layout "public"
  skip_before_filter :reset_session_timeout

  def new
    # if user is already logged in, just redirect to index
    redirect_to(intended_uri || root_url) if current_user
  end

  # REVIEW: Refactor this into a series of private methods instead of a 40-line monster.
  def create
    # email is the new username
    username_or_email = params[:email] || params[:username]

    if current_user
      return redirect_to(intended_uri || root_url)
    end

    begin
      unless user = User.authenticate(username_or_email, params[:password])
        logger.debug("email/username or password incorrect for: #{username_or_email}")
        flash.now[:error] = {:title => "Username/Email or Password incorrect",
                             :message => "Re-enter your email and password and try again." }
        return render(:action => "new")
      end
    rescue Authentication::LoginThrottle::UserThrottleError
      logger.debug("throttled login attempt for: #{username_or_email}")
      flash.now[:error] = {:title => "Too many failed login attempts",
                           :message => "This account is temporarily disabled. Please try again later."}
      return render(:action => "new")
    end

    logger.debug("logging in: " + username_or_email)

    # reset session to avoid session fixation attack
    reset_session

    # sign the user in
    set_current_user(user, :update_login_timestamp => true)
    current_user.after_login(self)

    # redirect to intended action if it exists
    if intended_uri.present? && intended_uri !~ %r{(/user/(login|logout|timeout|signup))|financial_insts}
      logger.debug("redirecting to intended uri: #{intended_uri}")
      return redirect_to(intended_uri)
    else
      return redirect_to(root_url)
    end
  end

  # Redirect the user's browser to the timeout page if they haven't been active
  # during the timeout period
  def show
    return redirect_to(root_url) if !request.xhr?

    if time_left > 0
      render :nothing => true
    else
      logger.info("*** session timed out for #{session[:session_id]}; time_left: #{time_left}; session[:expires_at]: #{session[:expires_at]}")
      render :update do |page|
        page.redirect_to login_url
      end
    end
  end

  # REVIEW: Move this to #update.
  # Reset the session timeout
  # called from javascript when users are typing in a form
  def reset_timeout
    reset_session_timeout
    render :nothing => true
  end

  def destroy
    logger.info("*** [SessionController#delete] called for #{session[:session_id]}; time_left: #{time_left}; session[:expires_at]: #{session[:expires_at]}; params: #{params.inspect}; session: #{session.inspect}")
    # REVIEW: Encapsulate all this logic in something.
    case params[:reason]
    when :timeout
      logger.debug("*** [SessionController#delete] session timeout")
      # only show timeout error if they timed out relatively recently
      if session[:expires_at] && session[:expires_at] < 12.hours.ago
        flash[:error] = Error::TIMEOUT
      end
    else
      clear_current_user
      return redirect_to(login_url(:signed_out => true))
    end

    clear_current_user(:clear_intended_uri => false)
    return redirect_to(login_url)
  end

private

  def intended_uri
    # If they were referred to this page by another person
    # Don't use the referer if an intended_uri is already set or if the user just logged out manually (in
    # which case the referer is the page they logged out from)
    @intended_uri ||= begin
      uri = params[:intended_uri] || session[:intended_uri]

      if !params[:signed_out] && !uri && referer = internal_referer
        # and it's not this controller or a static page
        if !["page", "sessions"].include?(referer[:controller])
          uri = url_for(referer)
          logger.debug "setting intended URI to #{uri}"
        end
      end

      uri
    end
  end

end

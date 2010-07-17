class ActionController::Base
  @@default_redirection = '/'
  cattr_accessor :default_redirection
  
  def redirect_to_with_redirect_protection(*options)
    begin
      redirect_to_without_redirect_protection(*options)
    rescue ::ActionController::RedirectBackError
      # A RedirectBackError means this is a redirect_to(:back) call, so rescue
      # and redirect to the second parameter (ie, :back, "/path") if there is one
      # or the application-wide default otherwise.
      redirect_to_without_redirect_protection(options[1] || @@default_redirection)
    end
  end
  alias :redirect_to_without_redirect_protection :redirect_to
  alias :redirect_to :redirect_to_with_redirect_protection
end
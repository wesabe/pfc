class PageController < ApplicationController
  before_filter :check_authentication, :only => [:knownissues]
  before_filter :only_allow_html

  def about
    redirect_to :action => "what"
  end

  def help
    redirect_to help_url('user-manual/uploading')
  end

  # REVIEW: See comment in app/views/page/_help_sidebar.html.erb for an explanation.
  def help_dont_panic
    redirect_to help_url('user-manual/troubleshooting')
  end

  def founders
    redirect_to :action => "execs", :status => :moved_permanently
  end
end

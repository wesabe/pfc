require 'base64'

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :clear_current_user_global

  include Stylesheeter
  include Authentication::ControllerMethods

  helper :all

  before_filter :unmunge_excel_accept_headers,
                :decode_tag_name,
                :reset_session_timeout,
                :handle_x_frame_header
  after_filter  :add_xss_blocker_to_js

  def ssu_enabled?
    !File.exist?("/var/wesabe/ssu-down")
  end
  helper_method :ssu_enabled?
  hide_action :ssu_enabled?

protected

  def clear_current_user_global
    User.current = nil
  end

  # remove the X-Frame-Options header if that feature is disabled
  def handle_x_frame_header
    response.headers["X-Frame-Options"] = "Sameorigin"
  end

  def decode_tag_names
    # turn strings like "foo/bar-slash-baz" into arrays like ["foo", "bar/baz"]
    # this works around an apache bug that unescapes %2F when proxying, even when explicitly told not to
    params[:tags] = params[:tags].split("/").map{|n| Tag.decode_name!(n) } if params[:tags]
  end

  def decode_tag_name
    Tag.decode_name!(params[:tag]) if params[:tag]
  end

  # remove the shitty Accept-munging that Excel+IE does on older machines
  def unmunge_excel_accept_headers
    request.headers["HTTP_ACCEPT"].gsub!(/application\/vnd.ms-excel(,)*/, "") if request.headers["HTTP_ACCEPT"]
  end

  include ActionView::Helpers::CaptureHelper
  include ApplicationHelper

  def user_home_path
    dashboard_path
  end

  #--------------------------------------------------------------------------
  # Authorization and Authentication


  # used in before filters where only admins are allowed to view the page
  def check_for_role(role)
    role_method = role.to_s + '?'
    return true if current_user && current_user.respond_to?(role_method) && current_user.send(role_method)

    flash[:notice] = Error::UNAUTHORIZED
    request.env["HTTP_REFERER"] ? (redirect_to :back) : (redirect_to root_url)
    return false
  end

  # used in before filters where only admins are allowed to view the page
  def check_for_admin
    check_for_role(:admin)
  end

  def only_allow_html
    render :nothing => true, :status => 406 if params[:format] && params[:format] != "html"
  end

  # prevents <script> tags on other web sites from accessing
  # potentially sensitive information.
  # see http://dev.rubyonrails.org/changeset/6556
  def add_xss_blocker_to_js
    case response.content_type
    when %r{^text/javascript}, %r{^application/json}
      response.body = "/*-secure- #{response.body} */"
    end
  end
end
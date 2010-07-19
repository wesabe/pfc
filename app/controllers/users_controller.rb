class UsersController < ApplicationController
  before_filter :check_authentication, :except => [:new, :create, :signup, :show, :userbar]
  before_filter :only_allow_html, :except => [:show]

  # this is no longer used...replaced by accounts/index
  def index
    redirect_to :controller => 'accounts', :action => 'index'
  end

  def ping
    render :nothing => true, :status => :ok
  end

  def destroy
    # require a password to delete the user
    unless current_user.valid_password?(params[:password])
      flash[:error] = "Password incorrect"
      return render(:action => "delete_membership")
    end

    current_user.destroy
    clear_current_user

    return redirect_to(root_url)
  end

  def show
    unless params[:id] || current_user
      return redirect_to(login_url)
    end

    @user = params[:id] ? User.find_with_normalized_name(params[:id]) : current_user
    # if no user, try to authenticate
    # REVIEW: this is horrendously ugly. The authentication system is in dire need of refactoring.
    unless @user
      if params[:format] && params[:format] != "html"
        check_authentication
        unless @user = current_user
          erase_results
          render_not_authorized
          return
        end
      else
        raise ActiveRecord::RecordNotFound
      end
    end

    respond_to do |format|
      format.html do # show.rhtml
        @profile = @user.profile
      end
      format.xml  { render :layout => false } # show.xml.builder
    end
  end

  def userbar
    if params[:homepage]
      render :partial => 'homepage_userbar'
    else
      render :partial => 'userbar'
    end
  end

  # render new user form
  def new
    return redirect_to(root_url) if current_user # shouldn't be here if already logged in
    @user = User.new
    render :layout => "public"
  end

  # create a user
  def create
    @user = User.new(params[:user])
    if @user.save
      @user = @user.authenticated_by(params[:user][:password])
      set_current_user(@user, :update_login_timestamp => true) # sign the user in
      return redirect_to(dashboard_url)
    end

    render :action => "new", :layout => "public"
  end

  def edit_filter_tags
    if request.post?
      if params[:add_filter_tag]
        # wrap in quotes if it has spaces
        if params[:add_filter_tag] =~ /\s/
          params[:add_filter_tag] = "\"#{params[:add_filter_tag]}\""
        end
        current_user.apply_filter_tags(Tag.array_to_string(current_user.filter_tags) + ' ' + params[:add_filter_tag])
        @filter_tags = current_user.filter_tags.map(&:display_name).join(' ')
        return
      else
        current_user.apply_filter_tags(params[:filter_tags] || [])
      end
    end
    respond_to do |format|
      format.js { render :json => current_user.filter_tags.map(&:display_name) }
      format.html { redirect_to :back }
    end
  end

  def associate_transfers
    count = current_user.associate_transfers
    current_user.preferences.has_found_transfers = true
    respond_to do |format|
      format.html {flash[:num_transfers] = count/2; redirect_to :back}
      format.js do
        text = "1 new transfer found" if count/2 == 1
        text ||= "#{count/2} new transfers found"
        render :json => {:num_transfers => text}
      end
    end
  end

  # display the change password page
  # FIXME: this should probably be in a separate controller and broken up into edit/update
  def edit_password
    @password_change = password_change
    render :template => "users/change_password"
  end

  def update_password
    if password_change.valid?
      current_user.change_password!(password_change.password)
      set_current_user(current_user)
      notify_success "Change Password", "Your password has been changed."
      password_change.clear
    end

    render :template => "users/change_password"
  end

  def download_data
    render :template => "users/download_data"
  end

  def delete_membership
    render :template => "users/delete_membership"
  end

  # this action is called right after a user logs in after their password has been reset. They are forced
  # to change their password
  def reset_password
    @password_reset = PasswordResetForm.new(params[:password_reset])
    user = current_user

    if request.post? && @password_reset.valid?
      user.change_password!(@password_reset.password)
      set_current_user(user)
      return redirect_to(:controller => 'accounts', :action => 'index')
    end
  end

  def toggle_preference
    case params[:preference]
    when 'show_one_time', 'show_notes', 'show_attachments'
      current_user.preferences.send(params[:preference]+"=", !current_user.preferences.send(params[:preference]))
      return render(:text => current_user.preferences.send(params[:preference]).to_s)
    end
  end

private
  include ActionView::Helpers::NumberHelper

  def password_change
    @user = current_user
    @password_change ||= PasswordChangeForm.new(current_user, params[:password_change])
  end
end

# form for changing password in user/edit/account
class PasswordChangeForm < ActiveForm
  attr_accessor :user, :current_password, :password, :password_confirmation

  def initialize(user, params={})
    self.user = user
    super(params)
  end

  def validate
    if current_password.blank?
      errors.add(:current_password, "Please enter your current password.")
    elsif not user.valid_password?(current_password)
      errors.add(:current_password, "Password is incorrect.")
    end

    if password.blank?
      errors.add(:password, "Please enter a new password.")
    elsif password != password_confirmation
      errors.add(:password_confirmation, "The password and confirmation do not match.")
    end
  end

  def clear
    self.current_password      = nil
    self.password              = nil
    self.password_confirmation = nil
  end
end
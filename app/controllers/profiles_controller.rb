class ProfilesController < ApplicationController
  before_filter :check_authentication

  def show
    @user    = current_user
    @profile = @user.profile
  end

  def edit
    @user = current_user

    @user.profile = UserProfile.new unless @user.profile
    @profile = @user.profile

    @email_change = EmailChangeForm.new(params[:email_change] || {:email => @user.email, :password => ''})
  end

  def update
    @user = current_user

    @user.profile = UserProfile.new unless @user.profile
    @profile = @user.profile

    if params[:email_change]
      @email_change = EmailChangeForm.new(params[:email_change])

      if @email_change.email != @user.email
        # make sure email address isn't already taken
        if User.find(:first, :conditions => ["email = ? and id != ?", @email_change.email, @user.id])
          @email_change.errors.add(:email, "That email address is already taken.")
          return render(:action => "edit")
        end
        # require password to change email
        if !@user.valid_password?(@email_change.password)
          @email_change.errors.add(:password, 'The password is incorrect.')
          return render(:action => "edit")
        end

        params[:user][:email] = @email_change.email
      else
        # don't allow email to be set via params. could use attr_protected in User, but I'm worried I might break something
        params[:user].delete(:email)
      end
      @email_change.password = "" # make sure we don't keep the password around
    end

    image_field = params[:photo] && params[:photo]['photo']
    if image_field.respond_to?('original_filename') && !image_field.original_filename.blank?
      @user.image_file = image_field
    end

    if @user.update_attributes(params[:user]) && @profile.update_attributes(params[:profile])
      set_current_user(@user) # update current user
      notify_success "Your profile has been updated."
      redirect_to edit_profile_url
      return
    elsif not @user.valid?
      notify_error(@user.errors.full_messages.first)
    elsif not @profile.valid?
      notify_error(@profile.errors.full_messages.first)
    end

    render :action => "edit"
  end

private

  def notify_success(title, message=nil)
    title, message = "Profile Updated", title if message.nil?
    super(title, message)
  end

  def notify_error(title, message=nil)
    title, message = "Error Updating Profile", title if message.nil?
    super(title, message)
  end

  # form for changing email address in user/edit/profile
  class EmailChangeForm < ActiveForm
    attr_accessor :password, :email
  end
end
class UserPreferencesController < ApplicationController
  before_filter :check_authentication

  # GET /preferences.(xml|json)
  def index
    @preferences = current_user.preferences.preferences || {}
    # remove any prefs not visible to the user
    @preferences.reject! {|k,v| UserPreferences::SYSTEM_PREFS.include?(k)}

    respond_to do |format|
      format.json  { render :json => @preferences.to_json }
      format.xml  { render :xml => @preferences.to_xml(:root => 'preferences') }
    end
  end

  # GET /preferences/:preference.(xml|json)
  def show
    @preferences = current_user.preferences.preferences || {}
    @preferences = {params[:preference].to_sym => @preferences[params[:preference]] || @preferences[params[:preference].to_sym]}
    @preferences.reject! {|k,v| UserPreferences::SYSTEM_PREFS.include?(k) || v.nil?} # strip non-user prefs or missing prefs
    raise ActiveRecord::RecordNotFound unless @preferences.any?

    respond_to do |format|
      format.json  { render :json => @preferences.to_json }
      format.xml  { render :xml => @preferences.to_xml(:root => 'preferences') }
    end
  end

  # PUT /preferences
  # update user preferences. Takes any parameters (other than action, controller, context, and format) and
  # adds/updates those parameters in the current user's preferences
  def update
    @preferences = current_user.preferences.update_preferences(params)
    render :nothing => true, :status => :ok
  end

  # PUT /preferences/toggle/:preference
  # toggle the given preference true/false
  def toggle
    state = current_user.preferences.toggle(params[:preference])
    render :text => state, :status => :ok
  end

  # DELETE /preferences
  # clear the user's preferences
  # REVIEW: this is primarily for development purposes; I don't see any reason to keep this in production
  def destroy
    current_user.preferences.destroy
    render :nothing => true, :status => :ok
  end
end

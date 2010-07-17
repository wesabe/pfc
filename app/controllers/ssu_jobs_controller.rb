class SsuJobsController < ApplicationController
  before_filter :get_ssu_job, :only => :update
  before_filter :check_authentication, :except => [:update]
  before_filter :find_account_cred, :except => [:update]

  def update
    @job.update_status(params)
    render :json => @job.presenter.to_internal_json
  end

  def create
    if job = SsuJob.start(current_user, @account_cred)
      @job = job.presenter
      respond_to do |format|
        format.html { redirect_to root_url }
        format.xml  { render :action => 'show', :layout => false } # show.xml.builder
        format.js   { render :action => 'show', :layout => false } # show.js.erb
      end
    elsif job = @account_cred.last_ssu_job
      @job = job.presenter
      action = if job.denied? then 'create_error_denied' else 'create_error_pending' end
      respond_to do |format|
        # format.html # 405 Method Not Allowed
        format.xml  { render :action => action, :status => 400 }
        format.js   { render :action => action, :status => 400 }
      end
    end
  end

  def index
    @jobs = @account_cred.all_ssu_jobs.map {|job| job.presenter}
    respond_to do |format|
      format.xml { render :action => 'index' } # index.xml.builder
      format.js  { render :action => 'index' } # index.js.erb
    end
  end

  def show
    if job = @account_cred.all_ssu_jobs.find_by_job_guid(params[:id])
      @job = job.presenter
      respond_to do |format|
        # format.html # 405 Method Not Allowed
        format.xml { render :action => 'show', :layout => false } # show.xml.builder
        format.js  { render :action => 'show', :layout => false } # show.js.erb
      end
    else
      render :text => "Cannot find job with id=#{params[:id]}", :status => 404
    end
  end

protected

  def find_account_cred
    render :text => "Cannot find credential with id=#{params[:credential_id]}", :status => 404 unless
      @account_cred = current_user.account_creds.find_by_id(params[:credential_id]) ||
                      current_user.account_creds.find_by_cred_guid(params[:credential_id])
  end

  def get_ssu_job
    render :text => "No such job", :status => 404 unless
      @job = SsuJob.find_by_job_guid(params[:id])
  end

end

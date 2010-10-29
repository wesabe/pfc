class SsuJobsController < ApplicationController
  before_filter :check_authentication, :except => [:update]

  def update
    @job.update_status(params)
    render :json => @job.presenter.to_internal_json
  end

  def create
    if job = account_cred.enqueue_sync
      @job = job.presenter
      respond_to do |format|
        format.json { render :json => @job.to_json, :status => :created, :location => credential_job_url(account_cred, job) }
      end
    else
      render :text => 'unable to start job', :status => :bad_gateway
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
    if job = account_cred.jobs.find_by_job_guid(params[:id])
      @job = job.presenter
      respond_to do |format|
        format.json { render :json => @job.to_json }
      end
    else
      render :nothing => true, :status => :not_found
    end
  end

protected

  def account_cred
    @account_cred ||= current_user.account_creds.find_by_id(params[:credential_id])
  end
end

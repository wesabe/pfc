class SsuJobsController < ApplicationController
  before_filter :check_authentication, :except => [:update]

  def create
    if @job = account_cred.enqueue_sync
      respond_to do |format|
        format.json { render :json => present(@job), :status => :created, :location => credential_job_url(account_cred, @job) }
      end
    else
      render :text => 'unable to start job', :status => :bad_gateway
    end
  end

  def show
    if @job = account_cred.jobs.find_by_job_guid(params[:id])
      respond_to do |format|
        format.json { render :json => present(@job) }
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

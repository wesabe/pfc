class AccountCredsController < ApplicationController
  before_filter :check_authentication
  before_filter :require_account_cred, :only => [:destroy, :show]
  before_filter :check_ssu_enabled

  def new
    return unless @financial_inst = financial_inst

    if (not ssu_enabled?) || ((not financial_inst.ssu_support?(current_user)) && (params[:force] != 'true'))
      redirect_to(new_upload_path)
    end
  end

  def index
    @account_creds = current_user.account_creds

    respond_to do |format|
      format.json { render :json => @account_creds }
    end
  end

  def create
    @fi = FinancialInst.find_by_wesabe_id(params[:fid])
    return redirect_to(user_home_path) unless @fi
    @account_cred = AccountCred.create(
      :cred_guid => params[:credguid],
      :cred_key => params[:credkey],
      :user => current_user,
      :financial_inst => @fi)
    @job = SsuJob.start(current_user, @account_cred) if @account_cred.valid?
    if @job && @job.valid?
      logger.info "SSU START job guid #{@job.job_guid}"
    elsif @job
      logger.error "SSU ERROR #{@account_cred.error_sentence} #{@job.error_sentence}"
    else
      logger.error "SSU ERROR cred is #{'in' unless @account_cred.valid?}valid and job was not created"
    end
    render :nothing => true
  end

  def destroy
    if @account_cred
      @account_cred.destroy
      if params[:back] && request.env["HTTP_REFERER"]
        redirect_to :back
      elsif params[:intended_uri] && params[:intended_uri] =~ %r{^/}
        redirect_to params[:intended_uri]
      else
        redirect_to ssu_new_upload_path(:fi => @account_cred.financial_inst, :second_try => params[:second_try])
      end
    else
      redirect_to user_home_path
    end
  end

  def start
    @account_creds = current_user.account_creds.find_by_financial_inst_id(params[:id])
    @account_creds.each{ |ac| SsuJob.start(current_user, ac) }
    redirect_to user_home_path
  end

  def show
    respond_to do |format|
      format.json { render :json => @account_cred }
    end
  end

protected

  def check_ssu_enabled
    render :text => "The automatic uploader is disabled.", :status => 503 unless ssu_enabled?
  end

  def require_account_cred
    @account_cred = AccountCred.find_by_cred_guid(params[:id])
    redirect_to home_path unless @account_cred && @account_cred.destroyable_by?(current_user)
  end

  def financial_inst
    @financial_inst ||= begin
      FinancialInst.find_for_user(params[:fi], current_user).tap do |fi|
        redirect_to new_upload_path if fi.nil?
      end
    end
  end
end
class AccountCredsController < ApplicationController
  before_filter :check_authentication
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
      format.json { render :json => present(@account_creds.to_a) }
    end
  end

  def create
    @account_cred = AccountCred.create(
      :creds          => creds,
      :user           => current_user,
      :financial_inst => financial_inst
    )

    if @account_cred.valid?
      render :nothing => true, :status => :created, :location => credential_url(@account_cred)
    else
      render :text => @account_cred.error_sentence, :status => :bad_request
    end
  end

  def update
    if account_cred.nil?
      render :nothing => true, :status => :not_found
    else
      begin
        account_cred.creds = account_cred.creds.merge(creds)
        account_cred.save!
        render :json => present(account_cred)
      rescue
        render :nothing => true, :status => :bad_request
      end
    end
  end

  def destroy
    if account_cred
      account_cred.destroy
    else
      render :nothing => true, :status => :not_found
    end
  end

  def show
    respond_to do |format|
      format.json { render :json => account_cred }
    end
  end

protected

  def check_ssu_enabled
    render :text => "The automatic uploader is disabled.", :status => 503 unless ssu_enabled?
  end

  def account_cred
    @account_cred ||= AccountCred.for_user(current_user).find(params[:id])
  end

  def creds
    return nil unless params.include?(:creds)

    ActiveSupport::JSON.decode(params[:creds])
  end

  def financial_inst
    @financial_inst ||= FinancialInst.find_for_user(params[:fi], current_user)
  end
end

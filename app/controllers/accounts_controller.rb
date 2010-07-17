class AccountsController < ApplicationController
  before_filter :check_authentication

  # GET /accounts
  def index
    respond_to do |format|
      format.html
    end
  end

  # GET /accounts/1
  def show
    if account.nil?
      redirect_to accounts_url
    else
      respond_to do |format|
        format.html do
          redirect_to accounts_url(:anchor => account_path(account))
        end
      end
    end
  end

  # PUT /accounts/1
  def update
    if account.nil?
      return render :nothing => true, :status => :not_found
    end

    account.name = params[:name] unless params[:name].blank?
    if params[:currency]
      account.currency = Currency.known?(params[:currency]) ? params[:currency] : 'USD'
    end

    # Update status
    case params[:status]
    when "active"
      account.status = Constants::Status::ACTIVE
    when "archived"
      account.status = Constants::Status::ARCHIVED
    end

    # update balance and account type
    if params[:enable_balance] && account.manual_account?
      account.account_type_id = (params[:enable_balance] =~ /^(true|1|t)$/) ?
        AccountType::MANUAL : AccountType::CASH
    end

    if account.has_balance? && params[:current_balance]
      account.balance = params[:current_balance]
    end

    account.save!

    respond_to do |format|
      format.json { render :json => present(account) }
    end
  end

  # DELETE /accounts/1
  def destroy
    if account.nil?
      return render :text => "Could not delete your account.", :status => :forbidden
    end

    # require correct password to delete an account
    if not current_user.valid_password?(params[:password])
      return render :text => "Incorrect password", :status => :forbidden
    end

    @account.safe_delete
    @account.send_later(:destroy)
    render :nothing => true
  end

  # GET /accounts/1/financial_institution_site
  def financial_institution_site
    if account && account.financial_inst && account.financial_inst.url.present?
      redirect_to account.financial_inst.url
    else
      render :nothing => true, :status => :not_found
    end
  end

  # POST /accounts
  def create
    # default to USD if the currency is missing or unknown
    params[:currency] = 'USD' if !Currency.known?(params[:currency])
    @account = Account.create(:name => params[:name],
                              :user => current_user,
                              :account_type_id => params[:balance] ? AccountType::MANUAL : AccountType::CASH,
                              :currency => params[:currency])
    @account.balance = params[:balance] if params[:balance]

    respond_to do |format|
      format.html { redirect_to account_url(@account) }
      format.json do
        if @account.errors.any?
          render(:json => {:errors => @account.errors.full_messages.to_json}, :status => :bad_request)
        else
          render(:json => {:id => @account.id_for_user, :guid => @account.guid }, :status => :ok)
        end
      end
    end
  end

  # POST /accounts/trigger_updates
  def trigger_updates
    User::AccountUpdateManager.login!(current_user, self, :force => true)
    render :nothing => true
  end

  # POST /accounts/enable
  def enable
    params[:accounts] && params[:accounts].each do |id, input|
      account = current_user.account_by_id_for_user(id)
      account.name = input[:name]
      if input[:enabled]
        account.status = Constants::Status::ACTIVE
        account.save
      else
        account.destroy # set status to DISABLED and delete txactions
      end
    end
    redirect_to(params[:add_another] ? new_upload_path : user_home_path)
  end

private

  def account
    # if the id looks like a guid, do the look up by that
    @account ||= (params[:id] =~ /^[0-9a-z]{64}$/) ?
      current_user.accounts.find_by_guid(params[:id]) :
      current_user.accounts.find_by_id_for_user(params[:id])
  end
end
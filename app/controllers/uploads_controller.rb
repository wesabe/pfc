class UploadsController < ApplicationController
  before_filter :check_authentication
  before_filter :only_allow_html, :only => [:new, :manual, :ssu]
  before_filter :require_ac, :only => [:error, :security]

  # FIXME: we should not be declaring stylesheets in the controller
  stylesheet 'upload-accounts'

  WEB_UPLOADER_CLIENT_NAME = 'Wesabe-WebUploader'
  WEB_UPLOADER_CLIENT_VERSION = '1.1'

  def index
    if params[:account_id]
      if @account = current_user.account(params[:account_id])
        @uploads = @account.uploads.reject {|u| u.txaction_count_for_account(@account) == 0}
        @last_balance = @account.last_balance
        return render
      end
    end
    redirect_to root_url # if all else fails, just send the user home
  end

  # show the file associated with this upload
  def destroy
    if upload = Upload.find_by_guid(params[:id])
      if upload.owned_by_user?(current_user)
        upload.destroy_for_account(current_user.account(params[:account_id]))
      end
    end
    render :nothing => true
  end

  def new
    @featured_fis = FinancialInst.find_all_by_featured(true, :order => "name")
  end

  def choose
    return unless financial_inst

    if ssu_enabled? && financial_inst.ssu_support?(current_user)
      # If possible, send users to SSU
      @path = ssu_new_upload_path(:fi => financial_inst)
    end

    # Worst case (or by request), manual uploads
    if params[:upload_type] != "manual" && @path
      redirect_to @path
    else
      redirect_to manual_uploads_path(:fi => financial_inst)
    end
  end

  def manual
    @financial_inst = financial_inst
    @need_more_info = params[:need_more_info]
    @show_form = "display:none;" unless flash[:error]
  end

  def ssu
    return unless financial_inst

    return redirect_to(new_upload_path) unless ssu_enabled? && (params[:force] == 'true' || financial_inst.ssu_support?(current_user))
    @account_creds = current_user.account_creds.find_all_by_financial_inst_id(financial_inst.id)
  end

  def error
    respond_to do |format|
      format.html
    end
  end

  # The select action now takes three parameters to help make working with it
  # easier. An example:
  #
  #     new_accounts=1&old_accounts=6&fi=us-000238
  #
  # This will pretend that SSU found one new account, six old accounts, and that
  # the bank was Bank of America. All params are optional, but there must be one
  # or both of new_accounts and old_accounts.
  def select
    if Rails.development? && (params[:old_accounts] || params[:new_accounts])
      @fi = params[:fi] ?
        FinancialInst.find_for_user(params[:fi], current_user) :
        FinancialInst.first(:conditions => ['wesabe_id like ?', 'us-%'])
      @new_accounts, @old_accounts = [], []
      params[:new_accounts].to_i.times {|i| @new_accounts << Account.create_sample}
      params[:old_accounts].to_i.times {|i| @old_accounts << Account.create_sample}
    else
      require_ac
      @accounts = @ac.accounts
      @new_accounts, @old_accounts = @accounts.partition do |account|
        account.newly_created_by?(@ac) || account.disabled?
      end
    end
  end

  def create
    @need_more_info = false
    referer = internal_referer || {}

    if params[:statement]
      unless file_provided?(params[:statement])
        flash[:error] = { :message => "Please upload a bank/creditcard statement." }
        params.delete(:statement)
        return redirect_to(referer.reverse_merge(params))
      end

      upload_params = {
        :user => current_user,
        :account_type => params[:account_type],
        :statement => params[:statement].read,
        :client_name => WEB_UPLOADER_CLIENT_NAME,
        :client_version => WEB_UPLOADER_CLIENT_VERSION,
        :client_platform_id => ClientPlatform.find_or_create_by_name(request.user_agent).id
      }
      upload_params.update(:account => account) if account
      upload_params.update(:financial_inst_id => financial_inst.id, :account_name => financial_inst.name) if financial_inst

      begin
        upload = Upload.generate(upload_params)
        flash[:error] = nil # not sure why we'd have to do this; but the error sticks around otherwise
      rescue MakeOFX2::TimeoutError => e
        flash[:error] = {:message => "There was a problem processing the statement you uploaded. Please <a href='#{new_support_request_url}'>contact support</a> for help." }
        return redirect_to(referer.reverse_merge(params))
      # FIXME: have the following return more information to the user about what kind of document they just uploaded (e.g. sorry, we don't accept PDF files)
      rescue MakeOFX2::AbstractException => e
        flash[:error] = {:message => "We couldn't parse the statement you uploaded. We only understand OFX, QFX, OFC, or QIF " +
        "files at the moment, and sometimes even those can throw us a curveball. Please try another format." }
        return redirect_to(referer.reverse_merge(params))
      end

      # get the statement format; if OFX, convert it and we're done; if QIF, we need to get
      # account type, number, and balance
      if @account || upload.original_format =~ /^(OFX|OFC)/
        begin
          Importer.import(upload)
        rescue Importer::UnsupportedStatementType
          logger.warn("unsupported statement type")
          flash[:error] = { :message => "We didn't recognize the account type in the statement you uploaded. We currently only " +
          "support bank or credit card statements. We don't yet support investment accounts (if this " +
          "is not an investment account, we probably had trouble parsing your statement." }
          return redirect_to(referer.reverse_merge(params))
        rescue Importer::XMLParseException => e
          subject = "fixofx failed importing #{upload.original_format} statement from #{financial_inst ? financial_inst.name : 'UNKNOWN'} (#{financial_inst ? financial_inst.wesabe_id : 'UNKNOWN'}) with #{e.class}"
          logger.error(subject + ': ' + e.message)
          flash[:error] = {:message => "We couldn't parse the statement you uploaded." }
          return redirect_to(referer.reverse_merge(params))
        end
      else # QIF upload...need to get more info
        # store the upload data in a temp file and go get more info
        tempfile = File.open(TempfilePath.generate('upload', ApiEnv::PATH[:upload_temp_dir]), "w")
        Marshal.dump(upload, tempfile)
        tempfile.close
        session[:upload_tempfile] = tempfile.path
        params[:statement] = nil
        return redirect_to(referer.reverse_merge(params).update(:need_more_info => true))
      end
    elsif params[:balance] # we're returning from collecting the QIF data
      if params[:account_number].blank? || (params[:account_number].size > 4)
        flash[:error] = "Please enter the last 4 digits of the account number."
        flash[:error_for] = 'account_number'
      elsif params[:balance].blank?
        flash[:error] = "Please enter a balance."
        flash[:error_for] = 'balance'
      elsif params[:account_type].blank?
        flash[:error] = "Please select an account type."
        flash[:error_for] = 'account_type'
      end
      if flash[:error]
        return redirect_to(referer.reverse_merge(params).update(:need_more_info => true))
      end

      # retrieve the upload from the temp file
      upload = nil
      begin
        tempfile = File.open(session[:upload_tempfile])
        Upload # make sure Upload is loaded for Marshal
        upload = Marshal.load(tempfile)
      rescue Exception => ex
        logger.error("Exception unmarshalling upload temp file (#{session[:upload_tempfile]}): " +
          ex.message + "\n    " + ex.backtrace.join("\n    "))
      ensure
        File.delete(session[:upload_tempfile]) if session[:upload_tempfile] && File.exist?(session[:upload_tempfile])
        session[:upload_tempfile] = nil
      end

      unless upload
        logger.error("upload has gone missing!")
        flash[:error] = "There was a problem processing your uploaded statement. Please try again."
        return redirect_to(referer)
      end

      upload.account_type = params['account_type']
      upload.account_number = params['account_number']
      upload.balance = params[:balance]
      upload.convert_to_ofx2 # reconvert to ofx

      Importer.import(upload)
    end

    if !@need_more_info && !flash[:error] && (upload && !upload.accounts.blank?)
      return redirect_to(account_path(upload.accounts.first.id_for_user))
    else
      return redirect_to(accounts_path)
    end
  end

private

  def financial_inst
    @financial_inst ||= begin
      account && account.financial_inst ||
        FinancialInst.find_for_user(params[:fi_name] || params[:fi], current_user).tap do |fi|
          redirect_to new_upload_path if fi.nil?
        end
    end
  end

  def account
    @account ||= current_user.accounts.find_by_uri(params.delete(:account_uri))
  end

  def require_ac
    @ac = current_user.find_by_cred_guid(params[:cred])
    @fi = @ac.financial_inst if @ac
    redirect_to new_upload_path unless @ac
  end
end

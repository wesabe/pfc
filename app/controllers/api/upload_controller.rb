class Api::UploadController < ApplicationController
  include Api::UploadHelper

  layout nil

  before_filter :check_basic_auth_credentials

  # exception we throw if we get a request that's too large
  class RequestSizeExceeded < Exception; end
  class UnsupportedUploader < Exception; end

  # return config file with user accounts
  def config
    # check api version
    api_version = get_api_version(request.user_agent)
    return render(:action => 'error/version') unless compatible_version?(api_version)

    # KLUDGE: throw an exception if the version is 1.09/Mac because Jay released debug code
    if request.user_agent =~ /1\.0\.9.*?darwin/i
      return render(:action => 'error/unsupported_uploader_version')
    end

     # update last api login
    @user.last_api_login = Time.now
    @user.save

    @accounts = @user.active_accounts
  end

  # method to upload a set of transaction data
  def statement
    if request.post?
      begin
        Importer.import_request(@user, request, @account_cred_id)
      rescue RequestSizeExceeded
        return render_text('', '413 Request Entity Too Large')
      rescue Importer::UnsupportedStatementType
        return render(:action => 'error/unsupported_statement_type')
      rescue Exception => e
        logger.error([e.message, *e.backtrace].join("\n"))
        render(:action => 'error/import_failed')
      end
    end
  end

private

  def check_basic_auth_credentials
    if params[:job_guid] && params[:user_id]
      job = SsuJob.find_by_job_guid(params[:job_guid])
      if job && !job.expired? && (@user = User.find_by_id(params[:user_id]))
        @account_cred_id = job.account_cred_id
        set_current_user(@user)
      else
        render :text => "Invalid job: Access denied.", :status => 401
      end
    else
      @user = authenticate_or_request_with_http_basic "Wesabe Upload API" do |username, password|
        if user = User.authenticate(username, password)
          set_current_user(user)
        end
        user
      end
    end
  rescue Authentication::LoginThrottle::UserThrottleError
    render(
      :text => 'Too many failed login attempts. This account is temporarily disabled. Please try again later.',
      :status => :forbidden,
      :layout => false
    )
    return false
  end

end


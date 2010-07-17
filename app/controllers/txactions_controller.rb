class TxactionsController < ApplicationController
  layout nil
  before_filter :check_authentication

  def create
    return unless account

    # only allow txactions to be created in manual accounts
    if not account.manual_account?
      flash.now[:error] = %{There was a problem saving your transaction. Please reload the page and try again.}
      flash.now[:error_for] = 'merchant_name'
      return _render_response(:create)
    end

    txaction ||= account.new_txaction

    if params[:merchant_name].blank?
      flash.now[:error] = 'Please enter a merchant name.'
      flash.now[:error_for] = 'merchant_name'
      return _render_response(:create)
    end

    # get merchant name
    unless merchant = Merchant.find_by_name(params[:merchant_name])
      merchant = Merchant.create(:name => params[:merchant_name])
      expire_action("merchants/user_index/#{current_user.id}")
    end

    txaction.merchant = merchant

    # set amount and date
    begin
      txaction_form = Txaction::Form.update(txaction, params)
    rescue Txaction::Form::UpdateValidationFailed => e
      flash.now[:error] = e.message
      flash.now[:error_for] = e.field
      return _render_response(:create)
    end

    # if the merchant on the txaction has changed, expire the user's merchant list cache
    if txaction.changed.include?("merchant_id")
      expire_action("merchants_for_user_#{current_user.id}")
    end

    # handle file attachement
    _process_file_attachments(txaction)
    txaction.save!
    txaction.attach_matching_transfer

    respond_to do |format|
      # yes, this is right. because of the stupid iframe, if the content type is json, we get a popup window
      format.html { render :json => txaction.to_json }
      format.json { render :json => txaction.to_json }
    end
  end

  # Saves edits to Txactions.
  def update
    return unless txaction

    _process_file_attachments(txaction)

    response_object = txaction
    response_status = nil

    # set amount and date
    begin
      Txaction::Form.update(txaction, params)
      # if the merchant on the txaction has changed, expire the user's merchant list cache
      if txaction.changed.include?("merchant_id")
        expire_action("merchants_for_user_#{current_user.id}")
      end
    rescue Txaction::Form::UpdateValidationFailed => e
      response_object = {:error => {:message => e.message, :field => e.field}}
      response_status = :bad_request
    end

    # hack for file uploads, see File Uploads at http://malsup.com/jquery/form/#code-samples
    if request.xhr?
      render :json => response_object.to_json, :status => response_status
    else
      self.content_type = 'text/html'
      render :text => "<textarea>#{response_object.to_json}</textarea>", :status => response_status
    end
  end

  def destroy
    return unless txaction

    txaction.safe_delete

    respond_to do |format|
      format.html { render :nothing => true }
      format.json { render :json => {} }
    end
  end

  def undelete
    return unless txaction

    txaction.update_attribute(:status, Constants::Status::ACTIVE)
    render :nothing => true
  end

  # returns a list of possible check matches
  def merchant_list_checks
    @check_merchants = Merchant.find_most_likely_merchants(txaction, :check => true, :limit => 2).map(&:name)
    render :json => @check_merchants
  end

  # called when a merchant is selected from the auto-complete dropdown
  def on_select_merchant
    return unless txaction

    if @merchant = Merchant.find_edited_by_name(params[:name])
      @suggested_tags = @merchant.suggested_tags
      sign = txaction ? txaction.amount.sign : -1
      @merchant_user = MerchantUser.get_merchant_user(current_user, @merchant, sign)
      @autotags = AccountMerchantTagStat.autotags_for(current_user, @merchant, sign)
    end

    respond_to do |format|
      format.json { _on_select_merchant_json }
    end
  end

  def _on_select_merchant_json
    if @merchant
      render :json => {
        'id' => @merchant.id,
        'suggested-tags' => @suggested_tags.map {|display_name| {'display' => display_name}},
        'tags' => @autotags.any? ? {
          # FIXME: once these are from AccountMerchantStats, use @ams.autotags_string
          'display' => @autotags.map(&:display_name).join(" "),
          'value' => @autotags.map {|tagging|
            {'name' => {'value' => tagging.name_without_split, 'display' => tagging.display_name}}
          }
        } : nil
      }
    else
      render :json => {}
    end
  end

  def transfer_selector
    return unless txaction

    @possibilities = txaction.find_all_matching_transfers
    render :partial => 'txactions/transfer_select', :locals => {:txaction => txaction}
  end

  private

  def _process_file_attachments(txaction)
    # read in any attachments
    files = []
    0.upto(4) do |i|
      file = params["file_#{i}"]
      unless file.blank?
        files << { :data => file.read,
                   :content_type => file.content_type,
                   :filename => file.original_filename }
      end
    end

    return if files.empty?

    # save attachments
    files.each do |f|
      begin
        txaction.attach(Attachment.generate(current_user, f))
      rescue Attachment::MaxSizeExceeded => e
        logger.error(e.message)
        # FIXME: do some proper error handling
      end
    end


    # delete attachments
    if params[:deleted_attachments]
      params[:deleted_attachments].split.each do |attachment_id|
        if attachment = current_user.attachments.find_by_id(attachment_id)
          txaction.detach(attachment)
          attachment.destroy
        end
      end
    end

    # see if they specified an inbox attachment
    unless params['inbox_attachment'].blank?
      if inbox_attachment = current_user.inbox_attachment(params['inbox_attachment'])
        txaction.attach(inbox_attachment.attachment)
        inbox_attachment.destroy
      end
    end
    txaction.save
  end

  def _render_response(action)
    respond_to do |format|
      format.json do
        if flash[:error]
          render :json => {:error => flash[:error]}, :status => :bad_request
        else
          render :json => {}, :status => :ok
        end
      end
    end
  end

  def account
    @account ||= current_user.accounts.find_by_id_for_user(params[:account_id]).tap do |account|
      if account.nil?
        render :nothing => true, :status => :forbidden
      end
    end
  end

  def txaction
    @txaction ||= Txaction.find_by_id(params[:id]).tap do |txaction|
      # make sure user owns this txaction
      if txaction.nil? || (not current_user.can_edit_txaction?(txaction))
        render :nothing => true, :status => :forbidden
        return nil
      end
    end
  end
end
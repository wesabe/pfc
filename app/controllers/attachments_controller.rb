class AttachmentsController < ApplicationController
  before_filter :check_authentication

  # GET /attachments/1
  def show
    if attachment = current_user.attachments.find_by_guid(params[:id])
      send_data(attachment.read, :filename => attachment.filename, :type => attachment.content_type)
    end
  end

  # POST /attachments.xml
  def create
    @attachment = Attachment.generate(current_user, params)
    InboxAttachment.create!(:user => current_user, :attachment => @attachment) unless @attachment.new_record?

    respond_to do |format|
      if @attachment && @attachment.valid?
        # flash[:notice] = 'Attachment was successfully created.'
        # format.html { redirect_to(@attachment) }
        format.xml  { render :xml => @attachment, :status => :created, :location => @attachment }
      else
        # format.html { render :action => "new" }
        format.xml do
          if @attachment
            errors = @attachment.errors
          else
            errors = ActiveRecord::Errors.new
            errors.add_to_base("Could not create attachment")
          end
          render :xml => errors, :status => :unprocessable_entity
        end
      end
    end
  rescue Attachment::MaxSizeExceeded => e
    logger.error(e.message)
    render :text => e.message, :status => :request_entity_too_large
  end

  # DELETE /attachments/:id
  def destroy
    if attachment = current_user.attachments.find_by_guid(params[:id])
      attachment.destroy
    end

    render :nothing => true, :status => :ok
  end
end

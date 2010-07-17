class SnapshotsController < ApplicationController
  before_filter :check_authentication

  def create
    Snapshot.async_build_snapshot_for_user(current_user)
    render :nothing => true, :status => :created
  end

  def show
    respond_to do |format|
      format.html
      format.zip            { download(:zip) }
      format.wesabeSnapshot { download(:wesabeSnapshot) }
    end
  end

  private

  def download(type)
    if snapshot && snapshot.built?
      send_file snapshot.archive,
        :filename => "#{current_user.to_param}.#{type}",
        :type => type,
        :disposition => 'attachment'
    else
      render :nothing => true, :status => :not_found
    end
  end

  def snapshot
    @snapshot ||= Snapshot.find_by_uid(params[:id])
  end
end

class SnapshotsController < ApplicationController
  before_filter :check_authentication

  def create
    Snapshot.async_build_snapshot_for_user(current_user)
    render :nothing => true, :status => :created, :location => snapshot_url
  end

  def show
    respond_to do |format|
      format.html do
        @snapshot = snapshot
        render :partial => 'snapshot' if request.xhr?
      end
      format.zip  do
        download(:zip)
      end
      format.json do
        render :json => snapshot ? {:snapshot => {:uid => snapshot.uid, :ready => snapshot.built?}} :
                                   {:error => "No snapshot available. Please POST #{snapshot_url} to create it."}
      end
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
    @snapshot ||= current_user.snapshot
  end
end
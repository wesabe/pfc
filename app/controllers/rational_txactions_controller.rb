class RationalTxactionsController < ApplicationController
  before_filter :check_authentication
  before_filter :set_expiration

  def index
    @txactions = DataSource::Txaction.new(current_user) do |ds|
      ds.rationalize      = true
      ds.filter_transfers = true
      ds.filtered_tags    = current_user.filter_tags
      ds.start_date       = (params[:start_date] || 1.month.ago)
      ds.end_date         = (params[:end_date] || Date.today)
      ds.amount           = params[:type] if params[:type]
    end.txactions

    respond_to do |format|
      format.xml
    end
  end

protected

  def set_expiration
    expires_in 1.minute
  end
end
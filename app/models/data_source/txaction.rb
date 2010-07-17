# A wrapper class encapsulating all of the necessary DB logic for displaying
# txaction lists.
#
# ==== Example Usage
#
#   # in the controller:
#   @txactions = DataSource::Txaction.new(current_user) do |ds|
#     ds.include_balances = true
#     ds.account = @account
#     ds.tags = [Tag.find_by_name('food'), Tag.find_by_name('burritos')]
#   end.txactions
#
#   # in the view:
#   @txactions.each do |txaction|
#     # etc.
#   end
#
#   # or if you need to pass it around:
#   @data_source = DataSource::Txaction.new(current_user)
#   @data_source.accounts = [@checking, @savings]
#
#   # and then to make it actually query the database:
#   @data_source.load!
#
#   # in the view:
#   @data_source.txactions.each # etc.
#
# ==== Pagination
#
#   # show the 3rd page of txactions:
#   @txactions = DataSource::Txaction.new(
#     current_user, Txaction::Paginator.new(3)
#   ).txactions
#
#   # show the txactions for a given month:
#   @txactions = DataSource::Txaction.new(
#     current_user, Txaction::MonthPaginator.new(params[:year], params[:month])
#   ).txactions
class DataSource::Txaction < DataSource::AbstractTxaction

end

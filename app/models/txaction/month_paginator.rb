class Txaction::MonthPaginator < Txaction::Paginator
  attr_reader :conditions, :limit, :offset

  def initialize(year, month, page = 1, page_size = 30)
    # if time isn't valid, just make it this month
    start_time = Time.mktime(year, month) rescue Time.now.beginning_of_month
    end_time = start_time.end_of_month

    page = page.to_i if page.is_a?(String)
    page = 1 if !page || page < 1

    @conditions = { "txactions.date_posted" => start_time..end_time }
    @limit = page_size
    @offset = (page - 1) * page_size
  end
end

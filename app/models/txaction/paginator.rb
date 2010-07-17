class Txaction::Paginator
  attr_reader :conditions, :limit, :offset

  PAGE_SIZE = 30

  def initialize(page, page_size = PAGE_SIZE)
    @conditions = {}
    @limit = page_size
    @offset = (page - 1) * page_size
  end
end
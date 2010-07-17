# originally from http://weblog.jamisbuck.org/2007/4/6/faking-cursors-in-activerecord
class <<ActiveRecord::Base
  def each_block(limit=1000, options = {})    
    rows = find_cursor_style(0, limit, options)
    while rows.any?
      yield rows
      rows = find_cursor_style(rows.last.id, limit, options)
    end
    self
  end
  
  def each(limit=1000, options = {})
    each_block(limit, options) { |rows| rows.each { |record| yield record }}
  end

private

  def find_cursor_style(last_id, limit, options)
    with_scope(:find => options) do
      find(:all, :conditions => ["#{table_name}.id > ?", last_id], :limit => limit)
    end
  end

end

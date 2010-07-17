class Stock < ActiveRecord::Base
  # override find_by_symbol so we can clean up the symbol
  def find_by_symbol(symbol)
    self.class.find(:first, :conditions => ["symbol = ?", symbol.gsub(/\W/,'.')])
  end
end

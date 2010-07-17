# ruby's Date.parse is completely happy with the date 20087-01-12. Mysql is not so happy with that.
# So do our own range checking.
require 'date'

class Date
  class << self
    alias_method :parse_without_year_checking, :parse
    def parse(*args)
      d = Date.parse_without_year_checking(*args)
      if d.year > 9999
        raise ArgumentError, 'invalid date'
      else
        d
      end
    end        
  end
end
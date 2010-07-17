# some methods for identifying and fixing ambiguous dates (where both mm/dd and dd/mm are valid)
class Time
  def ambiguous_date?
    day <= 12 and month <= 12
  end
  
  # return a new Time object with the month and day swapped
  def swap_month_and_day
    Time.mktime(year, day, month, hour, min, sec, usec)
  end
  alias :swap_day_and_month :swap_month_and_day
end

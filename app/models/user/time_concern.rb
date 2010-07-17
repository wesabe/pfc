# time concern for User
class User
  attr_accessor :timezone_offset # offset from GMT in minutes

  # return local time (as a DateTime) of the user, if available
  def local_time(time = Time.now)
    if timezone_offset
      return time.to_datetime.new_offset(Rational(timezone_offset,1440))
    else
      return time.to_datetime # just use the server time
    end
  end
end
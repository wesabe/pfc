module ProfileHelper
  def default_time_zone_options(user)
    tz = user.country && user.country.default_time_zone
    return tz ? [tz] : nil
  end
end
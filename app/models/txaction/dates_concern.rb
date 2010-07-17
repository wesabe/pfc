# dates concern for Txaction
class Txaction
  validates_presence_of :date_posted, :fi_date_posted

  before_validation :set_date_posted

  # override date_posted to return fi_date_posted if date_posted isn't set
  def date_posted
    read_attribute(:date_posted) || read_attribute(:fi_date_posted)
  end

  # override fi_date_posted to return date_posted if fi_date_posted isn't set
  def fi_date_posted
    read_attribute(:fi_date_posted) || read_attribute(:date_posted)
  end

  # called from before_validation. Make sure both date_posted and fi_date_posted are set
  def set_date_posted
    self.date_posted = read_attribute(:fi_date_posted) unless read_attribute(:date_posted) # need to do it this way because we've overridden date_posted above
    self.fi_date_posted = read_attribute(:date_posted) unless read_attribute(:fi_date_posted)
  end

  # return true if the user changed the date_posted
  def changed_date_posted?
    read_attribute(:fi_date_posted) && (read_attribute(:date_posted).to_date != read_attribute(:fi_date_posted).to_date)
  end
end
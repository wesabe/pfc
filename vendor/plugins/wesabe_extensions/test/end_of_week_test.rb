require "test/unit"

require "lib/time/end_of_week"

class TestLibTimeEndOfWeek < Test::Unit::TestCase
  def test_should_return_end_of_week
    assert_equal(Time.mktime(2007, 4, 15, 23, 59, 59), Time.mktime(2007, 4, 11).end_of_week)
  end
  
  def test_should_work_between_months
    assert_equal(Time.mktime(2007, 5, 6, 23, 59, 59), Time.mktime(2007, 4, 30).end_of_week)
  end
  
  def test_should_not_freak_out_about_dst
    assert_equal(Time.mktime(2006, 4, 2, 23, 59, 59), Time.mktime(2006, 3, 27).end_of_week)
    assert_equal(Time.mktime(2006, 10, 29, 23, 59, 59), Time.mktime(2006, 10, 23).end_of_week)
  end
end
require "test/unit"
require "lib/time/ambiguous_date"

class AmbiguousDateTest < Test::Unit::TestCase
  def setup
    @ambiguous_date = Time.mktime(2007,8,11)
    @unambiguous_date = Time.mktime(2007,8,29)
  end
  
  def test_should_identify_ambiguous_date
    assert @ambiguous_date.ambiguous_date?
    assert !@unambiguous_date.ambiguous_date?
  end
  
  def test_should_swap_month_and_day
    assert_equal Time.mktime(2007,11,8), @ambiguous_date.swap_month_and_day
  end
end

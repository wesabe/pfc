require "test/unit"

require "lib/file/change_extname"

class TestLibFileChangeExtName < Test::Unit::TestCase
  def test_should_change_ext_name
    assert_equal(File.change_extname("/var/www/example.com/index.html", ".shtml"), "/var/www/example.com/index.shtml")
    assert_equal(File.change_extname("/var/www/example.com/index.html", "shtml"),  "/var/www/example.com/index.shtml")
    assert_equal(File.change_extname("/var/www/example.com/index.html", :shtml),   "/var/www/example.com/index.shtml")
  end
end

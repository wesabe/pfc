require "test/unit"

require "lib/string/to_gz"

class TestLibStringToGz < Test::Unit::TestCase
  def test_should_gzip_strings
    data = (["woot"] * 300).join(" ")
    gzipped_data = data.to_gz
    ungzipped_data = ""
    assert_nothing_raised do
      ungzipped_data = gzipped_data.from_gz
    end
    assert data.size > gzipped_data.size
    assert_equal(data, ungzipped_data)
  end
end

require "rubygems"
require "active_support"

require "test/unit"

require "lib/string/better_titlecase"

class TestLibStringBetterTitlecase < Test::Unit::TestCase

  def test_should_convert_stuff_to_titles
    data = ["Xxx 000000000/XXXXXXX XXX XXX 000000000##",
            "0000 Xxxxxxx 0000000 Xxxx Xxxxxx/XXXXXXX XXXXXXXXX 0000 XXXXXXX 0000000 XXXX XXXXXXX",
            "000000000000 00x00 000000000/XX XXXXXXXX XX 000000000000 00X00 000000000",
            "000000000000 00x00 000000000/XX XXXXXXXX XX 000000000000 00X00 000000000",
            "Xxxxxx Xxxxx 00x00 000000000/XXXXXXXX XXXX XXXXXXXXXX XX XXXXXX XXXXX 00X00 000000000",
            "Xxx 000000000/XXXXXXX XXX XXX 000000000##",
            "0000 Xxxxxxx 0000000 Xxxx Xxxxxx/XXXXXXX XXXXXXXXX 0000 XXXXXXX 0000000 XXXX XXXXXXX",
            "0000/XXXXXXX XXXXXXXX XXX 0000 ##",
            "0000/XXXXXXX XXXXXXXX XXX 0000 ##",
            "Xxxxxxxxxx 0xx/XXXXXXX XXXXXXXX XXXX XXXXXXXXXX 0XX"]
    fixtures = ["Xxx 000000000/Xxxxxxx Xxx Xxx 000000000##",
                "0000 Xxxxxxx 0000000 Xxxx Xxxxxx/Xxxxxxx Xxxxxxxxx 0000 Xxxxxxx 0000000 Xxxx Xxxxxxx",
                "000000000000 00x00 000000000/Xx Xxxxxxxx Xx 000000000000 00 X00 000000000",
                "000000000000 00x00 000000000/Xx Xxxxxxxx Xx 000000000000 00 X00 000000000",
                "Xxxxxx Xxxxx 00x00 000000000/Xxxxxxxx Xxxx Xxxxxxxxxx Xx Xxxxxx Xxxxx 00 X00 000000000",
                "Xxx 000000000/Xxxxxxx Xxx Xxx 000000000##",
                "0000 Xxxxxxx 0000000 Xxxx Xxxxxx/Xxxxxxx Xxxxxxxxx 0000 Xxxxxxx 0000000 Xxxx Xxxxxxx",
                "0000/Xxxxxxx Xxxxxxxx Xxx 0000 ##",
                "0000/Xxxxxxx Xxxxxxxx Xxx 0000 ##",
                "Xxxxxxxxxx 0xx/Xxxxxxx Xxxxxxxx Xxxx Xxxxxxxxxx 0 Xx"]
    assert_equal(fixtures, data.map(&:titlecase))
  end

end
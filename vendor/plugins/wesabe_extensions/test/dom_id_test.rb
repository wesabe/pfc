require "test/unit"

require "lib/string/dom_id"

class TestLibStringDomId < Test::Unit::TestCase
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
    fixtures = ["xxx_000000000xxxxxxx_xxx_xxx_000000000",
                "id_0000_xxxxxxx_0000000_xxxx_xxxxxxxxxxxxx_xxxxxxxxx_0000_xxxxxxx_0000000_xxxx_xxxxxxx",
                "id_000000000000_00x00_000000000xx_xxxxxxxx_xx_000000000000_00x00_000000000",
                "id_000000000000_00x00_000000000xx_xxxxxxxx_xx_000000000000_00x00_000000000",
                "xxxxxx_xxxxx_00x00_000000000xxxxxxxx_xxxx_xxxxxxxxxx_xx_xxxxxx_xxxxx_00x00_000000000",
                "xxx_000000000xxxxxxx_xxx_xxx_000000000",
                "id_0000_xxxxxxx_0000000_xxxx_xxxxxxxxxxxxx_xxxxxxxxx_0000_xxxxxxx_0000000_xxxx_xxxxxxx",
                "id_0000xxxxxxx_xxxxxxxx_xxx_0000_",
                "id_0000xxxxxxx_xxxxxxxx_xxx_0000_",
                "xxxxxxxxxx_0xxxxxxxxx_xxxxxxxx_xxxx_xxxxxxxxxx_0xx"]
    assert_equal(fixtures, data.map{ |d| d.as_id })
  end
end
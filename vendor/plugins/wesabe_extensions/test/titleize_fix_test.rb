require "rubygems"
require "test/unit"
require "string/titleize_fix"

class TestLibStringTitleizeFix < Test::Unit::TestCase
  include ActiveSupport::Inflector
  
  def setup
    @fixtures = {
      # add as needed
      'one time I had a puppy' => "One Time I Had A Puppy",
      'AWOL mr banks said go go go' => "AWOL Mr Banks Said Go Go Go",
      "paddy o'malley's \"lunch\" is green's" => "Paddy O'Malley's \"Lunch\" Is Green's",
      "bongo's 'bongo' bongo's s'bongo 'bongo" => "Bongo's 'Bongo' Bongo's S'Bongo 'Bongo",
      "dinesh d'souza iza loser" => "Dinesh D'Souza Iza Loser"
    }
  end
  
  def test_should_titleize_a_bunch_of_strings
    for original, expected in @fixtures
      assert_equal(expected, titleize(original))
    end
  end
  
end

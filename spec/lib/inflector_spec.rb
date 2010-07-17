require 'spec_helper'

module Ace
  module Base
    class Case
    end
  end
end

describe ActiveSupport::Inflector, "legacy test/unit tests" do
  SingularToPlural = {
    "search"      => "searches",
    "switch"      => "switches",
    "fix"         => "fixes",
    "box"         => "boxes",
    "process"     => "processes",
    "address"     => "addresses",
    "case"        => "cases",
    "stack"       => "stacks",
    "wish"        => "wishes",
    "fish"        => "fish",

    "category"    => "categories",
    "query"       => "queries",
    "ability"     => "abilities",
    "agency"      => "agencies",
    "movie"       => "movies",

    "archive"     => "archives",

    "index"       => "indices",

    "wife"        => "wives",
    "safe"        => "saves",
    "half"        => "halves",

    "move"        => "moves",

    "salesperson" => "salespeople",
    "person"      => "people",

    "spokesman"   => "spokesmen",
    "man"         => "men",
    "woman"       => "women",

    "basis"       => "bases",
    "diagnosis"   => "diagnoses",
    "diagnosis_a" => "diagnosis_as",

    "datum"       => "data",
    "medium"      => "media",
    "analysis"    => "analyses",

    "node_child"  => "node_children",
    "child"       => "children",

    "experience"  => "experiences",
    "day"         => "days",

    "comment"     => "comments",
    "foobar"      => "foobars",
    "newsletter"  => "newsletters",

    "old_news"    => "old_news",
    "news"        => "news",

    "series"      => "series",
    "species"     => "species",

    "quiz"        => "quizzes",

    "perspective" => "perspectives",

    "ox"          => "oxen",
    "photo"       => "photos",
    "buffalo"     => "buffaloes",
    "tomato"      => "tomatoes",
    "dwarf"       => "dwarves",
    "elf"         => "elves",
    "information" => "information",
    "equipment"   => "equipment",
    "bus"         => "buses",
    "status"      => "statuses",
    "status_code" => "status_codes",
    "mouse"       => "mice",

    "louse"       => "lice",
    "house"       => "houses",
    "octopus"     => "octopi",
    "virus"       => "viruses", # viri my ass
    "alias"       => "aliases",
    "portfolio"   => "portfolios",

    "vertex"      => "vertices",
    "matrix"      => "matrices",
    "matrix_fu"   => "matrix_fus",

    "axis"        => "axes",
    "testis"      => "testes",
    "crisis"      => "crises",
    "tax"         => "taxes",
    "taxi"        => "taxis",

    "rice"        => "rice",
    "shoe"        => "shoes",

    "horse"       => "horses",
    "prize"       => "prizes",
    "edge"        => "edges",
    "cow"         => "cows", # kine? pfffft
    "sex"         => "sexes",
    "move"        => "moves",
    "love"        => "loves"
  }

  Irregularities = {
    'person' => 'people',
    'man'    => 'men',
    'child'  => 'children'
  }

  def test_pluralize_plurals
    assert_equal "plurals", ActiveSupport::Inflector.pluralize("plurals")
    assert_equal "Plurals", ActiveSupport::Inflector.pluralize("Plurals")
  end

  SingularToPlural.each do |singular, plural|
    define_method "test_pluralize_#{singular}" do
      assert_equal(plural, ActiveSupport::Inflector.pluralize(singular))
      assert_equal(plural.capitalize, ActiveSupport::Inflector.pluralize(singular.capitalize))
    end
  end

  SingularToPlural.each do |singular, plural|
    define_method "test_singularize_#{plural}" do
      assert_equal(singular, ActiveSupport::Inflector.singularize(plural))
      assert_equal(singular.capitalize, ActiveSupport::Inflector.singularize(plural.capitalize))
    end
  end

  %w{plurals singulars uncountables}.each do |inflection_type|
    class_eval "
      def test_clear_#{inflection_type}
        cached_values = ActiveSupport::Inflector.inflections.#{inflection_type}
        ActiveSupport::Inflector.inflections.clear :#{inflection_type}
        assert ActiveSupport::Inflector.inflections.#{inflection_type}.empty?, \"#{inflection_type} inflections should be empty after clear :#{inflection_type}\"
        ActiveSupport::Inflector.inflections.instance_variable_set :@#{inflection_type}, cached_values
      end
    "
  end

  Irregularities.each do |irregularity|
    singular, plural = *irregularity
    ActiveSupport::Inflector.inflections do |inflect|
      define_method("test_irregularity_between_#{singular}_and_#{plural}") do
        inflect.irregular(singular, plural)
        assert_equal singular, ActiveSupport::Inflector.singularize(plural)
        assert_equal plural, ActiveSupport::Inflector.pluralize(singular)
      end
    end
  end

  [ :all, [] ].each do |scope|
    ActiveSupport::Inflector.inflections do |inflect|
      define_method("test_clear_inflections_with_#{scope.kind_of?(Array) ? "no_arguments" : scope}") do
        # save all the inflections
        singulars, plurals, uncountables = inflect.singulars, inflect.plurals, inflect.uncountables

        # clear all the inflections
        inflect.clear(*scope)

        assert_equal [], inflect.singulars
        assert_equal [], inflect.plurals
        assert_equal [], inflect.uncountables

        # restore all the inflections
        singulars.reverse.each { |singular| inflect.singular(*singular) }
        plurals.reverse.each   { |plural|   inflect.plural(*plural) }
        inflect.uncountable(uncountables)

        assert_equal singulars, inflect.singulars
        assert_equal plurals, inflect.plurals
        assert_equal uncountables, inflect.uncountables
      end
    end
  end

  { :singulars => :singular, :plurals => :plural, :uncountables => :uncountable }.each do |scope, method|
    ActiveSupport::Inflector.inflections do |inflect|
      define_method("test_clear_inflections_with_#{scope}") do
        # save the inflections
        values = inflect.send(scope)

        # clear the inflections
        inflect.clear(scope)

        assert_equal [], inflect.send(scope)

        # restore the inflections
        if scope == :uncountables
          inflect.send(method, values)
        else
          values.reverse.each { |value| inflect.send(method, *value) }
        end

        assert_equal values, inflect.send(scope)
      end
    end
  end
end

module ActiveRecordMatchers
  class AssociationMatcher
    def initialize(expected_macro, expected_name, expected_options)
      @expected_macro = expected_macro
      @expected_name = expected_name
      @expected_options = expected_options
    end

    def matches?(model)
      @model_klass = model.is_a?(Class) ? model : model.class
      return association_exists? && macro_matches? && options_matches?
    end

    def failure_message
      return "expected #{@model_klass.name} to #{expectation_description} but #{@failure_message}"
    end

  private

    def association_exists?
      @association = @model_klass.reflect_on_association(@expected_name)
      if @association
        return true
      else
        @failure_message = "no association exists by that name"
        return false
      end
    end

    def macro_matches?
      if @association.macro == @expected_macro
        return true
      else
        @failure_message = "it's a #{@association.macro.inspect} association"
        return false
      end
    end

    def options_matches?
      actual_options = @association.options.slice(*@expected_options.keys)
      if actual_options == @expected_options
        return true
      else
        @failure_message = "has #{actual_options.inspect} instead of #{@expected_options.inspect}"
        return false
      end
    end

    def expectation_description
      name = @expected_name.to_s.camelcase
      case @expected_macro
      when :belongs_to
        "belong to #{name}"
      when :have_one
        "have one #{name}"
      when :has_many
        "have many #{name.pluralize}"
      when :has_and_belongs_to_many
        "have and belong to many #{name.pluralize}"
      end
    end
  end

  def belong_to(model, options = {})
    AssociationMatcher.new(:belongs_to, model, options)
  end

  def have_many(model, options = {})
    AssociationMatcher.new(:has_many, model, options)
  end

  def have_one(model, options = {})
    AssociationMatcher.new(:has_one, model, options)
  end

  def have_and_belong_to_many(model, options = {})
    AssociationMatcher.new(:has_and_belongs_to_many, model, options)
  end
end

RSpec.configure do |config|
  config.include(ActiveRecordMatchers)
end

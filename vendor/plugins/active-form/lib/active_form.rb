# Note ".valid?" method  must occur on object for validates_associated
class ActiveForm

  def initialize(attributes = nil)
    self.attributes = attributes
    yield self if block_given?
  end

  def attributes=(attributes)
    attributes.each do |key,value|
      send(key.to_s + '=', value)
    end unless attributes.nil?
  end

  def [](key)
    instance_variable_get("@#{key}")
  end

  def method_missing( method_id, *args )
    if md = /_before_type_cast$/.match(method_id.to_s)
      attr_name = md.pre_match
      return self[attr_name] if self.respond_to?(attr_name)
    end
    super
  end

  alias_method :respond_to_without_attributes?, :respond_to?

  def new_record?
    true
  end

protected
  def raise_not_implemented_error(*params)
    ValidatingModel.raise_not_implemented_error(*params)
  end

  def self.human_attribute_name(attribute_key_name)
    attribute_key_name.humanize
  end

  # these methods must be defined before Validations include
  alias save raise_not_implemented_error
  alias update_attribute raise_not_implemented_error
  alias save! raise_not_implemented_error

  # The following must be defined prior to Callbacks include
  alias create_or_update raise_not_implemented_error
  alias create raise_not_implemented_error
  alias update raise_not_implemented_error
  alias destroy raise_not_implemented_error

  def self.instantiate(record)
    object = allocate
    object.instance_variable_set("@attributes", record)
    object
  end

public
  include ActiveRecord::Validations
  include ActiveRecord::Callbacks

  def self.self_and_descendents_from_active_record
    [self]
  end

  def self.human_name
    self.to_s
  end

protected

  # the following methods must be defined after include so that they overide
  # methods previously included
  class << self
    def raise_not_implemented_error(*params)
      raise NotImplementedError
    end

    alias validates_uniqueness_of raise_not_implemented_error
    alias create! raise_not_implemented_error
    alias validate_on_create raise_not_implemented_error
    alias validate_on_update raise_not_implemented_error
    alias save_with_validation raise_not_implemented_error
  end

end

# class to construct conditions for AR queries
# cc = ConditionsConstructor.new('foobar > ?', 7)
# cc.add('blah is not null')
# cc.add('baz in (?)', [1,2,3])
# cc.conditions
# # => ["(foobar > ?) AND (blah is not null) AND (baz in (?))", 7, [1, 2, 3]]
class ConditionsConstructor
  def initialize(*args)
    add *args unless args.blank?
  end

  def add(str, *args)
    return if str.respond_to?(:empty?) && str.empty?

    case str
    when Array
      str, *args = *str
    when Hash
      str, *args = conditions_hash_to_array(str)
    when ConditionsConstructor
      self.conditions_strs += str.conditions_strs
      self.conditions_args += str.conditions_args
      return self
    end

    self.conditions_strs << str
    self.conditions_args += args
    self
  end

  def +(other)
    dup.add other
  end

  def conditions(operator=' AND ')
    return [] if conditions_strs.blank?
    [conditions_strs.map{|s|"(#{s})"}.join(operator)] + conditions_args
  end
  alias_method :join, :conditions

  attr_accessor :conditions_strs, :conditions_args

  def conditions_strs
    @conditions_strs ||= []
  end

  def conditions_args
    @conditions_args ||= []
  end

  def ==(other)
    other.is_a?(ConditionsConstructor) &&
    (conditions_strs == other.conditions_strs) &&
    (conditions_args == other.conditions_args)
  end

  def dup
    ConditionsConstructor.new.tap do |cc|
      cc.instance_variable_set("@conditions_args", conditions_args.dup)
      cc.instance_variable_set("@conditions_strs", conditions_strs.dup)
    end
  end


protected

  def conditions_hash_to_array(attributes)
    ary = [attributes.map { |key, value| "#{key} #{attribute_condition(value)}" }.join(' AND ')]

    # set up vars for substitution while handling ranges
    attributes.values.each { |n| (Range === n) ? ary << n.first << n.last : ary << n }

    return ary
  end

  # stolen from AR::Base, thx rails
  def attribute_condition(argument)
    case argument
    when nil then "IS ?"
    when Array, ActiveRecord::Associations::AssociationCollection then "IN (?)"
    when Range then "BETWEEN ? AND ?"
    else "= ?"
    end
  end

end

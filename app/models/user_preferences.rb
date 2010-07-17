class UserPreferences < ActiveRecord::Base
  belongs_to :user
  serialize :preferences

  validates_presence_of :user

  # system preferences aren't viewable or readable by the user
  SYSTEM_PREFS = [:tester_access]
  SYSTEM_PARAMS = [:action, :controller, :context, :format] # REVIEW: should this go in the controller instead?

  # delete a preference
  def delete(preference)
    preferences.delete(preference.to_sym)
    save!
  end

  def toggle(preference)
    return write(preference, (not query(preference)))
  end

  def update_preferences(params)
    # ignore rails params and prefs that users aren't allowed to set directly
    params = params.reject {|k,| system_attr?(k)}.symbolize_keys
    params.each {|k,v| write(k, v)}
    save!
    return _prefs
  end

  def system_attr?(a)
    (SYSTEM_PARAMS + SYSTEM_PREFS).include?(a.to_sym)
  end

  # As of Rails 2.2.2, AR association proxy objects check respond_to? before passing method calls
  def respond_to?(method_id, *)
    case method_id.to_s
    when /(.*?)=$/, /(.*?)\?$/, /^tester_access=?$/
      return true
    else
      super
    end
  end

  def read(key)
    # make sure string true and false are treated as booleans
    case value = _prefs[key.to_sym]
    when 'true'
      return true
    when 'false'
      return false
    else
      return value
    end
  end

  def write(key, value)
    write_attribute(:preferences, _prefs.update(key.to_sym => value))
    return value
  end

  def query(key)
    # double-negate to convert truthy values to true and falsy values to false
    return (not (not read(key)))
  end

  def to_hash
    _prefs.dup
  end

  private

  def _prefs
    (read_attribute(:preferences) || {}).symbolize_keys!
  end

  # allow preferences attributes to be get and set like methods
  #   user.preferences.foo = true
  #   user.preferences.foo?
  #    => true
  def method_missing(method_id, *args)
    # delegate existing attributes to AR
    return super if has_attribute?(method_id.to_s.gsub(/[=?]$/,''))
    case method_id.to_s
    when /(.*?)=$/
      write $1, args.first
      save!
    when /(.*?)\?$/
      query $1
    else
      read method_id
    end
  end
end

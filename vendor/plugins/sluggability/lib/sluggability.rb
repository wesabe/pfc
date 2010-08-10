require "active_support"

module Sluggability
  # Creates a slug out of a string.
  def self.make_slug(name)
    Normalizer.alnum.gsub(name.gsub('&', ' and ').gsub("'", ''), '-')
  end
end

require "sluggability/controller_methods"
require "sluggability/model_methods"
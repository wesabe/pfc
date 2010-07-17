require "active_support"
require "oniguruma"

module Sluggability
  STRIP_NON_ALPHANUMERICS = Oniguruma::ORegexp.new("[[:^alnum:]]", "imx", "utf8")
  
  # Creates a slug out of a string.
  def self.make_slug(name)
    slug = name.gsub("&", " and ").gsub("'", "")
    STRIP_NON_ALPHANUMERICS.gsub(slug, " ").mb_chars.downcase.split(" ").join("-").to_s
  end
  
end

require "sluggability/controller_methods"
require "sluggability/model_methods"
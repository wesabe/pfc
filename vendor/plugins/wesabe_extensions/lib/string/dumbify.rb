require 'oniguruma'
# convert fancy quotes, dashes, etc. to plain-old 7-bit characters
# stolen from http://diveintogreasemonkey.org/casestudy/dumbquotes.html
class String
  DUMBIFY_MAP = {
      "\\x{00a0}" => " ",
      "\\x{00a9}" => "(c)",
      "\\x{00ae}" => "(r)",
      "\\x{00b7}" => "*",
      "\\x{2018}" => "'",
      "\\x{2019}" => "'",
      "\\x{201c}" => '"',
      "\\x{201d}" => '"',
      "\\x{2026}" => "...",
      "\\x{2002}" => " ",
      "\\x{2003}" => " ",
      "\\x{2009}" => " ",
      "\\x{2013}" => "-",
      "\\x{2014}" => "--",
      "\\x{2122}" => "(tm)"
  }.freeze
  
  def dumbify!
    DUMBIFY_MAP.each { |k,v| Oniguruma::ORegexp.new(k, :encoding => Oniguruma::ENCODING_UTF8).gsub!(self, v) }
    self
  end
  
  def dumbify
    self.dup.dumbify!
  end
end
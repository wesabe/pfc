class String
  # This is really only for converting raw txaction names to human text.
  def titlecase
    self.underscore.humanize.gsub(/(\A|[\s&\\\/])([a-z])/) {"#{$1}#{$2.capitalize}"}
  end
end
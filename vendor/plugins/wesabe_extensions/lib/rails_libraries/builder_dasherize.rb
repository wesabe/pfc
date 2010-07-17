require 'builder'

class Builder::XmlMarkup

  def dasherize!
    @dasherize = true
  end

  def undasherize!
    @dasherize = false
  end

private

  def _start_tag_with_dasherize(sym, attrs, end_too=false)
    sym = sym.to_s.dasherize if @dasherize
    _start_tag_without_dasherize(sym, attrs, end_too)
  end
  alias_method_chain :_start_tag, :dasherize

  def _end_tag_with_dasherize(sym)
    sym = sym.to_s.dasherize if @dasherize
    _end_tag_without_dasherize(sym)
  end
  alias_method_chain :_end_tag, :dasherize

end
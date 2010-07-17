xml = ::Builder::XmlMarkup.new(:indent => params[:compact] ? 0 : 2)
xml.dasherize!
xml.instruct!
xml.txactions(:type => "array") do
  @txactions.each do |txaction|
    txaction_to_xml(xml, txaction, params.merge(:skip_instruct => true, :include_account => true, :concise => true))
  end
end

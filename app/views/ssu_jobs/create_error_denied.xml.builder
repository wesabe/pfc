xml.instruct!
xml.dasherize!
xml.error do
  xml.message "The last job run for these credentials was denied by the financial institution."
  @job.write_to_xml(xml)
end

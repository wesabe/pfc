xml.instruct!
xml.dasherize!
xml.error do
  xml.message "The last job run for these credentials is still running."
  @job.write_to_xml(xml)
end

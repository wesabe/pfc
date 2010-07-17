xml.dasherize!
xml.instruct!
xml.jobs do
  @jobs.each do |job|
    job.write_to_xml(xml)
  end
end

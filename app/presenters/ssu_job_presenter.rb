class SsuJobPresenter < SimplePresenter
  def status
    if pending?
      'pending'
    elsif successful?
      'successful'
    elsif failed?
      'failed'
    else
      'unknown'
    end
  end

  def write_to_xml(xml)
    xml.job do
      export_data.each do |k, v|
        xml.tag!(k, v)
      end
    end
  end

  def as_json(options=nil)
    {:id => jobid,
     :uri => credential_job_path(account_cred, presentable),
     :status => status,
     :result => result,
     :version => version,
     :created_at => created_at,
     :data => data}
  end
end

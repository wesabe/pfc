class SsuJobPresenter < PresenterBase
  attr_accessor :job

  def initialize(job)
    @job = job
  end

  def status
    if job.pending?
      'pending'
    elsif job.successful?
      'successful'
    elsif job.failed?
      'failed'
    else
      'unknown'
    end
  end

  def result
    job.result
  end

  def jobid
    job.jobid
  end

  def write_to_xml(xml)
    xml.job do
      export_data.each do |k, v|
        xml.tag!(k, v)
      end
    end
  end

  def to_json(options=nil)
    export_data.to_json
  end

  def to_internal_json
    internal_data.to_json
  end

  def export_data
    {:id => job.jobid,
     :status => status,
     :result => result,
     :created_at => job.created_at.utc.xmlschema}
  end

  def internal_data
    {:id => job.jobid,
     :status => job.status,
     :status_string => status,
     :result => job.result,
     :version => job.version,
     :created_at => job.created_at,
     :data => job.data }
  end
end

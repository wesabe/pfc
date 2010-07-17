class Exporter
  # render the converted data as a file
  def render(controller, filename)
    controller.response.headers['Content-Disposition'] = "attachment; filename=#{filename}"
    controller.send(:render, :text => convert, :content_type => content_type)
  end
end
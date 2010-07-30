require File.dirname(__FILE__) + '/../js_model/js_model_generator'

class JsWidgetGenerator < JsModelGenerator
  source_root File.expand_path('../templates', __FILE__)

  protected

  def prefix
    'wesabe.views.widgets'
  end

  def superclass_name
    'wesabe.views.widgets.BaseWidget'
  end
end

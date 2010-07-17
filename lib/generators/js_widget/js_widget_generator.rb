require File.dirname(__FILE__) + '/../js_model/js_model_generator'

class JsWidgetGenerator < JsModelGenerator
  protected

  def prefix
    'wesabe.views.widgets'
  end

  def superclass_name
    'wesabe.views.widgets.BaseWidget'
  end
end

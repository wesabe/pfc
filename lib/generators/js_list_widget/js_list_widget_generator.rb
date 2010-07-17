require File.dirname(__FILE__) + '/../js_widget/js_widget_generator'

class JsListWidgetGenerator < JsWidgetGenerator
  protected

  def superclass_name
    'wesabe.views.widgets.BaseListWidget'
  end
end

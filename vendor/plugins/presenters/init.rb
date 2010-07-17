module Presenters
  extend self
  
  def wrap(klass, method)
    return unless klass.instance_methods.include?(method.to_s)
    
    klass.class_eval <<-end_eval
      def #{method}_with_presenters(*args, &block)
        PresenterBase.view = self
        self.#{method}_without_presenters(*args, &block)
      end
      
      alias_method_chain :#{method}, :presenters
    end_eval
  end
end

# Rails 2.0
Presenters.wrap(ActionView::Base, :render)
Presenters.wrap(ActionView::Base, :render_file)
Presenters.wrap(ActionView::Base, :render_template)
 
# Rails 2.1+
Presenters.wrap(ActionView::Base, :execute)

module Sluggability::ModelMethods
  module ClassMethods
    def slug(name_method=:name, options={})
      #
      # construct the to_param method
      #  
      define_method :to_param do
        param = id.to_s
        if respond_to?(name_method) && name = send(name_method)
          s = Sluggability.make_slug(name)
          param << "-#{s}" unless s.blank?
        end
        param
      end
    end
  end
  
  extend ClassMethods
  
  def self.included(receiver)
    receiver.extend(ClassMethods)
  end
  
  
end

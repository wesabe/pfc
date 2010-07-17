require "sluggability"

ActiveRecord::Base.send(:include, Sluggability::ModelMethods)
ActionController::Base.send(:include, Sluggability::ControllerMethods)
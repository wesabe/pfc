require "pp"
require "active_support"

def missing_spec_report(missing, class_name)
  if missing.any?
    if missing.size == 1
      puts "1 #{class_name} does not have a spec:"
    else
      puts "#{missing.size} #{class_name.pluralize} do not have specs:"
    end
    puts missing.map { |c| "  * #{c}" }.join("\n")
  end
  @total_missing_count += missing.size if @total_missing_count
end

namespace :spec do

  desc "Find all missing specs, based on filenames."
  task :missing do
    @total_missing_count = 0
    Rake::Task["spec:missing:models"].invoke
    Rake::Task["spec:missing:controllers"].invoke
    Rake::Task["spec:missing:helpers"].invoke
    Rake::Task["spec:missing:views"].invoke
    Rake::Task["spec:missing:libraries"].invoke
    puts "Total missing specs: #{@total_missing_count}"
  end

  namespace :missing do

    task :controllers do
      @controllers_missing_specs = []
      for controller_file in Dir["app/controllers/**/*.rb"]
        controller_file.gsub!("app/controllers/", "")
        controller_file.gsub!(/\.rb$/, "")
        unless File.exist?("spec/controllers/#{controller_file}_spec.rb")
          @controllers_missing_specs << controller_file.classify
        end
      end
      missing_spec_report(@controllers_missing_specs, "controller")
    end

    task :models do
      @models_missing_specs = []
      for model_file in Dir["app/models/**/*.rb"]
        model_file.gsub!("app/models/", "")
        model_file.gsub!(/\.rb$/, "")
        unless File.exist?("spec/models/#{model_file}_spec.rb")
          @models_missing_specs << model_file.classify
        end
      end

      missing_spec_report(@models_missing_specs, "model")
    end

    task :helpers do
      @helpers_missing_specs = []
      for helper_file in Dir["app/helpers/**/*.rb"]
        helper_file.gsub!("app/helpers/", "")
        helper_file.gsub!(/\.rb$/, "")
        unless File.exist?("spec/helpers/#{helper_file}_spec.rb")
          @helpers_missing_specs << helper_file.classify
        end
      end

      missing_spec_report(@helpers_missing_specs, "helper")
    end

    task :libraries do
      @libraries_missing_specs = []
      for library_file in Dir["lib/**/*.rb"]
        library_file.gsub!("lib/", "")
        library_file.gsub!(/\.rb$/, "")
        unless File.exist?("spec/lib/#{library_file}_spec.rb")
          @libraries_missing_specs << library_file.classify
        end
      end

      missing_spec_report(@libraries_missing_specs, "library")
    end

    task :views do
      @views_missing_specs = []
      for view_file in Dir["app/views/**/*.{rhtml,rxml,erb,builder}"]
        view_file.gsub!("app/views/", "")
        unless File.exist?("spec/views/#{view_file.sub('.', "_")}_spec.rb")
          @views_missing_specs << view_file
        end
      end
      missing_spec_report(@views_missing_specs, "view")
    end

  end

end
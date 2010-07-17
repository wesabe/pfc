if Service.config.nil?
  raise "No services.yml configuration file found or no configuration for #{RAILS_ENV} environment found"
end
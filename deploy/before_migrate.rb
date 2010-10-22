%w[ssu-service.yml services.yml].each do |file|
  run "ln -nfs #{shared_path}/config/#{file} #{release_path}/config/#{file}"
end
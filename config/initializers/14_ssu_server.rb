path = Rails.root.join('config', 'ssu-service.yml')

unless path.exist?
  $stderr.puts "Cannot find ssu-service.yml configuration file, please run rake config."
  exit(1)
end

config = YAML.load_file(path)
uris = config['uris']
unless uris && uris['pfc'] && uris['ssu']
  $stderr.puts "Cannot find URI configuration in ssu-service.yml, please run rake config."
  exit(1)
end

SSU_URI = uris['ssu']
PFC_URI = uris['pfc']

priv = uris['internal']
unless priv && priv['pfc'] && priv['ssu']
  $stderr.puts "Cannot find internal URI configuration in ssu-service.yml, please run rake config."
  exit(1)
end

SSU_INTERNAL_URI = priv['ssu']
PFC_INTERNAL_URI = priv['pfc']
require 'yaml'
require 'readline'

PFC_CONFIG_DIR = '/etc/pfc'
PFC_CONFIG_FILES = {
  :'ssu-service' => 'ssu-service.yml'
}

class Object
  def blank?
    false
  end
end

class NilClass
  def blank?
    true
  end
end

class String
  def blank?
    self =~ /\A\s*\Z/
  end
end

class Array
  def blank?
    empty?
  end
end

def config_path(file=nil)
  case file
  when nil
    PFC_CONFIG_DIR
  when Symbol
    config_path PFC_CONFIG_FILES[file]
  when String
    File.join(PFC_CONFIG_DIR, file)
  end
end

def config_hash_for(file)
  path = config_path(file)
  config = YAML.load_file(path) if File.exist?(path)
  config ||= {}
end

def write_config_hash_for(file, config)
  File.open(config_path(file), 'w') do |f|
    f << config.to_yaml
  end
end

def readline_with_default(prompt, default)
  case default
  when TrueClass
    prompt = "#{prompt} [nY]"
  when FalseClass
    prompt = "#{prompt} [yN]"
  else
    prompt = "#{prompt} [#{default}]" unless default.blank?
  end

  result = Readline.readline("#{prompt} ")
  return default if result.blank?

  case default
  when TrueClass, FalseClass
    result =~ /y/i
  when Fixnum
    result.to_i
  else
    result
  end
end

namespace :config do
  task 'base' do
    sh("sudo mkdir -p #{PFC_CONFIG_DIR}") unless File.directory?(PFC_CONFIG_DIR)
    sh("sudo chown -R #{ENV['USER']} #{PFC_CONFIG_DIR}") unless File.owned?(PFC_CONFIG_DIR)
  end

  task 'ssu-service' => %w[config:base] do
    puts "** Configuring PFC to work with SSU Service"

    config = config_hash_for(:'ssu-service')
    uris = (config['uris'] ||= {})
    priv = (uris['internal'] ||= {})

    pfc = uris['pfc'] || "https://www.wesabe.com/"
    ssu = uris['ssu'] || "https://ssu.wesabe.com/"

    pfc = readline_with_default("What URL should PFC use for PFC?", pfc)
    ssu = readline_with_default("What URL should PFC use for SSU?", ssu)

    uris['pfc'] = pfc
    uris['ssu'] = ssu

    pfc = priv['pfc'] || pfc
    ssu = priv['ssu'] || ssu

    pfc = readline_with_default("What URL should PFC use internally for PFC?", pfc)
    ssu = readline_with_default("What URL should PFC use internally for SSU?", ssu)

    priv['pfc'] = pfc
    priv['ssu'] = ssu

    write_config_hash_for(:'ssu-service', config)
  end
end

desc "Guides you through configuring the application"
task :config => %w[config:ssu-service]
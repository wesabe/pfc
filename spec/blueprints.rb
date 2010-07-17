require 'machinist/active_record'
require 'sham'
require 'faker'

Dir.glob(File.expand_path('../blueprints/*.rb', __FILE__)).each {|file| require file }
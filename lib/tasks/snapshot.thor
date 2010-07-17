require File.join(File.dirname(__FILE__), '..', '..', 'config', 'environment')

class Snapshot < Thor
  desc 'import', 'import Wesabe snapshot'
  method_options %w(verbose -v) => :boolean
  def import(filepath)
    Importer::Wesabe.import(filepath, options)
  end
end
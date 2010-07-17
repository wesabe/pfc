require File.join(File.dirname(__FILE__), '..', 'asset_manifest')

class JavaScriptAssetManifest < AssetManifest
  JAVASCRIPTS_DIR = Rails.root.join('public', 'javascripts')
  MANIFESTS_DIR = JAVASCRIPTS_DIR.join('manifests')

  def rolled_filename
    "#{@manifest}-rolled.js"
  end

  def rolled_filepath
    JAVASCRIPTS_DIR.join(rolled_filename)
  end

  # Roll files together into a single file. Adds whitespace to avoid problems.
  def roll_files
    rolled_filepath.open('w+') do |out|
      self.files.each { |f| out << JAVASCRIPTS_DIR.join(f).read << "\n\n\n" }
    end
  end

  def self.asset_dir
    JAVASCRIPTS_DIR
  end

  def self.manifests_dir
    MANIFESTS_DIR
  end
end

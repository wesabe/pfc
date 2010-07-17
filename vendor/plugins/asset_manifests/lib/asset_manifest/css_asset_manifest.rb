require File.join(File.dirname(__FILE__), '..', 'asset_manifest')

# TODO: handle media types other than the default, screen
class CSSAssetManifest < AssetManifest
  STYLESHEETS_DIR = Rails.root.join('public', 'stylesheets')
  MANIFESTS_DIR = STYLESHEETS_DIR.join('manifests')

  def rolled_filename
    "#{@manifest}-rolled.css"
  end

  def rolled_filepath
    STYLESHEETS_DIR.join(rolled_filename)
  end

  # Roll files together into a single file. Adds whitespace to avoid problems.
  def roll_files
    rolled_filepath.open('w+') do |out|
      self.files.each { |f| out << STYLESHEETS_DIR.join(f).read << "\n\n\n" }
    end
  end

  def self.asset_dir
    STYLESHEETS_DIR
  end

  def self.manifests_dir
    MANIFESTS_DIR
  end
end

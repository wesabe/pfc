class AssetManifest
  def initialize(manifest)
    @manifest = manifest.to_s
  end

  def name
    @manifest
  end

  def files(rolled = false)
    if rolled
      @files ||= [rolled_filename]
    else
      @files ||= begin
        list = YAML::load_file(self.class.manifests_dir.join(@manifest + '.yml'))
        list.map { |item|
          item = self.class.asset_dir.join(item)
          items = Dir.glob(item).sort
          items.map do |file|
            file = file[self.class.asset_dir.to_s.size..-1]
            file[1..-1] if file[0,1] == '/'
          end
        }.flatten
      end
    end
  end

  # convenience method
  def self.roll_files(manifest)
    if manifest == :all
      manifests.each {|m| m.roll_files }
    else
      new(manifest).roll_files
    end
  end

  def unroll_files
    File.delete(rolled_filepath)
  end

  def self.unroll_files(manifest)
    if manifest == :all
      manifests.each {|m| m.unroll_files }
    else
      new(manifest).unroll_files
    end
  end

  # return list of all manifests
  # manifests_dir needs to be defined by the subclass
  def self.manifests
    @manifests = nil if defined?(::Rails) && !::Rails.env.production?
    @manifests ||= manifests_dir.entries.map {|f| f.to_s =~ /(.*?)\.yml$/ && new($1) }.compact
  end
end

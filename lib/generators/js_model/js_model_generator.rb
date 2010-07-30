class JsModelGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  def manifest
    inside "public/javascripts" do
      empty_directory package_path
      template 'model.js', file_path
    end
  end

  protected

  def name
    @js_class_name ||= generate_name(@name)
  end

  def generate_name(partial_name)
    prefix_parts       = prefix.split('.')
    partial_name_parts = partial_name.split('.')

    prefix_parts.size.downto(0) do |size|
      if prefix_parts.last(size) == partial_name_parts.first(size)
        return (prefix_parts.first(prefix_parts.size - size) + partial_name_parts).join('.')
      end
    end
  end

  def prefix
    'wesabe'
  end

  def name_parts
    @name_parts ||= name.split('.')
  end

  def class_name
    name_parts.last
  end

  def file_name
    name_parts.last + '.js'
  end

  def file_path
    File.join(package_path, file_name)
  end

  def package_path
    name_parts[0..-2].join('/')
  end

  def package_name
    name_parts[0..-2].join('.')
  end

  def superclass_name
    nil
  end

  def has_superclass?
    not superclass_name.nil?
  end
end

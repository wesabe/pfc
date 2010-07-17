module ImageProcessing
  def self.image_directory
    "/var/wesabe/images"
  end

  MAX_SIZE = 2.megabytes
  VALID_EXTENSIONS = %w{ JPEG JPG GIF PNG }
  VALID_CONTENT_TYPES = %w{ image/gif image/jpeg image/png }

  class ImageSizeExceeded < RuntimeError; end
  class InvalidContentType < RuntimeError; end

  module ClassMethods
    def has_image(options = {})
      options[:column] ||= :image_key
      include ImageProcessing::InstanceMethods
      cattr_accessor :image_options
      self.image_options = options
      cattr_accessor :image_key_column
      self.image_key_column = options[:column]
      cattr_accessor :image_subdirectory
      self.image_subdirectory = options[:subdirectory] || self.to_s.underscore.pluralize
      cattr_accessor :default_image_path
      self.default_image_path = options[:default]
      validates_uniqueness_of image_key_column, :allow_nil => true
      before_save :process_image
      after_destroy :delete_images
      attr_reader :image_file
      validate :validate_image_file
    end

  protected

    def imp_setup_validation

    end

  end

  module InstanceMethods
    def image_key
      read_attribute self.class.image_key_column
    end

    def image_key=(key)
      write_attribute self.class.image_key_column, key
    end

    # A setter for the uploaded image file. Allows for the use of create, new, and update_attributes.
    #
    # Examples:
    #   (in the view)
    #     <%= file_field :user, :image_file %>
    #
    #   (in the controller)
    #     @user.update_attributes(params[:user])
    def image_file=(new_image_file)
      if new_image_file.respond_to?(:original_filename) && new_image_file.respond_to?(:content_type) &&
        new_image_file.respond_to?(:size) && new_image_file.size > 0
        @image_file = new_image_file
      else
        @image_file = nil
      end
    end

    def image_file?
      !@image_file.nil?
    end

    def image_ext
      File.extname(@image_file.original_filename)[1..-1] if @image_file
    end

    # Returns the name of the associated image file.
    #
    # Examples:
    #
    #   image_name(:original)     #=> "2fszuxhpop.original.jpg"
    #   image_name(:thumbnail)    #=> "2fszuxhpop.thumbnail.jpg"
    def image_name(flavor = :original, ext = nil)
      if ext
        "#{image_key}.#{flavor}.#{ext}"
      else
        file = Dir.glob(full_image_path(flavor, '*')).first
        File.basename(file) if file
      end
    end

    # Returns the path of the associated image file, relative to the /images directory. If the record doesn't have an
    # image key, returns nil.
    #
    # Examples:
    #
    #   group.image_path(:original)             #=> "groups/2fszuxhpop.original.jpg"
    def image_path(flavor = :original, ext = nil)
      if image_key
        name = image_name(flavor, ext)
        return File.join(image_subdirectory, name) if name
      end

      return default_image_path
    end

    # Returns the full path of the associated image file. If the record doesn't have an image key, returns nil.
    def full_image_path(flavor = :original, ext = nil)
      image_key ? File.join(ImageProcessing.image_directory, image_path(flavor, ext)) : nil
    end

  protected

    def validate_image_file
      if image_file?
        errors.add(:image_file, "is too large (#{"%.2f" % (image_file.size.to_f / 1.megabyte)}MB). The maximum size is #{MAX_SIZE / 1.megabyte}MB.") if image_file.size > MAX_SIZE
        content_type = image_file.content_type
        unless VALID_CONTENT_TYPES.include?(content_type && content_type.strip) && VALID_EXTENSIONS.include?(image_ext.upcase)
          errors.add(:image_file, "is an unrecognized format (.#{image_ext}). We accept #{VALID_EXTENSIONS.to_sentence} files only.")
        end
      end
    end

    def save_original_image
      returning File.join(ImageProcessing.image_directory, image_path(:original, image_ext)) do |original_filename|
        File.open(original_filename, "wb+") { |f| f << image_file.read }
      end
    end

    def process_image
      if image_file?

        FileUtils.mkdir_p(File.join(ImageProcessing.image_directory, image_subdirectory))

        delete_images

        self.image_key = ActiveSupport::SecureRandom.hex(16)

        original_filename = save_original_image

        if image_options[:processor]
          image_options[:processor].process_image(original_filename)
        end

      end
    end

    def delete_images
      if image_key
        Dir.glob(File.join(ImageProcessing.image_directory, image_path("*", "*"))).each do |file|
          File.unlink(file) rescue nil
        end
      end
    end

  end
end

class ActiveRecord::Base
  extend ImageProcessing::ClassMethods
end

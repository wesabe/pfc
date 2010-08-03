# Creates small, square versions of images.
#
#   has_image :processor => ImageProcessing::Thumbnailer.new(48)
#   has_image :processor => ImageProcessing::Thumbnailer.new(:thumbnail => 32, :profile => 100)
class ImageProcessing::Thumbnailer
  def initialize(options)
    if options.is_a?(Fixnum)
      @options = { :thumbnail => options }
    else
      @options = options
    end
  end

  def process_image(infile)
    for flavor, size in @options
      outfile = File.change_extname(infile.sub(".original", ""), ".#{flavor}.png")
      Rails.logger.debug "Saving a #{flavor} version of #{infile} to #{outfile}..."
      system "./script/images/thumbnail", "--size=#{size}", infile, outfile
      Rails.logger.debug "... #{$?.success? ? 'OK' : "FAIL ($?=#{$?.exitstatus})"}"
    end
  end
end

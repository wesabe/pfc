require "zlib"

class String
  def to_gz
    output = ::StringIO.new
    gz = ::Zlib::GzipWriter.new(output)
    gz << self
    gz.close
    return output.string
  end
  
  def from_gz
    ungzipped_data = ""
    ::StringIO.open(self, "r") do |s|
      gz = ::Zlib::GzipReader.new(s)
      ungzipped_data = gz.read
      gz.close
    end
    return ungzipped_data
  end
end
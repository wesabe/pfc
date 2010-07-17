# This class encapsulates the generation of secure, temporary, writeable file
# paths for storing temporary data on disk. Use this instead of using
# +Tempfile+ directly since +Tempfile+ deletes the file and removes the path
# from the +Tempfile+ instance when you close it. Use it like so:
#
#     temppath = TempfilePath.generate
#     File.open(temppath, 'w') {|f| f << data}
#     # do something with temppath
#
class TempfilePath
  def initialize(basename=nil, tmpdir=nil)
    basename ||= 'tempfilepath'
    file = tmpdir ? Tempfile.new(basename, tmpdir) : Tempfile.new(basename)
    @path = file.path
    file.close! # make sure we delete the file now, not at some random time down the road (thanks, Tempfile!)
  end

  def to_s
    @path
  end

  def to_str
    @path
  end

  def self.generate(basename=nil, tmpdir=nil)
    new(basename, tmpdir).to_s
  end
end

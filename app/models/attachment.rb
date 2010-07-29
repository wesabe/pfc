require 'pathname'

class Attachment < ActiveRecord::Base
  belongs_to :user, :foreign_key => 'account_key', :primary_key => 'account_key'
  has_many :txaction_attachments, :dependent => :destroy

  validates_presence_of :filename

  # delete the attached file when we delete the attachment
  after_destroy :unlink

  BASE_DIR = Pathname(File.join(ApiEnv::FILE_PATH, 'attachments'))
  MAX_SIZE = 2.megabytes

  class MaxSizeExceeded < Exception; end

  def open(*args, &block)
    filepath.parent.mkpath
    filepath.open(*args, &block)
  end

  # read and return the attachment data
  def read
    filepath.read
  end

  def unlink
    filepath.unlink if filepath.exist?
  end

  # return full filepath of this attachment
  def filepath
    filedir.join(guid)
  end

  # return the directory in which the attachment is stored
  def filedir
    BASE_DIR.join(guid[0..1], guid[2..3])
  end

  def display_name
    description.blank? ? filename : description
  end

  def to_param
    guid
  end

  # given file data and a filename, save the data and create an Attachment
  def self.generate(user, params)
    filename = params[:filename] || (params[:data].respond_to?(:original_filename) ? params[:data].original_filename : 'no_filename')

    if params[:data].size > MAX_SIZE
     raise MaxSizeExceeded,
           "Attachment '#{filename}' (#{params[:data].size} bytes) exceeded the maximum upload size of #{MAX_SIZE} bytes."
    end

    # generate guid
    begin
      guid = ActiveSupport::SecureRandom.hex(32)
    end while Attachment.find_by_guid(guid)

    unless content_type = params[:content_type]
      if content_type = MIME::Types.type_for(filename)[0]
        content_type = content_type.content_type
      else
        content_type = 'application/octet-stream'
      end
    end

    attachment = user.attachments.create(
                  :filename => filename,
                  :description => params[:description],
                  :guid => guid,
                  :content_type => content_type.strip, # until this gets applied: http://dev.rubyonrails.org/ticket/9053
                  :size => params[:data].size)

    # save the file
    params[:data] = params[:data].read if params[:data].respond_to?(:read)
    attachment.open('w') {|f| f << params[:data] }

    return attachment
  end

  # create a zip file containing the attachments provided. The attachments are placed within a directory named
  # after the basename of the provided filename. The return value is the filename of the tempfile
  # REVIEW: the zip file creation could be generalized and moved into its own
  # library. We'll wait until we have other things to zip.
  def self.create_zip_file(filename, attachments)
    temppath = TempfilePath.generate('zip')
    Zip::ZipOutputStream::open(temppath) do |io|
      filename_hash = Hash.new(0) # keep track of filenames so we can rename duplicates
      dir = File.basename(filename, ".*") + "/" # put files in a directory named after the file
      # create a directory the hard way because rubyzip was written by monkeys
      dir_entry = Zip::ZipStreamableDirectory.new(temppath, dir, nil, 0755)
      io.put_next_entry(dir_entry)
      attachments.each do |attachment|
        filename_hash[attachment.filename] += 1
        entry_filename =
          if filename_hash[attachment.filename] > 1
            File.basename(attachment.filename, ".*") + "-#{filename_hash[attachment.filename]}" +
              File.extname(attachment.filename)
          else
            attachment.filename
          end

        io.put_next_entry(dir + entry_filename)
        io.write(attachment.read)
      end
    end
    return temppath
  end
end

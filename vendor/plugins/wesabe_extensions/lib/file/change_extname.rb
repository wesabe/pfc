class File
  # Change the file extension of a filename.
  # 
  # Examples:
  # 
  #   File.change_extname("/var/www/example.com/index.html", ".shtml") #=> "/var/www/example.com/index.shtml"
  #   File.change_extname("/var/www/example.com/index.html", :txt)     #=> "/var/www/example.com/index.txt"
  def self.change_extname(filename, extension)
    extension = extension.to_s
    extension = extension =~ /^\./ ? extension : ".#{extension}"
    File.join(File.dirname(filename), "#{File.basename(filename, File.extname(filename))}#{extension}")
  end
end
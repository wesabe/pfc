#!/usr/bin/env ruby

# script to import ofx data files
# takes either a filename or a directory as a parameter
# if a directory is provided, it will parse all .ofx files
# in the directory recursively

# make sure we're not hitting the production database accidentally
ENV["RAILS_ENV"] ||= 'development'
require File.dirname(__FILE__) + '/../config/environment'
require File.dirname(__FILE__) + '/../lib/ofx2importer'

# check for arguments
if !path=ARGV[0]
  puts "You must specify a filename or directory to parse."
  exit
end

if !FileTest.exists?(path)
  puts "File or directory '#{path}' not found."
  exit
end

importer = OFX2Importer.new(:verbose => true)

if FileTest.file?(path)
  importer.import(File.new(path))
else
  fixed_path = path.gsub(/[\/]+$/,'') # strip trailing slashes
  Dir["#{fixed_path}/**/*.ofx"].each do | file |
    importer.import(File.new(file))
  end
end

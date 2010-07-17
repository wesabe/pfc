require 'spec_helper'

describe Attachment do
  before do
    @user = User.make
    @params = {:filename => 'test.txt',
              :description => 'Test Attachment',
              :data => 'test attachment contents'}
    @attachment = Attachment.generate(@user, @params)
  end

  it "creates a new attachment for a given user" do
    @attachment.should be_valid
    @attachment.content_type.should == 'text/plain'
    @attachment.filepath.size.should == @attachment.size
  end

  it "should delete the associated file when an attachment is destroyed" do
    lambda { @attachment.destroy }.
      should change { @attachment.filepath.exist? }.from(true).to(false)
  end
end

describe Attachment, "creating a zip file" do
  before do
    @attachment = Attachment.make
    @attachments = [ @attachment ]
    @attachment.open('w') {|f| f << 'omgattachmentdata' }
  end

  it "should return a zip file" do
    zip_file = Attachment.create_zip_file("foo", @attachments)
    File.read(zip_file).should match(/^\x50\x4B\x03\x04/) # signature for a zip file
    File.delete(zip_file)
  end
end
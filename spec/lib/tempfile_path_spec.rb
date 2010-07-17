require 'spec_helper'

describe TempfilePath do
  before do
    @tempfile = stub(:tempfile, :path => '/tmp/myprefix/foo', :close! => nil)
  end

  it "uses Tempfile to generate a temporary file path" do
    Tempfile.should_receive(:new).with("myprefix").and_return(@tempfile)
    TempfilePath.generate("myprefix")
  end

  it "allows passing a custom temporary directory" do
    Tempfile.should_receive(:new).with("myprefix", "/private/tmp").and_return(@tempfile)
    TempfilePath.generate("myprefix", '/private/tmp')
  end

  it "returns a temporary file path suitable for writing" do
    path = TempfilePath.generate
    begin
      File.open(path, 'w') {|f| f << 'foo'}
      File.read(path).should == 'foo'
    ensure
      File.unlink(path) if File.exist?(path)
    end
  end
end

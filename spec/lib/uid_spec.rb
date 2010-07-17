require 'spec_helper'

describe UID do
  it "should generate a 10-character alphanumeric string" do
    UID.generate.should match(/\A[A-Za-z0-9]{10}\Z/)
  end
end
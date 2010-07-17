require 'spec_helper'

describe PresenterBase do
  before do
    @presenter = PresenterBase.new
  end

  describe "#presenter" do
    it "returns self" do
      @presenter.presenter.should == @presenter
    end
  end
end

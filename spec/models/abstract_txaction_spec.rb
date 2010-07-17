require 'spec_helper'

describe AbstractTxaction do
  it_should_behave_like "it has a logged-in user"

  describe "visible? method" do
    before do
      @txaction = Txaction.make
    end

    it "should return true if the transaction is ACTIVE" do
      @txaction.status = Constants::Status::ACTIVE
      @txaction.should be_visible
    end

    it "should return true if the transaction is PENDING" do
      @txaction.status = Constants::Status::PENDING
      @txaction.should be_visible
    end

    it "should return false if the transaction is DELETED" do
      @txaction.status = Constants::Status::DELETED
      @txaction.should_not be_visible
    end

    it "should return false if the transaction is DISABLED" do
      @txaction.status = Constants::Status::DISABLED
      @txaction.should_not be_visible
    end
  end
end
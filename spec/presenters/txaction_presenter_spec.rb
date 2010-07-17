require 'spec_helper'

describe TxactionPresenter do
  it_should_behave_like "it has a logged-in user"

  before do
    @txaction = Txaction.make
    @txaction.tag_with("foo bar")
    renderer = mock_model(Object)
    @presenter = TxactionPresenter.new(@txaction, renderer)
  end

  describe "brcm_hash_without_transfer" do
    it "should output the transaction's tags" do
      @presenter.brcm_hash_without_transfer.should match_insecure_json(
        hash_including("tags" => [
          {"name" => "foo", "uri" => "/tags/foo"},
          {"name" => "bar", "uri" => "/tags/bar"}]))
    end
  end
end
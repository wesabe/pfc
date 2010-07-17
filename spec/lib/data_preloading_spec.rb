require 'spec_helper'

describe DataPreloading do
  include DataPreloading

  def stub_accounts_request(returns)
    stub_request(:get, 'services.test:8080/v2/accounts/accounts/all/USD?include_archived=true').
      to_return(returns)
  end

  def current_user
    @current_user ||= User.make
  end

  def content_for(what, content=nil)
    content = yield if block_given?
    content_hash[what] << content if content
  end

  def content_hash
    @content_hash ||= Hash.new {|h,k| h[k] = ''}
  end

  describe "#preload_accounts" do
    before do
      @request = Service::Request.new('')
      @successful_response = Service::Response.new(200, {}, '{}', 'application/json')
      @failed_response = Service::Response.new(500, {}, 'FAIL', 'text/html')
    end

    describe "successfully requested" do
      before do
        stub_accounts_request :body => '{"accounts":[]}'
      end

      it "writes out the response as the account data in a script tag" do
        preload_accounts
        content_hash[:footer].should == <<-END
<script type="text/javascript">
  wesabe.ready("wesabe.data.accounts.sharedDataSource.setData", function() {
    wesabe.data.accounts.sharedDataSource.setData({"accounts": []});
  });
</script>
END
      end
    end

    describe "unsuccessfully requested" do
      before do
        stub_accounts_request :status => [500, 'Internal Server Error']
      end

      it "does not write anything to the page" do
        preload_accounts
        content_hash[:footer].should be_blank
      end
    end

    describe "when users put tags in their account names" do
      before do
        stub_accounts_request :body => %{{"accounts":[{"name":"<script>alert('evil!');</script>"}]}}
      end

      it "should escape names to prevent XSS" do
        preload_accounts
        content_hash[:footer].should == <<-END
<script type="text/javascript">
  wesabe.ready("wesabe.data.accounts.sharedDataSource.setData", function() {
    wesabe.data.accounts.sharedDataSource.setData({\"accounts\": [{\"name\": \"\\u003Cscript\\u003Ealert('evil!');\\u003C/script\\u003E\"}]});
  });
</script>
        END
      end
    end
  end
end

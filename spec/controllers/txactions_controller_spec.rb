require 'spec_helper'

describe TxactionsController do
  describe "handling POST /create" do
    it_should_behave_like "it has a logged-in user"

    before do
      @manual_account = Account.make(:manual, :user => current_user)
      @checking_account = Account.make(:checking, :user => current_user)
    end

    describe "to a manual account" do
      it "allows txactions to be created" do
        lambda {
          post :create,
               :account_id => @manual_account.to_param,
               :amount_type => "spent",
               :date_posted => "09/27/2008",
               :merchant_name => "Ace Parking",
               :amount => "5"
        }.should change(Txaction, :count).by(1)

        tx = Txaction.latest
        tx.account.should == @manual_account
        tx.merchant_name.should == "Ace Parking"
        tx.amount.should == -5.to_d
      end

      it "can handle a MM/DD date format" do
        lambda {
          post :create,
               :account_id => @manual_account.to_param,
               :rating => "1",
               :amount_type => "spent",
               :date_posted => "09/27",
               :tags => "Parking Deductible",
               :inbox_attachments => "",
               :merchant_name => "Ace Parking",
               :amount => "5",
               :note => ""
        }.should change(Txaction, :count).by(1)

        txaction = Txaction.latest
        txaction.date_posted.should == Time.parse("09/27")
      end

      it "should not allow a date with a year > 9999" do
          post :create,
               :account_id => @manual_account.to_param,
               :rating => "1",
               :amount_type => "spent",
               :date_posted => "20087-11-15",
               :tags => "Parking Deductible",
               :inbox_attachments => "",
               :merchant_name => "Ace Parking",
               :amount => "5",
               :note => ""
          flash[:error].should match(/could not parse the date/)
      end
    end

    it "saves notes even if there aren't tags" do
      lambda {
        post :create,
             :account_id => @manual_account.to_param,
             :rating => "1",
             :amount_type => "spent",
             :date_posted => "09/27",
             :tags => "",
             :inbox_attachments => "",
             :merchant_name => "A New Hope",
             :amount => "5",
             :note => "Notes are fun"
      }.should change(Txaction, :count).by(1)

      tx = Txaction.last
      tx.note.should == "Notes are fun"
    end

    describe "to a non-manual account" do
      it "should not allow txactions to be created" do
        post 'create', :account_id => @checking_account.to_param, :date_posted => '2008-01-01'
        assigns[:txaction].should be_nil
      end
    end

    describe "a json request" do
      it "returns json" do
        request.accept = "application/json"
        post :create, :account_id => @manual_account.to_param, :merchant_name => "Bob's Big Boy", :date_posted => '2009-02-26'
        response.should be_success
        response.content_type.should == "application/json"
        response.body.should match_json({
          "guid" => Txaction.last.guid,
          "merchant" => {"name" => "Bob's Big Boy", "id" => Txaction.last.merchant.id},
          "date" => "2009/02/26",
          "original_date" => "2009/02/26",
          "display_name" => "Bob's Big Boy",
          "account_id" => @manual_account.id_for_user,
          "raw_txntype" => "OTHER",
          "amount" => "0.00"
        })
      end
    end
  end

  describe "handling POST /update" do
    it_should_behave_like "it has a logged-in user"

    before do
      @account = Account.make(:user => current_user)
      @cash_account = Account.make(:cash, :user => current_user)
      @txaction = Txaction.make(:account => @account)
      @cash_txaction = Txaction.make(:account => @cash_account)
    end

    describe "a successful update" do
      it "modifies the Txaction based on the params" do
        post :update, :id => @txaction.to_param, :merchant_name => "Foo", :date_posted => '2008-01-01'
        assigns[:txaction].merchant.name.should == 'Foo'
        response.should be_success
      end
    end

    describe "where the txaction id is not owned by the user" do
      it "denies the user access" do
        @txaction2 = Txaction.make
        post :update, :id => @txaction2.to_param, :merchant_name => "Foo", :date_posted => '2008-01-01'
        response.should_not be_success
      end
    end

    it "should record the transaction tags" do
      post :update, :id => @txaction.to_param, :tags => "lunch biz", :merchant_name => "Irish Bank", :date_posted => '2008-01-01'
      assigns[:txaction].reload.tags.map(&:name).sort.should == %w[biz lunch]
    end

    describe "when the txaction is manual" do
      it "updates the amount given a valid amount" do
        post :update, :id => @cash_txaction.to_param, :amount => "1.95", :amount_type => "spent", :date_posted => '2008-01-01'
        @cash_txaction.reload.amount.to_d.should == -1.95.to_d
      end

      it "updates the date given a valid date" do
        post :update, :id => @cash_txaction.to_param, :date_posted => "2008-01-19"
        @cash_txaction.reload.date_posted.strftime("%Y-%m-%d").should == "2008-01-19"
      end
    end

    describe "when the txaction is a check" do
      before do
        Merchant.delete_all
        @txaction.update_attributes(:check_num => "1096", :raw_name => "CHECK #00000001096")
      end

      it "should mark unedited checks as unedited" do
        post :update, :id => @txaction.to_param, :merchant_name => "Check #00000001096", :date_posted => '2008-01-01'
        assigns[:txaction].merchant.should be_unedited
      end

      it "should not mark edited checks as unedited" do
        post :update, :id => @txaction.to_param, :merchant_name => "Mr. Woo", :date_posted => '2008-01-01'
        assigns[:txaction].merchant.should_not be_unedited
      end
    end

    describe "when the txaction does not edit independently" do
      before do
        @related_txactions = [ Txaction.make, Txaction.make ]
        @txaction.stub!(:update_independently?).and_return(false)
        @txaction.stub!(:find_related).and_return(@related_txactions)
      end

      describe "with a merchant name starting with !" do
        it "should force editing the merchant independently" do
          @related_txactions.each {|tx| tx.should_not_receive(:apply_autotags_for)}
          post :update, :id => @txaction.to_param, :merchant_name => '!Foo', :date_posted => '2008-01-01'
        end
        it "should not include the ! in the name" do
          post :update, :id => @txaction.to_param, :merchant_name => "!Foo", :date_posted => '2008-01-01'
          assigns[:txaction].merchant.name.should == "Foo"
        end
      end
    end

    describe "with file attachments" do
      it "posted file should be attached" do
        lambda {
          post :update,
               :id => @txaction.to_param,
               :tags => "foo",
               :merchant_name => "bar",
               :file_0 => fixture_file_upload('spec/fixtures/files/valid_image.jpg', 'image/jpeg'),
               :date_posted => '2008-01-01'
        }.should change { @txaction.reload.has_attachment? }.from(false).to(true)
      end
    end

    describe "a json request" do
      before do
        @json = {
          "guid" => @txaction.guid,
          "original_date" => Date.today,
          "date" => Date.today,
          "display_name" => @txaction.display_name(false),
          "account_id" => @txaction.account.id_for_user,
          "raw_txntype" => "DEBIT",
          "amount" => "-40.00",
          "raw_name" => proc{|raw_name| @txaction.raw_name.starts_with?(raw_name)}
        }
      end

      it "returns json wrapped in a textarea if not requested via XHR" do
        request.accept = "application/json"
        put :update, :id => @txaction.to_param
        response.should be_success
        # yes, this is right. because of the stupid iframe, if the content type is json, we get a popup window
        response.content_type.should == "text/html"
        txaction = response.body[%r{^<textarea>(.*)</textarea>$}, 1]
        txaction.should match_insecure_json(@json)
      end

      it "returns json if requested via XHR" do
        request.accept = "application/json"
        xhr :put, :update, :id => @txaction.to_param
        response.should be_success
        response.body.should match_json(@json)
      end
    end
  end

  describe "handling DELETE /transactions/:id" do
    it_should_behave_like "it has a logged-in user"

    def do_delete(params={})
      delete :destroy, params.reverse_merge(:id => @txaction.to_param)
    end

    context "given the id of a transaction the requesting user owns" do
      before do
        @account = Account.make(:checking, :user => current_user)
        @txaction = Txaction.make(:account => @account)
      end

      context "requested as HTML" do
        before do
          do_delete
        end

        it "is successful" do
          response.should be_success
        end
      end

      context "requested as JSON" do
        before do
          do_delete :format => 'json'
        end

        it "is successful" do
          response.should be_success
        end
      end
    end

    context "given the id of a transaction the requesting user does not own" do
      before do
        @txaction = Txaction.make
        current_user.can_edit_txaction?(@txaction).should be_false
      end

      it "is not successful" do
        do_delete
        response.should_not be_success
      end
    end
  end

  describe "PUT /txactions/:id/undelete" do
    it_should_behave_like "it has a logged-in user"

    context "given a deleted txaction that belongs to the user" do
      before do
        @account = Account.make(:checking, :user => current_user)
        @txaction = Txaction.make(:deleted, :account => @account)
      end

      it "undeletes the txaction" do
        lambda { put :undelete, :id => @txaction.id }.
          should change { @txaction.reload.active? }.
                  from(false).to(true)
      end
    end

    context "given a deleted txaction that doesn't belong to the user" do
      before do
        @txaction = Txaction.make(:deleted)
      end

      it "does not undelete the txaction" do
        lambda { put :undelete, :id => @txaction.id }.
          should_not change { @txaction.reload.active? }.
                      from(false)
      end
    end
  end

  describe "GET /txactions/on_select_merchant/:id" do
    it_should_behave_like "it has a logged-in user"

    context "with a valid transaction id and merchant name" do
      before do
        @merchant = Merchant.make
        # need at least one other person using a tag before it can be a suggested tag
        @accounts = [Account.make(:user => current_user), Account.make(:user => current_user), Account.make]
        @txactions = @accounts.map {|a| Txaction.make(:account => a, :merchant => @merchant)}
        @txactions.each {|t| t.tag_with("food:7") }
        @merchant_user = MerchantUser.find_by_merchant_id_and_user_id(@merchant.id, current_user.id)
      end

      it "returns JSON" do
        get :on_select_merchant, :id => @txactions[0].to_param, :name => @merchant.name, :format => 'json'
        response.body.should match_json({
          "id" => @merchant.id,
          "tags"=> nil,
          "suggested-tags" => [{"display"=>"food"}]
        })
      end

      context "but where the user has not used the merchant before" do
        before do
          @merchant_user.destroy
          @txactions[0].destroy
          @txactions[1].destroy
          @txaction = Txaction.make(:account => @accounts[0])
        end

        it "should omit the suggested-tags" do
          get :on_select_merchant, :id => @txaction.to_param, :name => @merchant.name, :format => 'json'
          response.body.should match_json(
            "id" => @merchant.id,
            "tags" => nil,
            "suggested-tags" => [] # there would be something here, but destroying the merchant_user made "food" unpopular
          )
        end
      end
    end

    context "with a non-existent transaction id" do
      it "is forbidden" do
        get :on_select_merchant, :id => 'new', :name => "Starbucks", :format => 'json'
        response.should be_forbidden
      end
    end
  end
end
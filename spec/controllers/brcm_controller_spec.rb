require 'spec_helper'

require 'exporter/txaction/csv'
require 'exporter/txaction/xls'

describe BrcmController do
  describe "GET /data/blah" do
    it "should connect to the BRCM server"
    it "should have a read timeout of 1 second"
    it "should have a connect timeout of 1 second"
    it "should request the given URI"
    it "should pass through the Accept-Language header"
    it "should pass through the Accept header"
    it "should generate Wesabe authorization headers"
    it "should return the response's status code"
    it "should return the response's content type"
    it "should return the response's body"
  end

  describe "GET /data/transactions" do
    it_should_behave_like "it has a logged-in user"

    describe "a JSON request" do
      before do
        @json_data = File.read(File.dirname(__FILE__) + '/../fixtures/transactions.json')
        stub_request(:get, %r{services.test:8080/.*}).
          to_return(:body => @json_data, :headers => {'Content-Type' => "application/json"})
      end

      it "should render JSON if no other format is specified" do
        get :transactions, :uri => %w[all]
        response.body.should match_json(ActiveSupport::JSON.decode(@json_data))
      end

      describe "a request for CSV" do
        before do
          @exporter = Exporter::Txaction::Csv.new(current_user, @json_data)
          @exporter.stub!(:convert)
          Exporter::Txaction::Csv.stub!(:new).and_return(@exporter)
        end

        it "should be successful" do
          get :transactions, :format => 'csv', :uri => %w[all]
          response.should be_success
        end

        it "should set the content type to 'text/csv" do
          get :transactions, :format => 'csv', :uri => %w[all]
          response.content_type.should == 'text/csv'
        end

        it "should set the Content-Disposition" do
          get :transactions, :format => 'csv', :uri => %w[all]
          response.headers['Content-Disposition'].should == "attachment; filename=wesabe-transactions.csv"
        end
      end

      describe "a request for Excel" do
        before do
          @exporter = Exporter::Txaction::Xls.new(current_user, @json_data)
          @exporter.stub!(:convert)
          Exporter::Txaction::Xls.stub!(:new).and_return(@exporter)
        end

        it "should be successful" do
          get :transactions, :format => 'xls', :uri => %w[all]
          response.should be_success
        end

        it "should set the content type to 'text/csv" do
          get :transactions, :format => 'xls', :uri => %w[all]
          response.content_type.should == 'application/vnd.ms-excel'
        end

        it "should set the Content-Disposition" do
          get :transactions, :format => 'xls', :uri => %w[all]
          response.headers['Content-Disposition'].should == "attachment; filename=wesabe-transactions.xls"
        end
      end
    end
  end
end
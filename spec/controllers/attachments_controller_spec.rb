require 'spec_helper'

describe AttachmentsController, "handling GET /attachments/1" do
  it_should_behave_like "it has a logged-in user"

  before do
    @attachment = Attachment.make(:user => current_user)
    @attachment.open('w') {|f| f << 'omgattachmentdata' }
  end

  def do_get
    get :show, :id => @attachment.to_param
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should find the attachment requested" do
    do_get
    response.body.should == @attachment.read
  end
end

describe AttachmentsController, "handling POST /attachments.xml" do
  it_should_behave_like "it has a logged-in user"

  before do
    @attachment = Attachment.make(:user => current_user)
    @inbox_attachment = InboxAttachment.make(:attachment => @attachment)
    @params = {:filename => 'new_attachment.txt', :data => 'new attachment contents'}
  end

  def do_post(params={})
    request.env["HTTP_ACCEPT"] = "application/xml"
    post :create, @params.merge(params)
  end

  it "renders the attachment as xml if successful" do
    do_post
    response.content_type.should == "application/xml"
  end

  it "renders including the location of the created attachment" do
    do_post
    response.should be_created
    Attachment.where(:guid => response.location[%r{/([^/]+)$}, 1]).should_not be_empty
  end

  it "renders errors of the attachment could not be created" do
    do_post(:filename => '')
    response.body.should match(/Filename can't be blank/)
    response.should be_unprocessable_entity
  end
end

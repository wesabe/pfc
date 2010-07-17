require 'spec_helper'

describe FinancialInst do

  before(:each) do
    @fi = FinancialInst.make
    @bofa_login_fields = [
      {:key => 'username', :type => 'text', :label => 'Online ID'},
      {:key => 'password', :type => 'password', :label => 'Passcode'} ]
  end

  it "should have an ssu_support attribute" do
    @fi.ssu_support.should == FinancialInst::SSUSupport::NONE
  end

  it "should return its Wesabe ID when coerced to a parameter" do
    @fi.wesabe_id = "woot"
    @fi.to_param.should == "woot"
  end

  it "should return its name when coerced to a string" do
    @fi.name = "woot"
    @fi.to_s.should == "woot"
  end

  it "prefers a username label from login_fields" do
    @fi.send(:write_attribute, :username_label, 'Username')
    proc { @fi.login_fields = @bofa_login_fields }.
      should change(@fi, :username_label).from('Username').to('Online ID')
  end

  it "prefers a password label from login_fields" do
    @fi.send(:write_attribute, :password_label, 'Password')
    proc { @fi.login_fields = @bofa_login_fields }.
      should change(@fi, :password_label).from('Password').to('Passcode')
  end

  it "finds login fields by key" do
    @fi.login_fields = @bofa_login_fields
    @fi.login_field('username')[:key].should == 'username'
    @fi.login_field(:username)[:key].should == 'username'
  end

  it "modifies login_fields when setting username_label" do
    @fi.username_label = 'Online ID'
    @fi.login_field(:username)[:label].should == 'Online ID'
  end

  it "modifies login_fields when setting password_label" do
    @fi.password_label = 'PIN'
    @fi.login_field(:password)[:label].should == 'PIN'
  end
end

describe FinancialInst, "generating Wesabe IDs" do

  before(:each) do
    FinancialInst.delete_all
    @fi = FinancialInst.new
    @country = mock(:country)
  end

  after(:each) do
    FinancialInst.delete_all
  end

  def run
    @fi.valid?
  end

  describe "for a financial institution without a country or Wesabe ID" do
    before(:each) do
      run
    end

    it "should not assign a Wesabe ID" do
      @fi.wesabe_id.should == nil
    end
  end

  describe "for a financial institution with a country and an existing Wesabe ID" do
    before(:each) do
      @fi.stub!(:country).and_return(@country)
      @fi.wesabe_id = "dingo"
      run
    end

    it "should not assign a Wesabe ID" do
      @fi.wesabe_id.should == "dingo"
    end
  end

  describe "for a financial institution with a country and no Wesabe ID, with existing Wesabe IDs for that country" do
    before(:each) do
      @fi.stub!(:country).and_return(@country)
      @country.stub!(:code).and_return("us")
      FinancialInst.create!(:name => "Dingo", :wesabe_id => "us-000100")
      run
    end

    it "should generate a Wesabe ID greater than the highest Wesabe ID for that country" do
      @fi.wesabe_id.should == "us-000101"
    end
  end

  describe "for a financial institution with a country and no Wesabe ID, with not existing Wesabe IDs for that country" do
    before(:each) do
      @fi.stub!(:country).and_return(@country)
      @country.stub!(:code).and_return("us")
      run
    end

    it "should generate a Wesabe ID of 000100" do
      @fi.wesabe_id.should == "us-000100"
    end
  end
end

describe FinancialInst, "activating" do
  it "should be approved by default" do
    fi = FinancialInst.new
    fi.approved.should == true
    fi.should be_approved
    fi.status.should == Constants::Status::ACTIVE
  end

  it "should not be approved if created as unapproved" do
    fi = FinancialInst.new(:approved => false)
    fi.approved.should == false
    fi.should_not be_approved
    fi.status.should == Constants::Status::UNAPPROVED
  end

  it "should toggle between approved and unapproved" do
    fi = FinancialInst.new(:approved => false)
    fi.approved.should == false
    fi.should_not be_approved
    fi.status.should == Constants::Status::UNAPPROVED

    fi.approved = true

    fi.approved.should == true
    fi.should be_approved
    fi.status.should == Constants::Status::ACTIVE
  end

  it "should interpret 0 and '0' as false" do
    fi = FinancialInst.new(:approved => true)
    fi.approved = "0"
    fi.should_not be_approved
    fi.approved = 0
    fi.should_not be_approved
  end
end

describe FinancialInst, "selecting ids and names" do
  it "should select the ids and names of all financial institutions, sorted by names" do
    connection = mock(:connection)
    FinancialInst.should_receive(:connection).and_return(connection)
    connection.should_receive(:select_rows).with(["SELECT id, name, wesabe_id, homepage_url, login_url FROM financial_insts WHERE id != ? AND status = ? ORDER BY name", FinancialInst::UNKNOWN_FI_ID, Constants::Status::ACTIVE]).and_return([[1, "Bank Blah", "us-10000", nil, "http://blah.com"], [2, "Dingo Madness", "ie-19191", "https://dingo.com/woot", nil], [3, "Foot Foot McGee", "us-30029", nil, nil]])
    FinancialInst.ids_and_names.should == [["Bank Blah [blah.com] (us-10000)", 1], ["Dingo Madness [dingo.com] (ie-19191)", 2], ["Foot Foot McGee [none] (us-30029)", 3]]
  end
end

describe FinancialInst, "destroying" do

  before(:each) do
    FinancialInst.delete_all
    Account.delete_all
    @fi = FinancialInst.create!(:name => "Bank Of Dingo", :wesabe_id => "di-37337")
    @account = Account.make(:financial_inst => @fi)
  end

  after(:each) do
    FinancialInst.delete_all
    Account.delete_all
  end

  it "should not destroy a financial institution it has accounts" do
    @fi.destroy.should == false
    FinancialInst.count.should == 1
    Account.delete(@account.id)
    @fi.destroy
    Account.count.should == 0
    FinancialInst.count.should == 0
  end
end

describe FinancialInst, "rendering as XML" do
  before do
    @fi = FinancialInst.new
  end

  def run
    @xml = Hash.from_xml(@fi.to_xml)["financial_inst"]
  end

  it "should always render the wesabe_id, name, connection_type, homepage_url, login_url, updated_at, and option_list" do
    run
    @xml.keys.sort.should == ["connection_type", "homepage_url", "login_url", "name", "option_list", "updated_at", "wesabe_id"]
  end

  it "should render the username_label, password_label, ofx_url, ofx_org, ofx_fid if the FI is automated" do
    @fi.connection_type = "Automatic"
    run
    @xml.keys.sort.should == ["connection_type", "homepage_url", "login_url", "name", "ofx_broker", "ofx_fid", "ofx_org", "ofx_url", "option_list", "password_label", "updated_at", "username_label", "wesabe_id"]
  end

  it "should render a whole bunch of other stuff if the FI is mechanized" do
    @fi.connection_type = "Mechanized"
    run
    @xml.keys.sort.should == ["connection_type", "date_format", "download_script", "homepage_url", "login_script", "login_url", "logout_script", "mfa_challenge_script", "mfa_login_script", "name", "option_list", "password_label", "statement_days", "updated_at", "username_label", "wesabe_id"]
  end
end

describe FinancialInst, "finding a financial institution for a user" do
  before do
    @user = User.make
    FinancialInst.delete_all
  end

  it "finds an unapproved FI if the user created it" do
    fi = FinancialInst.make(:approved => false, :creating_user => @user)
    FinancialInst.find_for_user(fi.name, @user).should == fi
  end

  it "does not find an unapproved FI if the user did not create it" do
    fi = FinancialInst.make(:approved => false, :creating_user => User.make)
    FinancialInst.find_for_user(fi.name, @user).should be_nil
  end

  it "does not find an FI by id unintentionally" do
    fi = FinancialInst.make
    FinancialInst.find_for_user("#{fi.id}th National Bank", @user).should_not == fi
  end

  it "finds a HIDDEN FI" do
    fi = FinancialInst.make(:status => FinancialInst::Status::HIDDEN)
    FinancialInst.find_for_user(fi.wesabe_id, @user).should == fi
  end

  describe "when that user is an admin" do
    before do
      @user.stub!(:admin?).and_return(true)
    end

    it "finds an unapproved FI if the user is an admin but did not create it" do
      fi = FinancialInst.make(:approved => false, :creating_user => User.make)
      FinancialInst.find_for_user(fi.name, @user).should == fi
    end

    it "finds active FIs by name before unapproved FIs" do
      @unapproved_amex = FinancialInst.make(:name => "American Express", :status => Constants::Status::UNAPPROVED)
      @active_amex     = FinancialInst.make(:name => "American Express", :status => Constants::Status::ACTIVE)
      FinancialInst.find_for_user("American Express", @user).should == @active_amex
    end
  end
end

describe FinancialInst, "finding a public financial institution" do
  before do
    @fi = FinancialInst.make
  end

  it "finds by id" do
    FinancialInst.find_public(@fi.id).should == @fi
  end

  it "finds by name" do
    FinancialInst.find_public(@fi.name).should == @fi
  end

  it "finds by wesabe id" do
    FinancialInst.find_public(@fi.wesabe_id).should == @fi
  end
end

describe FinancialInst, "with a login URL" do
  it "should provide the login URL as its main URL" do
    fi = FinancialInst.new(:login_url => "http://dingo")
    fi.url.should == "http://dingo"
  end
end

describe FinancialInst, "without a login URL" do
  it "should provide the homepage URL as its main URL" do
    fi = FinancialInst.new(:login_url => "", :homepage_url => "http://dingo")
    fi.url.should == "http://dingo"
  end
end

describe FinancialInst, "date formats" do
  it "should provide whether or not the FI uses the DDMMYYY format" do
    fi = FinancialInst.new(:statement_date_format => FinancialInst::DateFormat::DDMMYYYY)
    fi.date_format_ddmmyyyy?.should == true

    fi = FinancialInst.new(:statement_date_format => FinancialInst::DateFormat::MMDDYYYY)
    fi.date_format_ddmmyyyy?.should == false
  end

  it "should provide a list of date formats suitable for use with a select helper" do
    FinancialInst.date_format_options.should == [['US (MM-DD-YYYY)', FinancialInst::DateFormat::MMDDYYYY], ['International (DD-MM-YYYY)', FinancialInst::DateFormat::DDMMYYYY]]
  end
end

describe FinancialInst, "listing connection type options" do
  it "should include Manual, Automatic, and Mechanized" do
    FinancialInst.connection_type_options.should == ["Manual", "Automatic", "Mechanized"]
  end
end

describe FinancialInst, "merging" do

  before do
    @old_fi  = FinancialInst.make
    @account = Account.make(:financial_inst => @old_fi)
    @new_fi  = FinancialInst.make
  end

  it "should set the old FI's status to deleted and its mapped_to_id to the new FI's ID" do
    FinancialInst.merge(@old_fi, @new_fi)
    @old_fi.reload.mapped_to_id.should == @new_fi.id
  end

  it "should update all the accounts of the old FI with the new FI's id" do
    FinancialInst.merge(@old_fi, @new_fi)
    @account.reload.financial_inst.should == @new_fi
  end
end

describe FinancialInst, "listing names of popular FIs" do

  before do
    FinancialInst.delete_all
    FinancialInst.connection.execute("ALTER TABLE financial_insts AUTO_INCREMENT = 1")
    FinancialInst.make(:name => "UNKNOWN", :wesabe_id => "unknown")
    @fi1 = FinancialInst.make(:name => "Ringo", :wesabe_id => "1")
    @fi2 = FinancialInst.make(:name => "Blart", :wesabe_id => "2")
    @fi3 = FinancialInst.make(:name => "Unapproved", :wesabe_id => "3", :approved => false)

    Account.delete_all
    Account.make(:financial_inst => @fi1)
    Account.make(:financial_inst => @fi1)
    Account.make(:financial_inst => @fi2)
    Account.make(:financial_inst => @fi3)
  end

  after do
    FinancialInst.delete_all
    Account.delete_all
  end

  it "should cache the results in memcache" do
    FinancialInst.popular_names(10)
  end

  it "should return the FIs with the most accounts" do
    FinancialInst.popular_names(1).should == ["Ringo"]
  end

  it "should not include the Unknown FI" do
    FinancialInst.popular_names(100).should_not include("UNKNOWN")
  end

  it "should not include any unapproved FIs" do
    FinancialInst.popular_names(1000).should_not include("Unapproved")
  end
end
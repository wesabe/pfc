require 'spec_helper'

describe SsuJobs::Activity do
  before(:all) do
    @fi      = FinancialInst.make
    @ac      = AccountCred.make(:financial_inst_id => @fi.id)
    @job_200 = SsuJob.make(:account_cred_id => @ac.id, :status => 200)
    @job_400 = SsuJob.make(:account_cred_id => @ac.id, :status => 400)
    @job_500 = SsuJob.make(:account_cred_id => @ac.id, :status => 500)
  end

  after(:all) do
    FinancialInst.delete(@fi)
    AccountCred.delete(@ac)
    SsuJob.delete(@job_200)
    SsuJob.delete(@job_400)
    SsuJob.delete(@job_500)
  end

  before(:each) do
    @ssu_act = SsuJobs::Activity.new
  end

  it "must allow a starting date constraint to be set" do
    @ssu_act.start_date = Time.mktime(2006, 6)
    @ssu_act.start_date.should == Time.mktime(2006, 6)
  end

  it "must allow a ending date constraint to be set" do
    @ssu_act.end_date = Time.mktime(2006, 6)
    @ssu_act.end_date.should == Time.mktime(2006, 6)
  end

  ## FIXME - Add more spec, yo

end

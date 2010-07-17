require 'spec_helper'

describe Target do
  it_should_behave_like 'it has a logged-in user'

  before do
    @checking = Account.make(:user => current_user)
    @tx = Txaction.make(:account => @checking, :amount => -20, :date_posted => 1.day.since(Time.now.beginning_of_month))
    @tx.tag_with("atm")
    @atm = Tag.find_by_name('atm')
    @target = Target.make(:tag => @atm, :tag_name => @atm.name, :user => current_user)
  end

  context "given no period" do
    it "uses the current month as the period" do
      @target.calculate!(current_user).to_d.should == 20.to_d
    end

    it "includes transactions recorded today" do
      @tx2 = Txaction.make(:account => @checking, :amount => -40, :date_posted => 1.second.since(Time.now))
      @tx2.tag_with("atm")
      @target.calculate!(current_user).to_d.should == 60.to_d
    end
  end

  context "given a period in which there are matching transactions" do
    before do
      start = @tx.date_posted.beginning_of_month
      @period = start..(start.end_of_month)
    end

    it "calculates the absolute value of the net amount of the matched transactions" do
      @target.calculate!(current_user, @period).to_d.should == 20.to_d
    end
  end

  context "given a period in which there are no matching transactions" do
    before do
      start = Time.at(0).beginning_of_month
      @period = start..(start.end_of_month)
    end

    it "calculates the amount as zero" do
      @target.calculate!(current_user, @period).to_d.should == 0.to_d
    end
  end

  it "should not ignore transfers" do
    @tx.set_transfer_buddy!(@tx)
    @target.calculate!(current_user).to_d.should == 20.to_d
  end
end

require 'spec_helper'

describe ConditionsConstructor do
  before do
    @nothing = ConditionsConstructor.new
    @single = ConditionsConstructor.new 'amount = ?', 5
    @double = ConditionsConstructor.new 'amount = ?', 5
    @double.add 'status IN (?)', [1,2,3]
  end

  it "should return empty conditions if nothing is given" do
    @nothing.conditions.should be_empty
  end

  it "should return what it is given if only one set of conditions are used" do
    @single.conditions.should == ['(amount = ?)', 5]
  end

  it "should join all conditions with AND by default" do
    @double.conditions.first.should == '(amount = ?) AND (status IN (?))'
  end

  it "should allow joining all conditions with OR" do
    @double.conditions(' OR ').first.should == '(amount = ?) OR (status IN (?))'
  end

  it "should concatenate all bind variables together" do
    @double.conditions[1..-1].should == [5, [1,2,3]]
  end

  it "should allow adding an array" do
    @single.add(['status = ?', 1]).conditions.should == ['(amount = ?) AND (status = ?)', 5, 1]
  end

  it "should allow initializing with an array" do
    ConditionsConstructor.new(['status = ?', 1]).conditions.should == ['(status = ?)', 1]
  end

  it "should allow creating a new ConditionsConstructor using the + symbol" do
    (@single + ['status IS NOT NULL']).conditions.should == ['(amount = ?) AND (status IS NOT NULL)', 5]
  end

  it "should not be changed when adding using the + symbol" do
    lambda { @single + 'status IS NOT NULL' }.should_not change(@single, :conditions)
  end

  it "should allow initializing with a string" do
    ConditionsConstructor.new('status IS NOT NULL').conditions.should == ['(status IS NOT NULL)']
  end

  it "should allow adding a string" do
    (@single + 'status IS NOT NULL').conditions.should == ['(amount = ?) AND (status IS NOT NULL)', 5]
  end

  it "should allow adding another ConditionsConstructor" do
    (@nothing + @single).conditions.should == ['(amount = ?)', 5]
  end

  it "should equal another equivalent ConditionsConstructor" do
    ConditionsConstructor.new.should == @nothing
  end

  it "should allow initializing with a hash" do
    ConditionsConstructor.new(:id => 1).conditions.should == ['(id = ?)', 1]
  end

  it "should allow adding a hash" do
    (@single + {:id => 1}).conditions.should == ['(amount = ?) AND (id = ?)', 5, 1]
  end

  it "should handle hashes with ranges" do
    (@single + {:id => 1..10}).conditions.should == ['(amount = ?) AND (id BETWEEN ? AND ?)', 5, 1, 10]
  end

  it "should handle hashes with ranges and arrays" do
    cc = ConditionsConstructor.new(:id => 1..10)
    cc.add(:status => [1,2])
    cc.conditions.should == ['(id BETWEEN ? AND ?) AND (status IN (?))', 1, 10, [1, 2]]
  end

  it "should not generate a conditions string from an empty hash" do
    cc = ConditionsConstructor.new({})
    cc.conditions_args.should be_empty
    cc.conditions_strs.should be_empty
  end

  it "should not generate a nil condition string from an empty array" do
    cc = ConditionsConstructor.new([])
    cc.conditions_args.should be_empty
    cc.conditions_strs.should be_empty
  end

end
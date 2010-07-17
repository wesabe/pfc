require File.dirname(__FILE__) + '/spec_helper'

describe SimplePresenter do
  before(:all) do
    @renderer = Controller.new
    @presentable = String.new
  end

  it "should take a presentable and a renderer when initialized" do
    SimplePresenter.new(@presentable, @renderer)
  end

  it "should store presentable in an attribute" do
    SimplePresenter.new(@presentable, @renderer).presentable.should == @presentable
  end

  it "should store renderer in an attribute" do
    SimplePresenter.new(@presentable, @renderer).renderer.should == @renderer
  end

  it "requires a presentable" do
    lambda { SimplePresenter.new(nil, @renderer) }.
      should raise_error(ArgumentError, "you have to present something")
  end

  it "requires a renderer" do
    lambda { SimplePresenter.new(@presentable, nil) }.
      should raise_error(ArgumentError, "you have to have a renderer")
  end

  describe "namespaced_constant" do
    it "should return namespaced constants" do
      SimplePresenter.namespaced_constant("SimplePresenter::Helper").should == SimplePresenter::Helper
    end

    it "should return nil for nonexistent constants" do
      SimplePresenter.namespaced_constant("Foo::Bar").should be_nil
    end

    it "should return nil if passed nil" do
      SimplePresenter.namespaced_constant(nil).should be_nil
    end
  end
end

describe SimplePresenter::Helper do
  context "once included" do
    it "should define #present" do
      Controller.new.should respond_to(:present)
    end
  end

  context "present method" do
    before do
      @c = Controller.new
    end

    context "when given an object with no presenter" do
      it "should return a default presenter" do
        @c.present({:a => 1}).class.should == SimplePresenter
      end
    end

    context "when given an object with a specific presenter" do
      it "should return that specific presenter" do
        @c.present([]).class.should == ArrayPresenter
      end
    end

    context "when called instances of different classes on a single renderer" do
      it "should return specific presenters for each" do
        @c.present("bob").class.should == StringPresenter
        @c.present([]).class.should == ArrayPresenter
        @c.present({:a => 1}).class.should == SimplePresenter
      end
    end

    context "when given an array of one kind of thing" do
      it "should return ThingArrayPresenter" do
        @c.present([1,2,3]).class.should == FixnumArrayPresenter
      end

      it "should provide presenter methods specific to ThingArrayPresenter" do
        @c.present([1,2,3]).sum.should == 6
      end

      context "when ThingArrayPresenter doesn't exist" do
        it "should fall back on the ClassPresenter" do
          @c.present(ArrayChild.new).class.should == ArrayChildPresenter
        end
      end

      context "when the ClassPresenter doesn't exist" do
        it "should lastly fall back on ArrayPresenter" do
          @c.present(["a", "b", "c"]).class.should == ArrayPresenter
        end
      end
    end

  end
end

describe StringPresenter do
  before(:all) do
    @renderer = Controller.new
    @presenter = @renderer.present("bob")
  end

  it "should provide its methods via the present() helper" do
    @presenter.ascii_numbers.should == [98, 111, 98]
  end

  it "should pass methods through from the presenter to the presentable" do
    @presenter.ascii_numbers_on_self.should == [98, 111, 98]
  end

  it "should fall back on passing methods to the controller" do
    @renderer.should_receive(:some_cool_url)
    @presenter.some_cool_url
  end
end

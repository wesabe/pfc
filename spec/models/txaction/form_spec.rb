require 'spec_helper'

describe Txaction::Form do
  it_should_behave_like "it has a logged-in user"

  describe "#update" do
    def params
      @params ||= {:merchant_name => "Betty's"}
    end

    def update!
      form = Txaction::Form.new(params).update(@txaction)
      @txaction.reload
      return form
    end

    def update_expecting_failure!(field, message)
      begin
        update!
        fail "update! should have raised"
      rescue Txaction::Form::UpdateValidationFailed => e
        e.field.should == field
        e.message.should == message
      end
    end

    it "returns itself" do
      form = Txaction::Form.new
      form.update(Txaction.make).should == form
    end

    shared_examples_for "it can be a transfer" do
      describe "being marked as a transfer" do
        before do
          params[:is_transfer] = 'on'
        end

        describe "without a transfer buddy" do
          before do
            update!
          end

          it "makes the txaction a transfer" do
            @txaction.should be_a_transfer
          end

          it "makes the txaction not a paired transfer" do
            @txaction.should_not be_a_paired_transfer
          end
        end

        describe "with a transfer buddy" do
          before do
            @transfer_account = Account.make(:checking, :user => current_user)
            @transfer_buddy = Txaction.make(:account => @transfer_account)
            params[:transfer_buddy] = @transfer_buddy.to_param
          end

          it "makes the txaction a transfer" do
            update!
            @txaction.should be_a_transfer
          end

          it "makes the txaction a paired transfer" do
            update!
            @txaction.should be_a_paired_transfer
          end

          it "makes the transfer buddy the one passed in from params" do
            update!
            @txaction.transfer_buddy.should == @transfer_buddy
          end
        end
      end

      describe "being marked as a transfer implicitly by giving a transfer buddy" do
        before do
          @transfer_account = Account.make(:checking, :user => current_user)
          @transfer_buddy = Txaction.make(:account => @transfer_account)
          params[:transfer_buddy] = @transfer_buddy.to_param
        end

        it "makes the txaction a transfer" do
          update!
          @txaction.should be_a_transfer
        end

        it "makes the txaction a paired transfer" do
          update!
          @txaction.should be_a_paired_transfer
        end

        it "makes the transfer buddy the one passed in from params" do
          update!
          @txaction.transfer_buddy.should == @transfer_buddy
        end

        describe "and explicitly marking it as not a transfer" do
          before do
            params[:is_transfer] = '0'
          end

          it "marks it as not a transfer" do
            update!
            @txaction.should_not be_a_transfer
          end
        end
      end

      describe "and a transfer buddy belonging to another user" do
        before do
          @account = Account.make
          @transfer_buddy = Txaction.make(:account => @account)
          params[:transfer_buddy] = @transfer_buddy.to_param
        end

        it "is still marked as a transfer" do
          update!
          @txaction.should be_a_transfer
        end

        it "is not marked as a paired transfer" do
          update!
          @txaction.should_not be_a_paired_transfer
        end
      end

      describe "being marked as not a transfer" do
        before do
          params[:is_transfer] = '1'
          update!
          params[:is_transfer] = '0'
          update!
        end

        it "makes the transaction not a transfer" do
          @txaction.should_not be_a_transfer
        end

        it "makes the transaction not a paired transfer" do
          @txaction.should_not be_a_paired_transfer
        end
      end
    end

    shared_examples_for "it has an editable amount" do
      describe "and a valid amount" do
        before do
          params[:amount] = '1.95'
        end

        describe "of spending" do
          before do
            params[:amount_type] = 'spent'
            update!
          end

          it "updates the Txaction's amount" do
            @txaction.amount.to_d.should == -1.95.to_d
          end
        end

        describe "of earnings" do
          before do
            params[:amount_type] = 'earned'
            update!
          end

          it "updates the Txaction's amount" do
            @txaction.amount.to_d.should == 1.95.to_d
          end
        end
      end

      describe "and a blank amount" do
        before do
          params[:amount] = ""
        end

        it "complains about a blank amount" do
          update_expecting_failure!('amount', 'Please enter an amount.')
        end
      end
    end

    shared_examples_for "it has an immutable amount" do
      describe "and an amount" do
        before do
          params[:amount] = '2.00'
          params[:amount_type] = 'spending'
        end

        it "should not set the amount" do
          update!
          @txaction.amount.should_not == -2.0
        end
      end
    end

    shared_examples_for "it has an editable date" do
      describe "and a valid date" do
        before do
          params[:date_posted] = '2006-02-13'
        end

        it "updates the Txaction's date" do
          update!
          @txaction.date_posted.should == Time.local(2006, 2, 13)
        end

        describe "that happens to be today" do
          before do
            Time.stub!(:now).and_return(@now)
            params[:date_posted] = Time.now.strftime('%Y-%m-%d')
          end

          it "sets the Txaction's datetime to now" do
            update!
            @txaction.date_posted.should == @now
          end
        end

        describe "that is the same date as the transaction" do
          before do
            params[:date_posted] = @txaction.date_posted.to_date.strftime('%Y-%m-%d')
          end

          it "should not update the date on the transaction" do
            @txaction.should_not_receive(:update_attributes!)
            update!
          end
        end

        describe "that is only month and day" do
          before do
            params[:date_posted] = "9/27"
          end

          it "should append the current year" do
            update!
            @txaction.date_posted.should == Time.local(Time.now.year, 9, 27)
          end
        end

        describe "that has a two-digit year, separated by dashes" do
          before do
            params[:date_posted] = "12-24-08"
          end

          it "updates the Txaction's date" do
            update!
            @txaction.date_posted.should == Time.local(2008, 12, 24)
          end
        end
      end

      describe "and a blank date" do
        before do
          params[:date_posted] = ' '
        end

        it "complains about a blank date" do
          update_expecting_failure!('date_posted', 'Please enter a date.')
        end
      end

      describe "and a gibberish date" do
        before do
          params[:date_posted] = 'foosball rulez!'
        end

        it "complains about not being able to parse the date" do
          update_expecting_failure!('date_posted', 'We could not parse the date you entered. Please use the format "yyyy-mm-dd".')
        end
      end

      describe "and an out-of-range date" do
        before do
          params[:date_posted] = '1919-01-01'
        end

        it "complains about an out-of-range date" do
          update_expecting_failure!('date_posted', 'The date is not valid. Please enter a year between 1920 and 9999.')
        end
      end

    end

    shared_examples_for "it can have tags" do
      before do
        params[:tags] = "foo bar"
      end

      it "calls Txaction#tag_this_and_merchant_untagged_with" do
        @txaction.should_receive(:tag_this_and_merchant_untagged_with).once
        update!
      end
    end

    shared_examples_for "it can have a note" do
      describe "and a note" do
        before do
          params[:note] = 'foosball rulez!'
          update!
        end

        it "saves the note" do
          @txaction.note.should == 'foosball rulez!'
        end
      end
    end

    describe "given a bank Txaction" do
      before do
        @account  = Account.make(:credit, :user => current_user)
        @now = Time.mktime(2009, 6, 26, 12, 2)
        @txaction = Txaction.make(:amount => -2.95, :account => @account, :date_posted => @now)
      end

      it_should_behave_like "it can be a transfer"
      it_should_behave_like "it has an immutable amount"
      it_should_behave_like "it has an editable date"
      it_should_behave_like "it can have a note"
      it_should_behave_like "it can have tags"
    end

    describe "given a manual Txaction" do
      before do
        @account  = Account.make(:manual, :user => current_user)
        @now = Time.mktime(2009, 6, 26, 12, 2)
        @txaction = Txaction.make(:amount => -1.00, :account => @account, :date_posted => @now)
      end

      it_should_behave_like "it can be a transfer"
      it_should_behave_like "it has an editable amount"
      it_should_behave_like "it has an editable date"
      it_should_behave_like "it can have a note"
      it_should_behave_like "it can have tags"
    end
  end
end

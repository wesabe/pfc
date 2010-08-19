require 'spec_helper'

describe TagsController do
  describe 'DELETE /tags/food' do
    context 'when the user is logged in' do
      it_should_behave_like 'it has a logged-in user'

      context 'and the has no transactions tagged "food"' do
        it 'is successful' do
          delete :destroy, :id => 'food'
          response.should be_success
        end
      end

      context 'and the user has transactions tagged "food"' do
        before do
          @txaction = Txaction.make(:account => Account.make(:user => current_user))
          @txaction.tag_with('food')
        end

        it 'is successful' do
          delete :destroy, :id => 'food'
          response.should be_success
        end

        it 'removes the tag from transactions with that tag' do
          lambda { delete :destroy, :id => 'food' }.
            should change { @txaction.reload.tags.include?(Tag.find_or_create_by_name('food')) }.
                    from(true).to(false)
        end
      end
    end
  end
end

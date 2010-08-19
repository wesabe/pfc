class TagsController < ApplicationController
  before_filter :check_authentication

  def destroy
    if tag
      Tag.destroy(current_user, tag)
      render :nothing => true, :status => :ok
    else
      render :nothing => true, :status => :not_found
    end
  end

  private

  def tag
    @tag ||= Tag.find_by_name(params[:id])
  end
end

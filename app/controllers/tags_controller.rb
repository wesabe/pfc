class TagsController < ApplicationController
  before_filter :check_authentication

  def show
    if tag
      render :action => 'accounts/index'
    else
      redirect_to accounts_url
    end
  end

  def destroy
    if tag
      Tag.destroy(current_user, tag)
      render :nothing => true, :status => :ok
    else
      render :nothing => true, :status => :not_found
    end
  end

  def update
    if tag.nil?
      render :nothing => true, :status => :not_found
    elsif replacement_tags = params[:replacement_tags]
      Tag.replace(current_user, tag, replacement_tags)
      render :nothing => true, :status => :ok
    else
      render :nothing => true, :status => :bad_request
    end
  end

  private

  def tag
    @tag ||= Tag.find_by_name(params[:id])
  end
end

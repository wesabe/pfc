class TrendsController < ApplicationController
  before_filter :check_authentication

  def index
  end

  def show
    render :action => 'index'
  end
end

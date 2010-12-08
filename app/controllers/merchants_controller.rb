class MerchantsController < ApplicationController
  before_filter :check_authentication, :except => [:show]

  def show
    render :action => 'accounts/index'
  end

  def user_index
    render :json => current_user.merchants.
                      sort_by {|m| [-m.count.to_i, m.name]}.
                      map(&:name)
  end

  def public_index
    render :json => Merchant.all_publicly_visible_names - current_user.merchants.map(&:name)
  end

  private

  def user_index_cache_path
    "merchants/user_index/#{current_user.id}"
  end
end
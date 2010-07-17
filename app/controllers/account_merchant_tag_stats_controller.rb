class AccountMerchantTagStatsController < ApplicationController
  before_filter :check_authentication
  before_filter :get_merchant_and_sign
  layout nil

  def edit
    @autotags = AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign)
  end

  def update
    new_tags = TagParser.parse(params["autotags"])
    if new_tags.empty?
      MerchantUser.disable_autotags(current_user, @merchant, @sign)
      remove_tags = []
      tags = ""
    else
      old_tags = TagParser.parse(params["old_tags"])
      remove_tags = old_tags - new_tags

      AccountMerchantTagStat.force_on(current_user, @merchant, @sign, new_tags)
      AccountMerchantTagStat.force_off(current_user, @merchant, @sign, remove_tags)
      MerchantUser.enable_autotags(current_user, @merchant, @sign)
      tags = AccountMerchantTagStat.autotags_string_for(current_user, @merchant, @sign)

      if params["update_all"]
        Txaction.add_tags_for_merchant(current_user, @merchant, @sign, new_tags)
        Txaction.remove_tags_for_merchant(current_user, @merchant, @sign, remove_tags)
      end
    end

    render :json => {"added" => new_tags, "removed" => remove_tags, "tags" => tags}
  end

private

  def get_merchant_and_sign
    @merchant = Merchant.find(params[:id])
    @sign = params[:sign].to_i > 0 ? 1 : -1
  end
end

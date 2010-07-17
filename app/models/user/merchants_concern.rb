# merchants concern for User
class User
  # return the list of merchants used by this user, including a usage count
  # note that the count is returned as a string, not an integer
  def merchants
    acct_ids = account_ids
    return [] unless acct_ids.any?

    Merchant.find(:all,
      :select => "merchants.*, COUNT(merchants.id) AS count",
      :joins => "JOIN txactions ON txactions.merchant_id = merchants.id",
      :conditions => ["account_id in (?)", acct_ids],
      :group => "merchants.id")
  end

  # if the user has created their own edit for this txaction name, find it
  def get_merchant(filtered_txaction_name, sign)
    # don't try to find matches for UNKNOWN transactions (BugzId: 607)
    return if filtered_txaction_name.to_s =~ /UNKNOWN(?: PAYEE)?$/

    if account_ids.any? && txaction = Txaction.find(:first, :select => "merchant_id",
        :conditions => ["account_id in (?) \
                          and filtered_name = ? \
                          and merchant_id is not null \
                          and status = ? \
                          and amount #{sign >= 0 ? '>= 0' : '< 0'}",
                          account_ids, filtered_txaction_name, Constants::Status::ACTIVE],
        :order => "updated_at desc")
      Merchant.find(txaction.merchant_id)
    end
  end

  # return the MerchantUser associated with this merchant
  def merchant_user(merchant, sign = nil)
    merchant_id = merchant.is_a?(Merchant) ? merchant.id : merchant
    cc = ConditionsConstructor.new("user_id = ? and merchant_id = ?", id, merchant_id)
    cc.add("sign = ?", sign) if sign
    MerchantUser.find(:first, :conditions => cc.conditions)
  end

  # return true if the user shops at the given merchant (convenience method calls out to Merchant)
  def shops_at?(merchant)
    merchant.shopped_at_by_user?(self)
  end
end
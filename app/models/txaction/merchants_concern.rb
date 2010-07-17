# merchants concern for Txaction
class Txaction
  belongs_to :merchant

  before_save :cache_merchant_name
  before_save :update_merchant_associations

  #---------------
  # Class Methods
  #

  # find all transactions the user has for the given merchant
  def self.find_by_user_and_merchant(user, merchant)
    Txaction.for_user(user).active.where(:merchant_id => merchant.id).order('date_posted')
  end

  #------------------
  # Instance Methods
  #

  def merchant_name
    read_attribute(:merchant_name) || merchant && merchant.name
  end

  # return true if the we have a merchant and it is linkable (i.e. not unedited)
  def linkable_merchant?
    merchant && !merchant.unedited?
  end

  # find other txactions for this user that have the same merchant and sign
  def find_others_from_merchant(user)
    return [] unless merchant
    account_ids = user.accounts.visible.map(&:id)
    return [] if account_ids.empty?
    # return list of updated txactions
    Txaction.find(:all, :conditions => [
      "merchant_id = ? AND account_id in (?) AND status = ? AND SIGN(amount) = ?",
      merchant.id, user.accounts.map(&:id), Constants::Status::ACTIVE, amount.sign],
      :order => "date_posted desc, sequence asc")
  end

  # Look up and then cache the MerchantUser object for this txaction's merchant
  def merchant_user(user, reload=false)
    if !reload && merchant && @mu && (@mu.user == user)
      @mu
    else
      @mu = MerchantUser.get_merchant_user(user, merchant, amount.sign)
    end
  end

  # look for a merchant that matches this transaction
  def find_merchant(user)
    # don't set merchants on checks -- that could get really messy; ignore txactions that should
    # be edited independently, since the merchant matching is probably not accurate. (thanks, Matt K.)
    return if is_check? || edit_independently?

    # see if the user has a merchant with this name and sign
    sign = amount.sign
    if merchant = user.get_merchant(filtered_name, sign)
      logger.debug("found user merchant for \"#{filtered_name}\": #{merchant.name}")
    else
      logger.debug("couldn't find user merchant for \"#{filtered_name}\" with sign #{sign}")
      # otherwise, get the most popular merchant
      if merchant = Merchant.get_most_popular_merchant(filtered_name, sign)
        MerchantUser.create(:merchant => merchant, :user => user)  # add to merchants_users
        logger.debug("found popular merchant for \"#{filtered_name}\": #{merchant.name}")
      end
    end

    return merchant
  end

  private

  def cache_merchant_name
    self.merchant_name = self.merchant.name if self.merchant_id && self.merchant
  end

  def switch_amts_merchant(old_merchant, new_merchant)
    taggings.each do |tagging|
      tagging.decrement_tag_stats(old_merchant)
      tagging.increment_tag_stats(new_merchant)
    end
  end

  # update other matching unedited txactions with this txaction's merchant
  def update_unedited_txactions
    # FIXME: This doesn't work for manual txactions, which have no filtered name
    cc = ConditionsConstructor.new
    cc.add("account_id in (?)", User.current.accounts.map(&:id))
    cc.add("status = ?", Constants::Status::ACTIVE)
    cc.add("filtered_name = ?", filtered_name)
    cc.add("SIGN(amount) = ?", amount.sign)
    cc.add("(txactions.merchant_id IS NOT NULL AND merchants.unedited = ?) OR txactions.merchant_id IS NULL", true)

    ids = Txaction.select('txactions.id').where(cc.conditions).
            joins("LEFT OUTER JOIN merchants ON merchants.id = txactions.merchant_id")

    if ids.any?
      Txaction.where(:id => ids.map(&:id)).
        update_all({:merchant_id => merchant_id, :merchant_name => merchant_name})
    end
  end

  # update the amts and merchants_users table. Requires User.current to be set
  def update_merchant_associations
    user = User.current || raise("Current user not found!")
    # # if the merchant has changed, update the AMTS and MerchantUsers tables
    old_merchant_id, new_merchant_id = self.changes["merchant_id"]
    return if !old_merchant_id && !new_merchant_id

    if old_merchant_id && new_merchant_id
      switch_amts_merchant(Merchant.find(old_merchant_id), merchant)
    end

    if old_merchant_id
      # delete old MerchantUser record if it no longer exists in the user's transactions
      old_merchant_user = MerchantUser.find_by_user_id_and_merchant_id_and_sign(user.id, old_merchant_id, amount.sign)
      if old_merchant_user
        existing_transctions_at_old_merchant = Txaction.count(:conditions => {:account_id => user.accounts.map(&:id), :merchant_id => old_merchant_id})
        if existing_transctions_at_old_merchant <= 1 # this Txaction, self, is still at old_merchant
          old_merchant_user.destroy
        end
      end
    end

    # create new MerchantUser record if it doesn't already exist
    MerchantUser.find_or_create_by_user_id_and_merchant_id_and_sign(user.id, new_merchant_id, amount.sign)

    update_unedited_txactions unless edit_independently?
  end
end
# this model represents a mapping from users to merchants
class MerchantUser < ActiveRecord::Base
  # not sure why this is necessary; rails doesn't seem to figure out that it is a many-to-many
  # mapping table and it tries to use "merchant_users"
  set_table_name :merchants_users
  acts_as_taggable
  belongs_to :user
  belongs_to :merchant
  belongs_to :aliased_merchant, :class_name => "Merchant"

  validates_presence_of :user, :merchant

  after_save :update_merchant_visibility, :update_merchant_users_count

  # check if this merchant_user affects merchant visibility, and update the
  # publicly visible flag in merchant if so
  def update_merchant_visibility
    current_visibility = merchant.publicly_visible?
    if merchant.publicly_visible != current_visibility
      merchant.update_attribute(:publicly_visible, current_visibility)
    end
  end

  # keep the count of users for the merchant up-to-date
  def update_merchant_users_count
    users_count = merchant.uncached_users_count
    if merchant.users_count != users_count
      merchant.update_attribute(:users_count, users_count)
    end
  end

  # return the MerchantUser for this user and merchant
  def self.get_merchant_user(user, merchant, sign = -1)
    # allow user to pass in either objects or ids
    user_id = user.kind_of?(User) ? user.id : user
    merchant_id =
      merchant.kind_of?(Merchant) ? merchant.id : merchant

    self.find(:first,
              :conditions => ["user_id = ? AND merchant_id = ? AND sign = ?",
                              user_id, merchant_id, sign])
  end

  def self.disable_autotags(user, merchant, sign = -1)
    update_all(["autotags_disabled = ?", true],
               ["user_id = ? and merchant_id = ? and sign = ?",
                 user.id, merchant.id, sign])
  end

  def self.enable_autotags(user, merchant, sign = -1)
    update_all(["autotags_disabled = ?", false],
               ["user_id = ? and merchant_id = ? and sign = ?",
                 user.id, merchant.id, sign])
  end

  def self.autotags_disabled?(user, merchant, sign = -1)
    mu = get_merchant_user(user, merchant, sign)
    return mu && mu.autotags_disabled
  end
end

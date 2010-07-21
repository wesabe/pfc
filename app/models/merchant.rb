# REVIEW: This model has a shit-ton of crappy SQL calls which need a good ass-kicking.
class Merchant < ActiveRecord::Base
  has_many :txactions,
           :conditions => ["txactions.status = ?", Constants::Status::ACTIVE],
           :order => "txactions.date_posted, txactions.created_at"
  has_many :merchant_users, :dependent => :destroy
  has_many :users, :through => :merchant_users, :group => 'user_id'

  belongs_to :canonical_merchant, :class_name => "Merchant", :foreign_key => :canonical_merchant_id
  has_many :mapped_merchants, :class_name => "Merchant", :foreign_key => :canonical_merchant_id

  before_validation :strip_whitespace_from_name

  validates_presence_of :name
  validates_uniqueness_of :name

  attr_accessor :shopped_at_by_user # place to cache whether the current user shops here (used in merchants_controller#show)
  attr_accessor :noncanonical_merchant # place to cache the merchant that mapped to this canonical merchant

  slug :name

  def <=>(other)
    name <=> other.name
  end

  #----------------------------------------------------------------------------
  # Class methods
  #

  # find or create a Merchant, returning the Merchant record
  # The reason this is as complex as it is is because we are seeing a race condition with the
  # find and create. We still try the find first, since a create in the case where the record already
  # exists will result in two selects--one for the uniqueness validation, and another for the find_by_name.
  def self.find_or_create_by_name(name, params = {})
    find_by_name(name) || create!(params.update(:name => name))
  rescue ActiveRecord::RecordNotUnique
    find_by_name(name)
  end

  # find merchant(s) by id(s) that is (are) visible to the given user (or publicly visible if user is nil)
  def self.find_visible(merchant_id, user, options = {})
    raise ActiveRecord::RecordNotFound if merchant_id.blank?
    merchants = find(:all, {:conditions => ["id in (?)", [merchant_id].flatten]}.update(options)).compact.select {|m| user ? m.visible?(user) : m.publicly_visible? }
    raise ActiveRecord::RecordNotFound if merchants.empty?
    # return array or scalar depending on how we were called
    merchant_id.is_a?(Array) ? merchants : merchants.first
  end

  # not a great name, but given a set of merchant_ids, return either those merchants, or the canonical merchants they map to
  def self.find_visible_and_canonical(merchant_ids, user, options = {})
    merchants = find_visible(merchant_ids, user, :include => :summary)
    # if any of the merchants are mapped to a canonical merchant, use that instead
    merchants.map! do |m|
      # look for a canonical merchant, but if the set of merchants already contains that canonical merchant,
      # ignore it so that we don't end up comparing the same merchant
      if (canonical_merchant = m.canonical_merchant) && !merchants.include?(canonical_merchant)
        canonical_merchant.noncanonical_merchant = m
        canonical_merchant
      else
        m
      end
    end

    # exclude merchants that don't have a sumamry
    merchants.reject! {|m| !m.summary }

    # make sure they're in the same order as they were originally requested
    merchants.sort_by {|m| merchant_ids.index(m.id) || merchant_ids.index(m.noncanonical_merchant.id)}
  end

  # return the canonical merchant given this id
  def self.find_canonical(id)
    merchant = find(id)
    return merchant if merchant.canonical? # that was easy
    # if the merchant is mapped to a canonical merchant, go to that
    return merchant.canonical_merchant if merchant.canonical_merchant
    # otherwise, query Icehouse
    # ** insert magic here **
  end

  def self.find_by_name_for_user(name, user)
    mu = MerchantUser.table_name
    find(:first,
         :conditions => ["#{mu}.user_id = ? AND name = ?", user.id, name],
         :joins => "INNER JOIN #{mu} ON #{mu}.merchant_id = merchants.id")
  end

  # find a merchant by name. this overrides the default find_by_name so we can strip leading and trailing whitespace
  def self.find_by_name(name)
    find(:first, :conditions => ["name = ?", name.strip])
  end

  # find an edited merchant by name. this overrides the default find_by_name so we can strip leading and trailing whitespace
  def self.find_edited_by_name(name)
    find(:first, :conditions => ["name = ? and unedited is not true", name && name.strip])
  end

  # same as find_edited_by_name, but only returns merchants that are visible to the user (which should
  # probably be what find_edited_by_name does)
  def self.find_visible_edited_by_name(name, user)
    merchant = find_edited_by_name(name)
    return merchant if merchant.visible?(user)
  end


  # if the user has created their own edit for this txaction name, find it
  # FIXME: this is not well named, as it returns a Merchant object,
  # not a MerchantUser object. should this method be in MerchantUser instead?
  def self.get_merchant_user(user_id, filtered_txaction_name, sign)
    # don't try to find matches for UNKNOWN transactions (BugzId: 607)
    return nil if filtered_txaction_name.to_s =~ /UNKNOWN(?: PAYEE)?$/

    find(:first,
         :select => "merchants.*",
         :from => "merchants, merchants_users, txactions",
         :conditions => ["merchants_users.user_id = ? \
                           AND txactions.filtered_name = ? \
                           AND txactions.status = ? \
                           AND txactions.merchant_id = merchants.id \
                           AND merchants_users.merchant_id = merchants.id \
                           AND merchants_users.sign = ?",
                           user_id, filtered_txaction_name, Constants::Status::ACTIVE, sign],
         :group => "merchants.id",
         :order => "updated_at desc")
  end

  # return true if the user shops at this merchant or any merchant mapped to this canonical merchant
  def shopped_at_by_user?(user)
    # first just check the merchant itself
    if merchant_user = user.merchant_user(self, -1)
      return true
    elsif canonical
      # this is a canonical merchant, so look to see if the user uses any merchants that map to it
      merchant_id = Merchant.find_value('merchants_users.merchant_id',
        :joins => "JOIN merchants_users ON merchants_users.merchant_id = merchants.id",
        :conditions => ["merchants.canonical_merchant_id = ? and merchants_users.user_id = ?",
                        id, user.id])
      return !merchant_id.nil?
    end

    return false
  end

  # given a list of merchants, return those that the user shops at, taking canonical merchants into consideration
  # also sets the shopped_at_by_user flag for those merchants in the original merchants list
  def self.shopped_at_by_user(user, merchants)
    return [] if merchants.empty?
    merchant_ids = merchants.map(&:id)
    shopped_at_merchants = Merchant.find(:all,
      :select => "merchants.*",
      :joins => "JOIN merchants_users ON merchants_users.merchant_id = merchants.id",
      :conditions => ["(merchants_users.merchant_id in (?) or merchants.canonical_merchant_id in (?)) and merchants_users.user_id = ?",
                      merchant_ids, merchant_ids, user.id],
      :group => "merchants.id")
    # REVIEW: this is a bit weird, modifying merchants that were passed in as a parameter,
    # but we need this flag set in MerchantsController and TagsController, and we need the list of shopped_at_merchants,
    # so I'm doing it here. If anyone has ideas for how to make this less weird, speak up.
    merchants.each {|m| m.shopped_at_by_user = shopped_at_merchants.map {|sam| [sam.id, sam.canonical_merchant_id] }.flatten.compact.uniq.include?(m.id) }
    return shopped_at_merchants
  end

  # return the most common publicly visible merchant for the given filtered name and sign
  def self.get_most_popular_merchant(filtered_name, sign)
    # don't try to find matches for UNKNOWN transactions (BugzId: 607) or ACH PAYMENTs (BugzId: 3321)
    return nil if filtered_name.to_s =~ /UNKNOWN(?: PAYEE)?$/ || filtered_name.to_s == 'ACH PAYMENT/'

    Merchant.find(:first,
                  :select => "merchants.*",
                  :joins => "LEFT OUTER JOIN merchant_bank_names ON merchant_bank_names.merchant_id = merchants.id",
                  :conditions => ["filtered_name = ? AND sign = ? AND unedited = ? AND txactions_count > 1", filtered_name, sign, false],
                  :order => "txactions_count DESC")
  end

  # given a txaction, return a list of the most likely merchants, based on the amount of the
  # txaction and whether it is a check or not
  def self.find_most_likely_merchants(txaction, params = {})
    params = {:check => false, :tolerance => 0.2, :limit => 8}.update(params)
    cc = ConditionsConstructor.new(%{account_id = ? and status = ? and merchant_id is not null
                                     and abs(amount) > ? and abs(amount) < ?},
                                     txaction.account_id,
                                     Constants::Status::ACTIVE,
                                     (txaction.amount * (1 - params[:tolerance])).abs,
                                     (txaction.amount * (1 + params[:tolerance])).abs)
    if params[:check]
      cc.add("check_num is not null and raw_name like '%check%'")
    end

    merchant_ids = Txaction.find(:all, :select => "amount, merchant_id",
                                       :conditions => cc.conditions,
                                       :limit => params[:limit],
                                       :order => "abs(#{quote_value(txaction.amount)} - amount)").map(&:merchant_id)
    Merchant.find(merchant_ids) rescue []
  end

  # return the most popular alias names that start with the given string. This method is
  # called by the auto-completer on the transactions list page
  def self.get_most_popular_starting_with(string, limit = 5)
    Merchant.find(:all,
                  :select => "m.*, count(*) AS count",
                  :from => "merchants m, txactions t",
                  :conditions => ['m.name like ? and t.merchant_id = m.id and t.status = ?',
                                  string + '%', Constants::Status::ACTIVE],
                  :group => 'm.name',
                  :order => 'count desc, name',
                  :limit => limit)
  end

  # return the most common merchants used by the user for the matching the given
  # name
  def self.get_most_popular_by_user_starting_with(user,name,limit=5)
    Merchant.find(:all,
                  :select => 'merchants.*, count(*) AS count',
                  :from => 'accounts, txactions, merchants',
                  :conditions => [
                      "accounts.account_key = ?
                       AND account_id = accounts.id
                       AND accounts.status != ?
                       AND merchants.id = merchant_id
                       AND merchants.name like ?
                       AND txactions.status = ?",
                       user.account_key, Constants::Status::DELETED,
                       "#{name}%", Constants::Status::ACTIVE ],
                  :group => "merchants.id",
                  :order => "count DESC",
                  :limit => limit )
  end

  def self.rename_for_user(user, old_merchant, new_name)
    new_merchant = self.find_by_name(new_name) || Merchant.create!(:name => new_name)
    old_txaction_ids = DataSource::Txaction.new(user) do |ds|
      ds.merchant = old_merchant
    end.txactions.map(&:id)
    Txaction.update_all(["merchant_id = ?", new_merchant.id], ["id IN (?)", old_txaction_ids])
    return new_merchant
  end

  def self.valid_name?(name)
    # not valid to have more than 5 numbers anywhere in a merchant name,
    # or starting or ending with most special characters
    (name.mb_chars =~ /(?:\d\D*){5,}|^[0~`#\$%\^&\*\(\)\-_=\+\[\]\{\}\|\\:;"\,<>\/\?]|[~`#\$\^&\*\(\-_=\[\]\{\}\|\\:;"\,<\.>\/]$/).nil?
  end

  # convenience method for calling valid_name on a merchant object
  def valid_name?
    self.class.valid_name?(name)
  end

  # takes a list of merchant ids and flags them as unedited
  def self.mark_unedited(merchant_ids)
    update_all(["unedited = ?, publicly_visible = ?", true, false], ["id in (?)", merchant_ids]) if merchant_ids && !merchant_ids.empty?
  end

  # takes a list of merchant ids and flags them as non-merchants
  def self.mark_non_merchant(merchant_ids)
    update_all(["non_merchant = ?", true], ["id in (?)", merchant_ids]) if merchant_ids && !merchant_ids.empty?
  end

  # flag the merchant with the given id as canonical
  def self.make_canonical(merchant_id)
    update_all(["canonical = ?", true], ["id = ?", merchant_id]) unless merchant_id.blank?
  end

  # map the given merchant_ids to the canonical_merchant_id
  def self.map_to_canonical(canonical_merchant_id, merchant_ids)
    update_all(["canonical_merchant_id = ?", canonical_merchant_id], ["id in (?)", merchant_ids]) unless merchant_ids && !merchant_ids.empty?
  end

  #----------------------------------------------------------------------------
  # Instance methods
  #

  # Returns the id of the merchant which the user is actually seeing -- either
  # this merchant's id, or the canonical merchant's id if any.
  def visible_id
    return canonical_merchant_id || id
  end

  def destroy
    # null out any Txaction.merchant_ids that point to it
    Txaction.where(:merchant_id => id).update_all(:merchant_id => nil)
    super
  end

  # FIXME: count users with this merchant ourself, since the has_many :through association doesn't count distinct users,
  # and seems to ignore counter_sql
  def uncached_users_count
    MerchantUser.select('DISTINCT user_id').where(:merchant_id => id).count
  end

  # given a user, return boolean for existance of default tags for this
  # merchant.
  def has_default_tags?(user)
    self.default_tags(user).length > 0 ? true : false
  end

  # given a User, return a list of Tags that are marked as default for this
  # Merchant.
  def default_tags(user)
    mu = MerchantUser.get_merchant_user(user,self)
    mu ? mu.tags : []
  end

  # given a string of tags set those tags to be the default. The string of tags
  # can include tag splits, "foo:13"
  def set_default_tags(user, tags, sign = -1)
    AccountMerchantTagStat.increment_tags(user, self, sign, tags)
    if mu = MerchantUser.get_merchant_user(user, self, sign)
      mu.tag_with_splits(tags)
      mu
    end
  end

  # return the most common tag names for this merchant. only return tags that are in
  # use by more than one user.
  def suggested_tags
    Rails.cache.fetch("Merchant:#{id}:suggested_tags", :expires_in => 30.minutes) do
      Tag.suggested_tags_for_merchant(self) || []
    end
  end

  # return string containing the merchant's address in the form:
  #   address1, address2, city, state
  def short_display_address
    [address1, address2, city, state].collect {|field| field.blank? ? nil : field}.compact.join(', ')
  end

  # return list of tags used by the given user for this merchant
  def tags_for_user(user)
    account_ids = user.accounts.visible.map(&:id)
    return [] if account_ids.empty?

    Tag.find(:all, :select => 'tags.*, taggings.name as user_name',
      :joins => "JOIN taggings ON taggings.tag_id = tags.id \
                 JOIN txactions ON taggings.taggable_id = txactions.id AND taggings.taggable_type = 'Txaction'",
      :conditions => ["txactions.merchant_id = ? and txactions.status = ? and txactions.account_id in (?)",
                      id, Constants::Status::ACTIVE, account_ids],
      :order => "user_name",
      :group => "user_name")
  end

  # check to see if the merchant should be shown to the given user
  def visible?(user)
     return publicly_visible? || (user && user.merchant_user(self))
  end

  def publicly_visible?
    true
  end

private

  # Strips any whitespace from the merchant's name. Called before validation,
  # and therefore before creation.
  def strip_whitespace_from_name
    self.name = name.strip if self.name
  end

  private_class_method

  def self.all_publicly_visible_names
    Rails.cache.fetch('all_publicly_visible_names', :expires_in => 1.week) do
      select(:name).where(:publicly_visible => true, :unedited => false).order('users_count DESC, name ASC').map(&:name)
    end
  end
end
# tags concern for Txaction
class Txaction
  has_many :tags,
    :through => :taggings,
    :source => :tag,
    :select => 'tags.*, txaction_taggings.name as user_name'
  has_many :taggings,
    :class_name => "TxactionTagging",
    :dependent => :destroy
  scope :untagged, :conditions => {:tagged => false}
  before_save :cache_tag_names

  # tag the txaction with the given tags returns the tag objects
  # tag_list can either be a tag string or an array of Tags
  # tags will be reloaded by default unless you pass in false as the second argument
  def tag_with(tag_list, reload_tags = true)
    return remove_tags(self.tags) if tag_list.blank?
    new_tags = Tag.parse_to_tags(tag_list)
    tags_to_update = new_tags & self.tags
    tags_to_add = new_tags - self.tags
    tags_to_delete = self.tags - new_tags
    TxactionTagging.transaction do
      tags_to_update.each {|t| update_tagging(t) }
      tags_to_add.each {|t| create_tagging(t) }
      destroy_taggings(tags_to_delete) if tags_to_delete.any?
      update_attribute(:tagged, true)
    end

    self.taggings(reload_tags)
    return self.tags(reload_tags) # need to reload or AR doesn't see the changes
  end

  # tags this transaction, but also tags every untagged transaction with the same merchant
  def tag_this_and_merchant_untagged_with(tag_list)
    self.tag_with(tag_list)
    # don't tag other transactions if this merchant has had autotags disabled
    return if MerchantUser.autotags_disabled?(User.current, merchant, amount.sign)

    non_split_tags = Tag.parse_to_tags(tag_list).reject(&:split)
    to_tag = self.merchant.txactions.with_account_key(self.account.account_key).with_sign(amount.sign).untagged
    to_tag.each{|tx| tx.tag_with(non_split_tags) } # don't propagate splits

    to_tag |= [self]
  end

  # add one or more tags (as a tag string) to this Txaction, making sure we don't duplicate tags
  # tag_list can either be a tag string or an array of Tags
  # tags will be reloaded by default unless you pass in false as the second argument
  def add_tags(tag_list, reload_tags = true)
    new_tags = Tag.parse_to_tags(tag_list)

    tags_to_add = new_tags - self.tags
    if tags_to_add.any?
      TxactionTagging.transaction do
        tags_to_add.each {|t| create_tagging(t) }
        update_attribute(:tagged, true)
      end
    end

    self.taggings(reload_tags)
    return self.tags(reload_tags) # need to reload or AR doesn't see the changes
  end
  alias :add_tag :add_tags

  # update_tags will overwrite any duplicate tags with tags from the tag_list
  # this is only really relevant if there are duplicate tags with differing splits
  def update_tags(tag_list, reload_tags = true)
    new_tags = Tag.parse_to_tags(tag_list)
    return tag_with(new_tags | self.tags, reload_tags)
  end
  alias :update_tag :update_tags

  # remove one or more tags (as a tag string) from this Txaction
  # tag_list can either be a tag string or an array of Tags
  # tags will be reloaded by default unless you pass in false as the second argument
  def remove_tags(tag_list, reload_tags = true)
    tags_to_delete = Tag.parse_to_tags(tag_list)
    TxactionTagging.transaction do
      destroy_taggings(tags_to_delete)
    end if tags_to_delete.any?
    self.taggings(reload_tags)
    current_tags = self.tags(reload_tags)
    update_attribute(:tagged, false) if current_tags.empty?
  end
  alias :remove_tag :remove_tags

  def autotags_for(user)
    AccountMerchantTagStat.autotags_for(user, self.merchant, self.amount.sign) if merchant
  end

  def taggings_to_string(taggings = self.taggings)
    return "" unless taggings
    taggings.map(&:display_name).join(" ")
  end

  def autotags_string(user)
    taggings_to_string(self.autotags_for(user))
  end

  def apply_autotags_for(user)
    autotags = self.autotags_string(user)
    self.tag_with(autotags) if autotags && !autotags.blank?
  end

  # return all transactions belonging to the given user that have the given tag
  # if a :conditions value is provided, that will be passed on to the query
  def self.find_by_user_and_tag(user, tag, options = {})
    account_ids = user.accounts.map(&:id)
    if account_ids.any?
      options.reverse_merge!({:order => "date_posted"})
      # make sure include includes taggings
      options[:include] ||= [:taggings]
      options[:include] |= [:taggings]

      cc = ConditionsConstructor.new(
        'account_id in (?) and txactions.status in (?) and txaction_taggings.tag_id = ?',
        account_ids, VISIBLE_STATUSES, tag.id)
      cc.add(options[:conditions]) if options[:conditions]
      options[:conditions] = cc.conditions

      txactions = Txaction.find(:all, options)
    else
      txactions = []
    end

    return txactions
  end

  def self.find_by_user_and_merchant_and_sign(user, merchant, sign)
    Txaction.
      for_user(user).active.with_sign(sign)
      where(:merchant_id => merchant.id)
  end

  # add the tags on all the user's txactions with the given merchant and sign
  def self.add_tags_for_merchant(user, merchant, sign, tags)
    return if tags.empty?
    find_by_user_and_merchant_and_sign(user, merchant, sign).each {|t| t.add_tags(tags, false) }
    return nil
  end

  # remove the tags on all the user's txactions with the given merchant and sign
  def self.remove_tags_for_merchant(user, merchant, sign, tags)
    return if tags.empty?
    find_by_user_and_merchant_and_sign(user, merchant, sign).each {|t| t.remove_tags(tags, false) }
    return nil
  end

  private

  def cache_tag_names
    self.tag_names = self.taggings.compact.map(&:name).join(" ")
  end

  # create a tagging with the given Tag. Assumes split and user_name has been set on the tag
  def create_tagging(tag)
    # refuse to create taggings with a 0 split
    split_amount = TagParser.calculate_split(tag.name_with_split, self.amount)
    return nil if split_amount == 0
    usd_split_amount = CurrencyExchangeRate.convert_to_usd(split_amount, self.currency, self.date_posted) if split_amount

    taggings.create(
      :tag => tag,
      :name => tag.name_with_split,
      :split_amount => split_amount,
      :usd_split_amount => usd_split_amount)
  end

  def update_tagging(tag)
    # refuse to create taggings with a 0 split
    split_amount = TagParser.calculate_split(tag.name_with_split, self.amount)
    return remove_tags([tag]) if split_amount == 0
    usd_split_amount = CurrencyExchangeRate.convert_to_usd(split_amount, self.currency, self.date_posted) if split_amount

    existing_tag = taggings.find_by_tag_id(tag.id)
    existing_tag.update_attributes(
      :name => tag.name_with_split,
      :split_amount => split_amount,
      :usd_split_amount => usd_split_amount)
  end

  def destroy_taggings(tags)
    TxactionTagging.destroy_all([
      "txaction_id = ? and tag_id in (?)",
      self.id, Array(tags).map(&:id)])
  end

end

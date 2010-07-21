class TxactionTagging < ActiveRecord::Base
  belongs_to :tag
  belongs_to :txaction

  validates_presence_of :tag, :txaction, :name

  after_create :increment_tag_stats
  after_destroy :decrement_tag_stats

  after_save :set_txaction_tagged
  after_destroy :clear_txaction_tagged

  # override the tag association so that we can set the user_name on the tag
  def tag
    tag = Tag.find(tag_id)
    tag.user_name = name
    return tag
  end

  # format a split amount to it's simplest possible representation, either ##
  # or ##.##
  def split_amount_display
    Currency.format(split_amount.abs, currency, :hide_unit => true).sub(/[.,]00$/,'')
  end

  def name_without_split
    name.split(':').first
  end

  def display_name_without_split
    display_name(name_without_split)
  end

  def name
    read_attribute(:tag_name) || read_attribute(:name)
  end

  # quote name if it contains spaces
  def display_name(name = self.name)
    if (name =~ /\s/)
      %{"#{name}"}
    else
      name
    end
  end

  def normalized_name
    Tag.normalize(name)
  end

  def to_param
    param = name.dup
    Tag::OUTGOING_URL_ESCAPES.each{|o,s| param.gsub!(o,s) }
    param
  end

  # update the tag counts in account_merchant_tag_stats
  def increment_tag_stats(merchant = txaction.merchant)
    AccountMerchantTagStat.increment_tags(
      txaction.account.account_key,
      merchant,
      txaction.amount.sign,
      [tag]
    ) if merchant
  end

  # update the tag counts in account_merchant_tag_stats
  def decrement_tag_stats(merchant = txaction.merchant)
    AccountMerchantTagStat.decrement_tags(
      txaction.account.account_key,
      merchant,
      txaction.amount.sign,
      [tag]
    ) if merchant
  end

  # remove duplicate tags from transactions in the given user's accounts
  def self.remove_duplicates(user, tag)
    # the above update will create duplicate taggings on transactions that already have the new tag,
    # so remove those dups
    dup_taggings = find(:all,
      :select => "txaction_taggings.*, count(txaction_taggings.name) as count",
      :joins => "JOIN txactions ON txaction_taggings.txaction_id = txactions.id",
      :conditions => ["account_id in (?) AND tag_id = ?", user.accounts.map(&:id), tag.id],
      :group => "txaction_id, txaction_taggings.name HAVING count > 1")

    dup_taggings.each do |dup|
      # find all dups in the set
      dups = find_all_by_tag_id_and_txaction_id_and_name(dup.tag_id, dup.txaction_id, dup.name)
      ids_to_delete = dups.slice(0, dups.length-1).map(&:id)
      delete(ids_to_delete)
    end
  end

private

  def set_txaction_tagged
    txaction.update_attribute(:tagged, true) unless txaction.tagged
  end

  def clear_txaction_tagged
    txaction.update_attribute(:tagged, false) if txaction.tagged && txaction.tags.count.zero?
  end

end
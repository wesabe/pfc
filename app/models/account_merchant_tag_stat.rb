class AccountMerchantTagStat < ActiveRecord::Base
  belongs_to :merchant
  belongs_to :tag

  validates_presence_of :account_key, :sign, :merchant, :tag, :name

  AUTOTAG_THRESHOLD = 0.8 # minimum percentage of total tags on a merchant required for a tag to be an autotag
  AUTOTAG_MINIMUM_TXACTIONS = 3 # minimum number of taggings needed for something to be an autotag

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

  def self.find_or_create(account_key, merchant_id, sign, tag_id, name = nil)
    id_hash = {:account_key => account_key, :tag_id => tag_id,
      :merchant_id => merchant_id, :sign => sign}
    id_hash.merge!(:name => name) if name

    logger.info("*** [AMTS.find_or_create] id_hash: #{id_hash.inspect}")

    @retried = 0
    begin
      record = self.find(:first, :conditions => id_hash, :include => [:merchant, :tag])

      if record
        logger.info("*** [AMTS.find_or_create] found! record: #{record.inspect}")
      else
        logger.info("*** [AMTS.find_or_create] not found! creating...")

        # Intense debugging info when something seems to have gone wrong
        if @previously_kaboomed
          logger.info("***  tag(#{tag_id})=#{Tag.find(tag_id).name}")
          self.find(:all, :conditions => {:account_key => account_key, :merchant_id => merchant_id}).each do |amts|
            logger.info("***  " + [amts.account_key, amts.merchant_id, amts.name, amts.sign, [amts.tag_id, (amts.tag.name rescue :not_found!)]].inspect)
          end
          Tag.find_all_by_id.each{|tag| logger.info("***  " + [tag.id, tag.name, tag.created_at].inspect) }
        end

        record = self.create(id_hash)
      end
      return record

    rescue ActiveRecord::StatementInvalid => exception
      if @retried < 2
        @retried += 1
        logger.info("*** [AMTS.find_or_create] try #{@retried} kaboomed! message: #{exception.message}")
        @previously_kaboomed = true
        sleep (1 + rand(3))
        retry
      else
        raise
      end
    end

  end

  def self.increment_tags(user_or_account_key, merchant, sign, tags_list)
    self.update_record(user_or_account_key, merchant, sign, tags_list, :change => :increment)
  end

  def self.decrement_tags(user_or_account_key, merchant, sign, tags_list)
    self.update_record(user_or_account_key, merchant, sign, tags_list, :change => :decrement)
  end

  def self.force_on(user_or_account_key, merchant, sign, tags_list)
    self.update_record(user_or_account_key, merchant, sign, tags_list, :force => 1)
  end

  def self.force_off(user_or_account_key, merchant, sign, tags_list)
    self.update_record(user_or_account_key, merchant, sign, tags_list, :force => -1)
  end

  def self.auto_on(user_or_account_key, merchant, sign, tags_list)
    # FIXME: I'm pretty sure this should actually find all the tags for this merchant, and set them _all_ to forced == 0
    self.update_record(user_or_account_key, merchant, sign, tags_list, :force => 0)
  end

  def self.update_record(user_or_account_key, merchant, sign, tags_list, options = {})
    raise ArgumentError unless options.is_a?(Hash) && (options[:change] || options[:force])

    account_key = user_or_account_key.is_a?(String) ? user_or_account_key : user_or_account_key.account_key
    tags = Tag.parse_to_tags(tags_list)
    tags.map do |tag|
      next if tag.split == "0"
      amts = self.find_or_create(account_key, merchant.id, sign, tag.id, tag.name_with_split)

      if options[:force]
        amts.forced = options[:force]
        amts.save!
        next amts
      end

      if (options[:change] == :increment)
        amts.increment!(:count)
      else
        amts.decrement!(:count)
        if amts.count.zero?
          amts.destroy
          next nil
        end
      end

      amts
    end.compact
  end

  def self.autotags_for(user, merchant, sign)
    # first check to see if autotags are disabled for this merchant
    if MerchantUser.autotags_disabled?(user, merchant, sign)
      return []
    end

    manual_mode = self.find(:all, :conditions => {:forced => 1, :sign => sign,
      :account_key => user.account_key, :merchant_id => merchant.id})

    if manual_mode.any?
      autotags = manual_mode
    else # auto mode
      # how many times should a tag have been used to be autotagged
      tags_total = self.total_for_merchant(user, merchant, sign)
      threshold = [(tags_total * AUTOTAG_THRESHOLD).to_i, AUTOTAG_MINIMUM_TXACTIONS].max

      # look for tags that have been used a high enough number of times
      v = {:key => user.account_key, :mid => merchant.id, :n => threshold, :sign => sign}
      c = %{SELECT COALESCE(s2.name, s1.name) as tag_name, SUM(s1.count) as tag_count, s1.*
            FROM account_merchant_tag_stats  s1
            LEFT JOIN account_merchant_tag_stats s2
              ON s1.account_key = s2.account_key
              AND s1.merchant_id = s2.merchant_id
              AND s1.tag_id = s2.tag_id
              AND s2.count > s1.count
            WHERE s1.account_key = :key
              AND s1.merchant_id = :mid
              AND s1.sign = :sign
              AND s1.forced != -1
            GROUP BY s1.tag_id
            HAVING tag_count >= :n}
      autotags = self.find_by_sql([c, v])

      # try inverting sign if we didn't find anything
      if autotags.empty?
        v[:sign] = -v[:sign]
        autotags = self.find_by_sql([c, v])
      end

      autotags.reject!{|n| n.name.include?(":")}
    end

    return autotags
  end

  def self.autotags_string_for(user, merchant, sign)
    self.autotags_for(user, merchant, sign).map(&:display_name).join(" ")
  end

  def self.total_for_merchant(user, merchant, sign)
    c = ConditionsConstructor.new
    c.add "merchant_id = ?", merchant.id
    c.add "accounts.account_key = ?", user.account_key
    c.add "tagged = ?", true
    (sign < 0) ? c.add("amount < 0") : c.add("amount >= 0")
    Txaction.count(:all, :include => :account, :conditions => c.conditions)
  end

  def self.total_for_tag(user, merchant, sign, tag)
    self.sum(:count, :conditions => {
      :account_key => user.account_key,
      :merchant_id => merchant.id,
      :sign => sign,
      :tag_id => tag.id})
  end

  # fix the tag entries and counts for this account_key, and optionally, a set of tags
  def self.fix!(account_key, *tags)
    raise ArgumentError, "No account key!" unless account_key

    tag_ids = tags.map(&:id) if tags

    # iterate through all the user's transactions with merchants, and rebuild the amts entries for that user in a hash
    cc = ConditionsConstructor.new(%{ accounts.account_key = ?
                                      AND txactions.merchant_id IS NOT NULL
                                      AND txaction_taggings.id IS NOT NULL }, account_key)
    cc.add("txaction_taggings.tag_id in (?)", tag_ids) if tag_ids.any?
    txactions = Txaction.
                      select(
                     %{ txactions.merchant_id, txactions.amount,
                        txaction_taggings.tag_id AS tag_id,
                        txaction_taggings.name AS name,
                        COUNT(*) AS count}).
                      joins(
                     %{ JOIN accounts ON txactions.account_id = accounts.id
                        JOIN txaction_taggings ON txaction_taggings.txaction_id = txactions.id }).
                      where(cc.conditions).
                      group('merchant_id, tag_id, name, sign')

    # get user's amts entries as a hash
    amts_hash = {}
    cc = ConditionsConstructor.new("account_key = ?", account_key)
    cc.add("tag_id in (?)", tag_ids) if tag_ids.any?
    where(cc.conditions).each do |amts|
      key = [amts.merchant_id, amts.tag_id, amts.name, amts.sign]
      amts_hash[key] = {'id' => amts.id, 'count' => amts.count, 'forced' => amts.forced}
    end

    AccountMerchantTagStat.transaction do
      # for each entry in the txactions hash, look up the corresponding AMTS entry
      entries_to_create = []
      txactions.each do |txaction|
        key = [txaction.merchant_id, txaction.tag_id, txaction.name, txaction.sign]
        # if the entry is found, update the count, leaving the forced status as is
        if amts_entry = amts_hash[key]
          if amts_entry['count'] != txaction.count
            AccountMerchantTagStat.update(amts_entry['id'], :count => txaction.count)
          end
          amts_hash.delete(key)
        else # if the entry is not found, create it.
          entries_to_create << txaction.attributes.merge(:account_key => account_key)
        end
      end

      # delete any entries in the user's AMTS table that weren't in the hash (this would possibly include forced tags)
      ids_to_delete = amts_hash.values.map {|v| v['id'] }
      AccountMerchantTagStat.delete(ids_to_delete) if ids_to_delete.any?

      # create new entries
      entries_to_create.each {|entry| AccountMerchantTagStat.create!(entry) }
    end
  end
end
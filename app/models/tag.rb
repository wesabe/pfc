class Tag < ActiveRecord::Base
  module Kind
    REPORT_FILTER = "report_filter"
  end

  has_many :taggings, :dependent => :destroy
  has_many :txaction_taggings, :dependent => :delete_all
  has_many :txactions, :through => :txaction_taggings, :conditions => ["txactions.status != ?", Constants::Status::DELETED]
  has_many :recommendation_tags
  has_many :recommendations, :through => :recommendation_tags

  has_many :targets, :dependent => :destroy

  attr_accessor :user_name # the user's version of this tag (e.g. "Restaurants" for "restaurant")
  attr_accessor :split # any split associated with the tag (e.g. foo:3.75 or bar:50%)

  # Spending and earning accesssors
  attr_accessor :current_spending, :average_spending, :total_spending, :average_spending_per_unit, :current_target
  attr_accessor :current_earnings, :average_earnings, :total_earnings, :average_earnings_per_unit

  attr_accessor :merchant_summary # place to cache merchant_summary_for_merchant (set in MerchantSummary)

  validates_presence_of :normalized_name

  INCOMING_URL_ESCAPES = [
    ["/", "-slash-"],
    [".", "-dot-"],
    ["?", "-qmark-"]
  ].freeze

  OUTGOING_URL_ESCAPES = [
    ["/", "-slash-"],
    [".", "-dot-"],
    ["?", "-qmark-"],
    [" ", "+"]
  ].freeze

  def self.decode_name!(name)
    if name
      INCOMING_URL_ESCAPES.each{|o,s| name.gsub!(s,o) }
      return name
    end
  end

  # comparison operator; sort by tag name case-insensitively
  def <=>(other)
    name.casecmp(other.name)
  end

  # the user's version of this tag (e.g. "Restaurants" for "restaurant")
  # this allows us to pull in the user_name in a select (e.g. SELECT tags.*, taggings.name as user_name...)
  def user_name
    read_attribute(:user_name) || @user_name
  end

  def name_with_split
    split ? [user_name, split].join(':') : user_name
  end

  # return a tag given a name
  def self.find_by_name(name)
    if tag = find_by_normalized_name(Tag.normalize(name))
      tag.user_name = name
    end
    tag
  end

  def self.find_all_by_names(names)
    names = Array(names).map{|n| Tag.normalize(n)}
    find(:all, :conditions => { :normalized_name => names }, :group => "normalized_name")
  end

  # Given a tag name, return either the tag with the normalized name or a newly created tag with that normalized name.
  def self.find_or_create_by_name(full_name)
    return nil if full_name.blank?
    (name, split) = full_name.split(':')
    name.strip!
    tag = find_by_name(name) || create(:normalized_name => Tag.normalize(name))
    tag.user_name ||= name
    tag.split ||= split
    tag
  end

  # parse a string of tag names and return a list of tag objects
  # to simplify life for callers, list can either be a string of tags ("foo bar baz"),
  # or an array of strings (["foo", "bar", "baz"]), or even an array of Tag objects, in which
  # case we just return that list
  def self.parse_to_tags(list)
    case list
    when String
      return parse_tag_string_to_tags(list)
    else
      return list.map do |name|
        name.is_a?(Tag) ? name : find_or_create_by_name(name)
      end
    end
  end

  def self.parse_tag_string_to_tags(tag_string)
    TagParser.parse(tag_string).map { |name| find_or_create_by_name(name) }
  end

  # return an array of tags as a space-separated string
  def self.array_to_string(tags)
    tags.map(&:display_name).join(' ')
  end

  # normalize a tag
  def self.normalize(str)
    if str && !str.blank?
      punct_and_space = Oniguruma::ORegexp.new('[\p{Punct}\p{Space}]', "i", "utf8")
      normalized = punct_and_space.gsub(str.singularize, '').downcase
      # if the tag is only 's' or only punctuation, return it instead of ''
      normalized.blank? ? str.downcase.gsub(/ /, '') : normalized
    end
    # FIXME: also do custom normalization (user requests):
    #   clothing => clothe
  end

  def to_s
    name
  end

  def name
    user_name || canonical_name
  end

  def to_param
    param = name.dup
    OUTGOING_URL_ESCAPES.each{|o,s| param.gsub!(o,s) }
    param
  end

  # return the most common non-normalized name for this tag
  def canonical_name
    normalized_name
  end

  # return tag name, but quote it if it contains spaces
  def display_name
    (name =~ /\s/) ? "\"#{name}\"" : name
  end

  # REVIEW: this method should probably be removed
  def on(taggable, split_amount = nil)
    params = {:taggable => taggable, :split_amount => split_amount, :name => name}
    # calculate usd_split_amount
    if split_amount && taggable.is_a?(Txaction)
      params[:usd_split_amount] = CurrencyExchangeRate.convert_to_usd(split_amount, taggable.account.currency, taggable.date_posted)
    end
    taggings.create(params)
  end


  def ==(comparison_object)
    super || name == comparison_object.to_s
  end

  # Getter for the (sometimes) virtual attribute "txaction_count", which is
  # populated by some of the +Tag+ class methods.
  #
  # @return [Fixnum]
  #   The number of transactions this tag has for the current user.
  def txaction_count
    self['txaction_count'].to_i
  end

  def publicly_visible?
    true
  end

  def self.suggested_tags_for_merchant(merchant)
    AccountMerchantTagStat.find(:all,
      :select => "name, sum(count) as total, count(distinct(account_key)) as num_users",
      :conditions => ["merchant_id = ?", merchant.id],
      :group => "tag_id",
      :order => "total desc",
      :limit => 5).find_all {|t| t.num_users.to_i > 1 }.map {|t| t.display_name_without_split.downcase }
  end

  # TODO: rename tag_name in Target
  # rename a user tag. tags can be passed in as a Tag or a String
  # FIXME:  need to also resave the tag_names fields in any affected transactions
  def self.rename(user, old_tag, new_tag)
    Tag.transaction do
      old_tag = find_by_name(old_tag) if old_tag.kind_of?(String)
      new_tag = find_or_create_by_name(new_tag) if new_tag.kind_of?(String)

      # rename non-split taggings
      connection.execute(
        [%{ UPDATE txaction_taggings, txactions SET txaction_taggings.tag_id = ?, txaction_taggings.name = ?
            WHERE txaction_taggings.tag_id = ?
            AND txaction_taggings.split_amount IS NULL
            AND txaction_taggings.txaction_id = txactions.id
            AND txactions.account_id in (?) },
          new_tag.id, new_tag.name, old_tag.id, user.accounts.map(&:id)]
      )

      # the above update will create duplicate taggings on transactions that already have the new tag, so remove those dups
      TxactionTagging.remove_duplicates(user, new_tag)

      # rename split taggings
      # since the name field of txaction_taggings has "tag:<split>", we need to update these individually
      # (note that the split here isn't necessarily the same as the split_amount--e.g. "foo:50%")
      taggings = TxactionTagging.find(:all,
        :select => "txaction_taggings.*",
        :joins => "JOIN txactions ON txaction_taggings.txaction_id = txactions.id",
        :conditions => [
          %{ txactions.account_id in (?)
             AND txaction_taggings.tag_id = ?
             AND txaction_taggings.split_amount IS NOT NULL },
          user.accounts.map(&:id), old_tag.id])

      taggings.each do |tagging|
        parts = tagging.name.split(':') # just get split part of name
        if parts.length > 1
          tagging.name = [new_tag.name, parts.last].join(':')
          tagging.save
        end
      end

      # rename target tags
      if target = Target.for_tag(old_tag, user)
        target.tag = new_tag
        target.save!
      end

      # update AMTS entries via Delayed Job
      # FIXME: this isn't ideal, but using DJ breaks TagSpec. The fix is
      # to move the AMTS tests in TagSpec to the AMTS spec, testing AMTS.fix! separately
      AccountMerchantTagStat.send_later(:fix!, user.account_key, old_tag, new_tag)
    end
  end

  # replace a user tag with one or more tags. The original tag can be passed in by id or name; the replacement
  # tags is either an array of tags or a string that will be parsed out into individual tags
  def self.replace(user, old_tag_name, replacement_tags)
    old_tag_name = *old_tag_name
    replacement_tags = Tag.parse_to_tags(replacement_tags)
    return if replacement_tags.empty?
    old_tag = Tag.find_by_name(old_tag_name)

    # if there's only one replacement tag, just do a straight rename
    return rename(user, old_tag, replacement_tags[0]) if replacement_tags.size == 1

    Tag.transaction do
      # get all one-time and cached merchant tags
      taggings = TxactionTagging.find(:all, :from => 'txaction_taggings, txactions',
                              :conditions => ["txaction_taggings.name = ? and txaction_taggings.txaction_id = txactions.id \
                                 and txactions.account_id in (?)",
                                 old_tag_name, user.accounts.map(&:id)])

      keep_old_tag = false
      for tagging in taggings
        # create new taggings for the replacement tags
        for tag in replacement_tags
          # if one of the replacements is the original tag, no need to create a new one; just don't delete it
          if tag.name == old_tag.name
            keep_old_tag = true
            next
          end
          if tagging.is_a?(TxactionTagging)
            TxactionTagging.create(:tag_id => tag.id,
                                   :name => tag.name,
                                   :txaction_id => tagging.txaction_id,
                                   :split_amount => tagging.split_amount)
          else
            Tagging.create(:tag_id => tag.id,
                           :name => tag.name,
                           :taggable_id => tagging.taggable_id,
                           :taggable_type => tagging.taggable_type,
                           :split_amount => tagging.split_amount,
                           :kind => tagging.kind)
          end
        end
      end

      # the above will create duplicate taggings on transactions that already have the new tag, so remove those dups
      replacement_tags.each {|tag| TxactionTagging.remove_duplicates(user, tag) }

      # FIXME: if a target tag is replaced with multiple different tags, what happens to the target?
      # filed a bug on this (15992). For now, just use the first replacement tag
      if !keep_old_tag && target = Target.for_tag(old_tag, user)
        target.tag = replacement_tags.first
        target.save!
      end

      # delete original tag if it wasn't one of the replacement tags
      destroy(user, old_tag) unless keep_old_tag

      # update AMTS entries via Delayed Job
      # FIXME: this isn't ideal, but using DJ breaks TagSpec. The fix is
      # to move the AMTS tests in TagSpec to the AMTS spec, testing AMTS.fix! separately
      AccountMerchantTagStat.send_later(:fix!, user.account_key, old_tag, replacement_tags)
    end

    # return ids of replacement tags
    return replacement_tags.map(&:id)
  end

  # delete a user tag. tags can be passed in by id or name
  def self.destroy(user, tag)
    tag = *tag
    tag = find_by_name(tag) if tag.kind_of?(String)

    # delete taggings
    connection.execute(
      ["DELETE txaction_taggings FROM txaction_taggings, txactions \
        WHERE txaction_taggings.tag_id = ? \
        AND txaction_taggings.txaction_id = txactions.id \
        AND txactions.account_id in (?)",
        tag.id, user.accounts.map(&:id)])

    # mark all txactions that are now untagged as untagged
    connection.execute([
      "UPDATE txactions \
      LEFT OUTER JOIN txaction_taggings \
      ON txaction_taggings.txaction_id = txactions.id \
      SET tagged = 0 \
      WHERE txaction_taggings.id IS NULL \
      AND txactions.account_id IN (?)",
      user.accounts.map(&:id)])

    # delete targets w/ this tag
    if target = Target.for_tag(tag, user)
      target.destroy
    end
  end

  # return all unique tags for a user. if all is true, then don't group by normalized name
  def self.tags_for_user(user, all = nil)
    # get list of tags, but group by unnormalized name instead of tag.id so we can identify the most common
    # unnormalized tag out of sets of tags with the same normalized name
    account_ids = user.accounts.visible.map(&:id)
    return [] if account_ids.empty?
    tags = Tag.find(:all,
                    :select => "tags.*, \
                                SUBSTRING_INDEX(txaction_taggings.name,':',1) AS user_name, \
                                count(tags.id) as txaction_count",
                    :joins => "JOIN txaction_taggings ON txaction_taggings.tag_id = tags.id \
                               JOIN txactions ON txaction_taggings.txaction_id = txactions.id",
                    :conditions => ["txactions.account_id in (?)", account_ids],
                    :group => "user_name",
                    :order => "tags.normalized_name, txaction_count desc").each {|t| t.user_name = t['user_name']}

    if all
      return tags.sort
    else
      # collapse tags with the same normalized name, updating the tag count to get the total
      tag_hash = {}
      tags.each do |tag|
        if tag_hash[tag.normalized_name]
          tag_hash[tag.normalized_name].txaction_count = tag_hash[tag.normalized_name].txaction_count.to_i + tag.txaction_count.to_i
        else
          tag_hash[tag.normalized_name] = tag
        end
      end
      return tag_hash.values.sort
    end
  end

  def self.filter_tags_for_user(user)
    find(:all,
      :select => 'tags.*, taggings.name as user_name',
      :joins => "join taggings on taggings.tag_id = tags.id",
      :conditions => ['taggable_id = ? and taggable_type = ? and taggings.kind = ?',
        user.id, User.to_s, Kind::REPORT_FILTER])
  end

  # like the above, but just return tag_ids. Saves a join, and cachable
  def self.filter_tag_ids_for_user(user)
    cached(:id => user.account_data_cache_key.merge(:filter_tag_ids => true)) do
      Tagging.where(["taggings.taggable_id = ? AND taggings.taggable_type = ? AND taggings.kind = ?",
                       user.id, User.to_s, Kind::REPORT_FILTER]).maximum(:tag_id)
    end
  end
end

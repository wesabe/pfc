# base class for commonalities between Txaction and InvestmentTxaction DataSources
class DataSource::AbstractTxaction
    # An exception raised when a method is called in a loaded data source which
    # requires that the data source not be loaded.
    class ReadOnlyError < StandardError ; end

    include Enumerable

    # Query conditions
    attr_reader :accounts, :merchants, :start_date, :end_date, :statuses, :amount

    # Tag conditions
    attr_reader :tags, :filtered_tags, :required_tags

    # Options
    attr_reader :include_balances, :rationalize, :filter_transfers, :unedited, :untagged

    def initialize(user, paginator = nil)
      @user             = user
      @accounts         = []
      @merchants        = []
      @tags             = []
      @filtered_tags    = []
      @required_tags    = []
      @statuses         = ::Txaction::VISIBLE_STATUSES
      @paginator        = paginator
      @include_balances = false
      @rationalize      = false
      @filter_transfers = false
      @unedited         = false
      @untagged         = false
      @loaded           = false
      if block_given?
        yield self
        load!
      end
    end

    # Returns +true+ if the data source has loaded the transactions from the
    # database, +false+ otherwise.
    def loaded?
      return @loaded
    end

    # Loads the transactions from the database. Returns +true+ if the database was
    # queried, +false+ if the transactions were already loaded.
    def load!
      unless @loaded
        @txactions = find_all_txactions
        rationalize! if rationalize
        return @loaded = true
      end
      return false
    end

    def total_entries
      @total_entries ||= ::Txaction.count(:all, build_options.except(:limit, :offset))
    end

    def rationalize!
      # 3: create the list of tags with total spending per tag
      tags_priority = {}
      tags_priority.default = 0
      @txactions.each do |tx|
        tx.tags.each do |tag|
          # don't include required tags. you don't want to include the
          # food tag if every transaction is already tagged food.
          unless @required_tags.include?(tag)
            tags_priority[tag] += tx.usd_amount(:tag => tag).abs
          end
        end
      end
      tags_priority = tags_priority.to_a

      # 4: sort the list of tags by value per tag and then frequency of use on wesabe
      tags_priority.sort! do |x,y|
        # try comparing values first
        case y[1] <=> x[1]
        when -1
          -1
        when 1
          1
        when 0
          # if values are the same, then pick the more popular one
          y[2] ||= y[0].txaction_taggings.count
          x[2] ||= x[0].txaction_taggings.count
          y[2] <=> x[2]
        end
      end
      tags_priority.map!{|tag, priority| tag }

      # 5: replace the array of tags on each txaction with the highest-priority tag
      # !!!
      @txactions.each do |tx|
        priority_tag = tags_priority.detect{|n| tx.tag_ids.include?(n.id) }
        tx.rational_tag = [tx.taggings.detect{|n| n.tag_id == priority_tag.id }] if priority_tag
        tx.rational_tag.first.name = priority_tag.name if tx.rational_tag && tx.rational_tag.any?
      end

      return @txactions
    end

    # Sorts the data source's transactions in place.
    def sort!(&block)
      return txactions.sort!(&block)
    end

    # Returns +true+ if the data source is loaded but has no transactions, +false+
    # otherwise.
    def empty?
      return txactions.empty?
    end

    # Returns the number of transactions in the data source. Only valid for loaded
    # data sources.
    def size
      return txactions.size
    end
    alias_method :length, :size

    # The Txaction objects in the data source. Will fetch from the database if needed.
    def txactions
      load! unless loaded?
      return @txactions
    end

    # Iterates over each transaction in the data source. Only valid for loaded
    # data sources.
    def each(&block)
      txactions.each(&block)
    end

    # Sets an account constraint on the data source. All transactions in the data
    # source will belong to the account(s) in +accounts+.
    #
    # ==== Examples
    #
    #   data_source.account = @account
    #   data_source.accounts = [@account1, @account2]
    #
    # Only valid for unloaded data sources.
    def accounts=(accounts)
      # TODO: should this check to make sure the account belongs to the user?
      assert_unloaded
      @accounts = Array(accounts)
    end
    alias_method :account=, :accounts=

    # Sets an merchant constraint on the data source. All transactions in the data
    # source will belong to the merchant(s) in +merchants+.
    #
    # ==== Examples
    #
    #   data_source.merchant = @merchant
    #   data_source.merchants = [@merchant1, @merchant2]
    #
    # Only valid for unloaded data sources.
    def merchants=(merchants)
      assert_unloaded
      @merchants = Array(merchants)
    end
    alias_method :merchant=, :merchants=

    # Sets a tag constraint on the data source. All transactions in the data
    # source will belong to the tag(s) in +tags+.
    #
    # ==== Examples
    #
    #   data_source.tag = @tag
    #   data_source.tags = [@tag1, @tag2]
    #
    # Only valid for unloaded data sources.
    def tags=(tags)
      assert_unloaded
      @tags = names_to_tags(tags)
    end
    alias_method :tag=, :tags=

    # Sets a filtered tag constraint on the data source. Any transactions in
    # the data source with a tag in +filtered_tags+ will not be returned.
    #
    # ==== Examples
    #
    #   data_source.filtered_tag = @tag
    #   data_source.filtered_tags = [@tag1, @tag2]
    #
    # Only valid for unloaded data sources.
    def filtered_tags=(filtered_tags)
      assert_unloaded
      @filtered_tags = names_to_tags(filtered_tags)
    end
    alias_method :filtered_tag=, :filtered_tags=

    # Sets a required tag constraint on the data source. Any transactions in
    # the data source without every tag in +required_tags+ will not be returned.
    #
    # ==== Examples
    #
    #   data_source.required_tag = @tag
    #   data_source.required_tags = [@tag1, @tag2]
    #
    # Only valid for unloaded data sources.
    def required_tags=(required_tags)
      assert_unloaded
      @required_tags = names_to_tags(required_tags)
    end
    alias_method :required_tag=, :required_tags=

    # Sets the +include_balances+ option. If +true+, the data source will include
    # account-level balance data for each transaction. Only valid for unloaded
    # data sources.
    def include_balances=(include_balances)
      assert_unloaded
      @include_balances = include_balances
    end

    # Sets the +filter_transfers+ option. If +true+, the data source will not
    # include transactions that have been marked as account-to-account transfers.
    # Only valid for unloaded data sources.
    def filter_transfers=(filter_transfers)
      assert_unloaded
      @filter_transfers = filter_transfers
    end

    # Sets the +unedited+ option. If +true+, the data source will only
    # include transactions that are not associated with a merchant.
    # Only valid for unloaded data sources.
    def unedited=(unedited)
      assert_unloaded
      @unedited = unedited unless unedited.blank?
    end

    # Sets the +untagged+ option. If +true+, the data source will only
    # include transactions that have not been tagged.
    # Only valid for unloaded data sources.
    def untagged=(untagged)
      assert_unloaded
      @untagged = untagged unless untagged.blank?
    end

    # Sets the +rationalize+ option. If +true+, the data source will rationalize
    # the tags of returned transactions. Only valid for unloaded data sources.
    def rationalize=(rationalize)
      assert_unloaded
      @rationalize = rationalize
    end

    # Sets a starting date constraint on the data source. All transactions in the
    # data source will have a +date_posted+ later than or equal to +start_date+.
    # Only valid for unloaded data sources.
    def start_date=(start_date)
      assert_unloaded
      @start_date = start_date
    end

    # Sets an ending date constraint on the data source. All transactions in the
    # data source will have a +date_posted+ earlier than or equal to +end_date+.
    # Only valid for unloaded data sources that do not have an +end_time+.
    def end_date=(end_date)
      assert_unloaded
      raise ArgumentError, "you have already set end_time" if @end_time
      @end_date = end_date
    end

    # Sets an ending time constraint on the data source. All transactions in the
    # data source will have a +date_posted+ earlier than or equal to +end_time+.
    # Only valid for unloaded data sources that do not have an +end_date+.
    def end_time=(end_time)
      assert_unloaded
      raise ArgumentError, "you have already set end_date" if @end_date
      @end_time = end_time
    end

    # Sets a sequence constraint on the data source. All transactions in the
    # data source will have a +sequence+ higher than or equal to +sequence+.
    # Only valid for unloaded data sources.
    def sequence=(sequence)
      assert_unloaded
      raise ArgumentError, "you have already set sequence" if @sequence
      @sequence = sequence
    end

    # Sets a status constraint on the data source. All transactions in the data
    # source will have the status(s) in +statuses+.
    #
    # ==== Examples
    #
    #   data_source.status = @status
    #   data_source.statuses = [@status1, @status2]
    #
    # Only valid for unloaded data sources.
    def statuses=(statuses)
      assert_unloaded
      @statuses = Array(statuses)
    end
    alias_method :status=, :statuses=

    # Sets an amount constraint on the data source. If amount is set to "negative",
    # only transactions with a negative value will be included. If "positive", then
    # only positive transactions will be included. If amount is not set to one of
    # those options, transactions with any amount will be included.
    # Only valid for unloaded data sources.
    def amount=(amount)
      assert_unloaded
      @amount = amount.to_s unless amount.blank?
      @amount = "positive" if ("earnings" == @amount)
      @amount = "negative" if ("spending" == @amount)
    end

  private

    def assert_unloaded
      if loaded?
        raise ReadOnlyError, "data source is already loaded"
      else
        return true
      end
    end

    def names_to_tags(names)
      tags = Array(names).map{|n| n.is_a?(String) ? Tag.find_by_name(n) : n }
      if tags.any? { |tag| tag.nil? }
        raise ActiveRecord::RecordNotFound, "couldn't find tags #{names.inspect}"
      else
        return tags
      end
    end

    def account_ids
      (@accounts.empty? ? @user.accounts : @accounts).map { |a| a.id }
    end

    def build_conditions
      cc = ConditionsConstructor.new(@paginator ? @paginator.conditions.dup : {})
      cc.add("txactions.account_id" => account_ids)
      cc.add("txactions.merchant_id" => @merchants.map { |m| m.id }) if @merchants.any?
      cc.add("txactions.status" => @statuses) if @statuses.any?

      if @start_date.is_a?(String)
        @start_date = Time.parse(@start_date) rescue nil
      end
      if @end_date.is_a?(String)
        @end_date = Time.parse(@end_date) rescue nil
      end
      cc.add("txactions.date_posted >= ?", @start_date)          if @start_date
      cc.add("txactions.date_posted <= ?", @end_date.end_of_day) if @end_date
      cc.add("txactions.date_posted <= ?", @end_time)            if @end_time

      cc.add("txactions.sequence >= ?",    @sequence)            if @sequence

      cc.add("txactions.amount > 0") if ("positive" == @amount)
      cc.add("txactions.amount < 0") if ("negative" == @amount)

      cc.add("txactions.transfer_txaction_id IS NULL") if @filter_transfers

      cc.add('txactions.merchant_id IS NULL')          if @unedited
      cc.add('txactions.tagged = 0')                   if @untagged
      cc.add('txactions.transfer_txaction_id IS NULL') if @untagged

      # Included tag join conditions to eliminate txactions without at least one of the included tags
      cc.add("included_taggings.tag_id" => @tags.map { |m| m.id }) if @tags.any?

      # Filtered tag left outer join conditions to eliminate txactions with a filtered tag and also lacking split tags
      cc.add("(filtered_taggings.txaction_id IS NOT NULL AND split_taggings.split_amount IS NOT NULL) OR (filtered_taggings.txaction_id IS NULL)") if @filtered_tags.any?

      # Required tag left outer join conditions to eliminate txactions without all the required tags
      cc.add("required_taggings.times_tagged = ?", @required_tags.size) if @required_tags.any?

      return cc.conditions
    end

    def build_joins
      joins_array = []

      if @tags.any?
        joins_array << %{JOIN txaction_taggings AS included_taggings ON included_taggings.txaction_id = txactions.id}
      end

      if @filtered_tags.any?
        joins_array << %{LEFT OUTER JOIN txaction_taggings
          AS filtered_taggings ON (
            filtered_taggings.txaction_id = txactions.id AND
            filtered_taggings.tag_id IN (#{@filtered_tags.map(&:id).join(',')})
          )}
        joins_array << %{LEFT OUTER JOIN txaction_taggings
          AS split_taggings ON (
            split_taggings.txaction_id = txactions.id AND
            split_taggings.split_amount IS NOT NULL
          )}
      end

      if @required_tags.any?
        joins_array << %{LEFT OUTER JOIN (
          SELECT txaction_id, COUNT(*) AS times_tagged
          FROM txaction_taggings
          WHERE tag_id IN (#{@required_tags.map(&:id).join(',')})
          GROUP BY txaction_id
        ) AS required_taggings ON
          required_taggings.txaction_id = txactions.id}
      end

      return joins_array.join(" ").squeeze(" ").gsub("\n", "")
    end

    def build_options
      options = {}
      options[:order]   = "txactions.date_posted DESC, txactions.sequence ASC, " +
        "txactions.created_at DESC, txactions.id ASC"
      options[:joins]   = build_joins if (@filtered_tags.any? || @required_tags.any? || @tags.any?)
      options[:limit]   = @paginator.limit if @paginator
      options[:offset]  = @paginator.offset if @paginator
      options[:conditions] = build_conditions

      unless rationalize
        options[:include] = [:merchant, :account, :taggings]
      else
        options[:include] = [:merchant, :account, {:taggings => :tag}, :txaction_type]
      end

      return options
    end

    def find_all_txactions
      txactions = ::Txaction.find(:all, build_options)
      ::Txaction.generate_balances!(txactions) if include_balances
      return txactions
    end

end

# REVIEW: This should be moved into the lib directory.
# FIXME: we should move this into a Reports controller

class TagsSpendingSummary
  def self.generate(user, options = {})
    average_tags = calculate_spending_summary(user, options.update( :period => options[:average_period] ))
    current_tags = calculate_spending_summary(user, options.update( :period => options[:current_period] ))

    # make sure we include any required tags (e.g. targets)
    for required_tag in ((options[:tags] || []) + (options[:required_tags] || [])).uniq
      unless current_tags.include?(required_tag)
        ActiveRecord::Base.logger.debug required_tag.inspect
        required_tag.send(:total_spending=, 0)
        required_tag.send(:total_earnings=, 0)
        current_tags << required_tag
      end
    end

    # set the various spending summary attributes
    tags = current_tags.map do |current_tag|
      average_tag = average_tags.find{ |t| t.id == current_tag.id }
      average_spending = average_tag ? average_tag.total_spending : 0
      average_earnings = average_tag ? average_tag.total_earnings : 0
      current_tag.current_spending = current_tag.total_spending.abs
      current_tag.current_earnings = current_tag.total_earnings.abs
      current_tag.average_spending = average_spending.to_f.abs
      current_tag.average_earnings = average_earnings.to_f.abs
      current_tag.average_spending_per_unit = average_spending / ((options[:average_period].end - options[:average_period].begin) / 1.month)
      current_tag.average_earnings_per_unit = average_earnings / ((options[:average_period].end - options[:average_period].begin) / 1.month)
      current_tag.current_target = user.targets.to_a.find{ |t| t.tag_id == current_tag.id }
      current_tag
    end

    if options[:type] == :spending
      tags.sort {|a,b| b.current_spending <=> a.current_spending }
    else
      tags.sort {|a,b| b.current_earnings <=> a.current_earnings }
    end
  end

  # Return a list of tags for a logged-in user. Each tag includes the total
  # spent on that tag since the given date, as total_spending.
  # options:
  #  :tags - array of tags over which to generate the summary; if not specified, all of the user's tags are used
  #  :period - date range of summary
  #  :type - :spending or :earnings or :txaction
  def self.calculate_spending_summary(user, options = {})
    accounts = user.accounts
    return [] if accounts.empty?

    options[:tags] = [options[:tags]] if options[:type] == :txaction
    tags = ( options[:tags] || (user.tags - user.filter_tags) )
    return [] if tags.empty?

    txactions = DataSource::Txaction.new(user) do |ds|
      ds.accounts = accounts
      ds.tags = tags
      ds.filtered_tags = user.filter_tags unless options[:tags]
      ds.start_date = options[:period].begin
      ds.end_date   = options[:period].end if options[:type] != :txaction
      ds.end_time   = options[:period].end if options[:type] == :txaction
      ds.sequence   = options[:sequence]
      ds.filter_transfers = options[:ignore_transfers]
      ds.rationalize = options[:rational]
    end.txactions

    # build a hash of tag_ids and their net spending and earning amount
    tag_total_hash = Hash.new(0)
    tag_total_spending_hash = Hash.new(0)
    tag_total_earnings_hash = Hash.new(0)
    txactions.each do |tx|
      taggings = ( options[:rational] ? tx.rational_tag : tx.taggings )
      taggings.each do |t|
        original_amount = (t.split_amount || tx.amount)
        amount = CurrencyExchangeRate.convert(original_amount, tx.currency, user.default_currency, tx.date_posted)
        tag_total_hash[t.tag_id.to_i] += amount
      end
    end
    tag_total_hash.each do |id, amount|
      if amount < 0
        tag_total_spending_hash[id] = amount
      else
        tag_total_earnings_hash[id] = amount
      end
    end

    # set the total_spending attribute in the tags
    tags.each do |tag|
      tag.total_spending = tag_total_spending_hash[tag.id]
      tag.total_earnings = tag_total_earnings_hash[tag.id]
    end

    # only return tags on which we've spent money if type == :spending, and visa versa
    # if type isn't set, it returns all tags that have earning or spending.
    if options[:type] == :earnings
      tags.select {|t| t.total_earnings != 0 } || []
    elsif options[:type] == :spending
      tags.select {|t| t.total_spending != 0 } || []
    elsif options[:type] == :txaction
      [tags.first] || []
    else
      tags.select {|t| t.total_spending != 0 || t.total_earnings != 0 } || []
    end
  end
end

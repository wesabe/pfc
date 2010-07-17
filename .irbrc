# Some niceness for using the pfc console

# Find users by typing their username
def username(name)
  User.find_by_username(name.to_s)
end

# Authenticate by username and password
def auth(username, password)
  User.authenticate(username, password)
end

# Filter transactions
def f(string)
  TxactionFilter.filter(string.to_s)
end

# Find account
def a(id)
  Account.find(id.to_i)
end

# Re-filter txactions in account
def refilter(account_or_id)
  if account_or_id.is_a?(Account)
    account = account_or_id
  else
    account = Account.find(account_or_id.to_i)
  end
  account.txactions.each do |tx|
    tx.generate_filtered_and_cleaned_names!
    tx.save
  end
  puts "refiltered #{account.txactions.size} txactions"
  return account.txactions.size
end

### http://gist.github.com/72234.git
# mysql-style output for an array of Ruby objects
#
# Usage:
#   report(records)  # displays report with all fields
#   report(records, :field1, :field2, ...) # displays report with given fields
#
# Example:
# >> report(records, :id, :amount, :created_at)
# +------+-----------+--------------------------------+
# | id   | amount    | created_at                     |
# +------+-----------+--------------------------------+
# | 8301 | $12.40    | Sat Feb 28 09:20:47 -0800 2009 |
# | 6060 | $39.62    | Sun Feb 15 14:45:38 -0800 2009 |
# | 6061 | $167.52   | Sun Feb 15 14:45:38 -0800 2009 |
# | 6067 | $12.00    | Sun Feb 15 14:45:40 -0800 2009 |
# | 6059 | $1,000.00 | Sun Feb 15 14:45:38 -0800 2009 |
# +------+-----------+--------------------------------+
# 5 rows in set
#
def report(items, *fields)
  # find max length for each field; start with the field names themselves
  fields = items.first.attribute_names unless fields.any?
  max_len = Hash[*fields.map {|f| [f, f.to_s.length]}.flatten]
  items.each do |item|
    fields.each do |field|
      len = item.send(field).to_s.length
      max_len[field] = len if len > max_len[field]
    end
  end

  border = '+-' + fields.map {|f| '-' * max_len[f] }.join('-+-') + '-+'
  title_row = '| ' + fields.map {|f| sprintf("%-#{max_len[f]}s", f.to_s) }.join(' | ') + ' |'

  puts border
  puts title_row
  puts border

  items.each do |item|
    row = '| ' + fields.map {|f| sprintf("%-#{max_len[f]}s", item.send(f)) }.join(' | ') + ' |'
    puts row
  end

  puts border
  puts "#{items.length} rows in set\n"
end
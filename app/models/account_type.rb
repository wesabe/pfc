# this used to be in a table, but the values are limited and fixed, so no need to have a real table
# FIXME: Now that BRCM has its own AccountType, it might make sense to make this a table again
class AccountType < ActiveRecord::BaseWithoutTable
  column :raw_name, :string
  column :name, :string
  column :visible, :boolean
  column :has_balance, :boolean
  column :has_fi, :boolean
  column :has_uploads, :boolean

  UNKNOWN = 1
  CHECKING = 2
  MONEYMRKT = 3
  CREDITCARD = 4
  SAVINGS = 5
  CREDITLINE = 7
  BROKERAGE = 8
  CASH = 9
  MANUAL = 10
  INVESTMENT = 11
  CERTIFICATE = 12
  LOAN = 13
  MORTGAGE = 14

  ACCOUNT_TYPES = {
    UNKNOWN     => new(:raw_name => 'UNKNOWN',
                       :name => nil,
                       :visible => 0,
                       :has_balance => true,
                       :has_fi => nil,
                       :has_uploads => true),
    CHECKING    => new(:raw_name => 'CHECKING',
                       :name => 'Checking',
                       :visible => 1,
                       :has_balance => true,
                       :has_fi => true,
                       :has_uploads => true),
    MONEYMRKT   => new(:raw_name => 'MONEYMRKT',
                       :name => 'Money Market',
                       :visible => 1,
                       :has_balance => true,
                       :has_fi => true,
                       :has_uploads => true),
    CREDITCARD  => new(:raw_name => 'CREDITCARD',
                       :name => 'Credit Card',
                       :visible => 1,
                       :has_balance => true,
                       :has_fi => true,
                       :has_uploads => true),
    SAVINGS     => new(:raw_name => 'SAVINGS',
                       :name => 'Savings',
                       :visible => 1,
                       :has_balance => true,
                       :has_fi => true,
                       :has_uploads => true),
    CREDITLINE  => new(:raw_name => 'CREDITLINE',
                       :name => 'Credit Line',
                       :visible => 1,
                       :has_balance => true,
                       :has_fi => true,
                       :has_uploads => true),
    BROKERAGE   => new(:raw_name => 'BROKERAGE',
                       :name => 'Brokerage',
                       :visible => 1,
                       :has_balance => true,
                       :has_fi => true,
                       :has_uploads => true),
    CASH        => new(:raw_name => 'CASH',
                       :name => 'Cash',
                       :visible => 1,
                       :has_balance => false,
                       :has_fi => false,
                       :has_uploads => false),
    MANUAL      => new(:raw_name => 'MANUAL',
                       :name => 'Manual',
                       :visible => 0,
                       :has_balance => true,
                       :has_fi => false,
                       :has_uploads => false),
    INVESTMENT  => new(:raw_name => 'INVESTMENT',
                      :name => 'Investment',
                      :visible => 1,
                      :has_balance => true,
                      :has_fi => true,
                      :has_uploads => true),
    CERTIFICATE  => new(:raw_name => 'CERTIFICATE',
                      :name => 'Certificate of Deposit',
                      :visible => 0,
                      :has_balance => true,
                      :has_fi => true,
                      :has_uploads => true),
    LOAN  => new(:raw_name => 'LOAN',
                      :name => 'Loan',
                      :visible => 0,
                      :has_balance => true,
                      :has_fi => true,
                      :has_uploads => true),
    MORTGAGE  => new(:raw_name => 'MORTGAGE',
                      :name => 'Mortgage',
                      :visible => 0,
                      :has_balance => true,
                      :has_fi => true,
                      :has_uploads => true)
  }

  def id
    "#{self.class}::#{raw_name}".constantize
  end

  def to_s
    name || ''
  end

  def self.find(id)
    if id == :all
      ACCOUNT_TYPES.values
    else
      ACCOUNT_TYPES[id]
    end
  end

  def self.visible_names
    ACCOUNT_TYPES.values.select {|t| t.visible }.map(&:name).sort
  end

  # not your standard find; allow a little leeway in the raw name
  def self.find_by_raw_name(name)
    case name
    when /CHECKING/i
      ACCOUNT_TYPES[CHECKING]
    when /(CREDIT\s*CARD)|^2$/i   # PC Financial credit cards gives an account type of "2" (BugzId:17943)
      ACCOUNT_TYPES[CREDITCARD]
    when /CREDIT\s*LINE/i, /LOC/i
      ACCOUNT_TYPES[CREDITLINE]
    when /MONEY\s*MA?RKE?T/i
      ACCOUNT_TYPES[MONEYMRKT]
    when /SAVINGS/i
      ACCOUNT_TYPES[SAVINGS]
    when /BROKERAGE/i
      ACCOUNT_TYPES[BROKERAGE]
    when /CASH/i
      ACCOUNT_TYPES[CASH]
    when /MANUAL/i
      ACCOUNT_TYPES[MANUAL]
    when /INVEST/i
      ACCOUNT_TYPES[INVESTMENT]
    when /CERTIFICATE/i
      ACCOUNT_TYPES[CERTIFICATE]
    when /LOAN/i
      ACCOUNT_TYPES[LOAN]
    when /MORTGAGE/i
      ACCOUNT_TYPES[MORTGAGE]
    else
      ACCOUNT_TYPES[UNKNOWN]
    end
  end
end

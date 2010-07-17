class InvestmentTxaction < ActiveRecord::Base
  include AbstractTxaction

  belongs_to :investment_security

  validates_presence_of :investment_security, :upload

  before_create :generate_wesabe_txid
  before_create :check_for_duplicate

  # alias trade_date as date_posted and amount as total to help pretend we're a normal Txaction
  alias_attribute :date_posted, :trade_date
  alias_attribute :amount, :total

  TYPES = {
    "CGLONG" => "Capital Gains-Long Term",
    "CGSHORT" => "Capital Gains-Short Term",
    "DIV" => "Dividend",
    "INTEREST" => "Interest",
    "MISC" => "Misc",
    "BUY" => "Buy",
    "BUYTOCOVER" => "Buy to Cover",
    "SELL" => "Sell",
    "SELLSHORT" => "Short Sell"
  }

  def self.find_by_wesabe_txid(wesabe_txid)
    find(:first, :conditions => ["wesabe_txid = ? and status in (?)",
                                  wesabe_txid, [Constants::Status::ACTIVE, Constants::Status::DISABLED]])
  end

  def generate_wesabe_txid
    self.wesabe_txid = Digest::SHA256.hexdigest([
      account_id, trade_date, investment_security_id, units,
      unit_price, sub_account_type, buy_sell_type, income_type].join)
  end

  # check if this txaction already exists before creating; if it does, update any differing data
  def check_for_duplicate
    if existing_txaction = self.class.find_by_wesabe_txid(wesabe_txid)
      return false
    end
  end

  def display_name
    if investment_security
      investment_security.to_s + (memo ? " - #{memo}" : "")
    else
      memo
    end
  end

  def currency
    account.currency
  end

  # return trade_date as default date
  def date
    trade_date.to_date
  end

  def units
    # units should be positive so long as this is a standard transaction type
    # (as opposed to an administrative transaction, like for a security name change)
    if u = read_attribute(:units)
      buy_sell_type ? u.abs : u
    end
  end

  def unit_price
    Money.new(read_attribute(:unit_price), currency) if read_attribute(:unit_price)
  end

  def total
    if t = read_attribute(:total)
      return Money.new(t.abs, currency) # total should always be positive
    else
      return unit_price * units
    end
  end

  # return a human-readable type for this transaction
  def type
    TYPES[income_type || buy_sell_type] || ""
  end
end

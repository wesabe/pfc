class InvestmentSecurity < ActiveRecord::Base
  has_many :investment_txactions
  has_many :investment_positions

  validates_presence_of :unique_id, :unique_id_type

  # given a list of unassociated (with the database) securities, find or create InvestmentSecurities
  # and return the associated securities
  def self.find_or_create(securities)
    securities.map { |s| s.find_or_create }
  end

  # find this security in the database or create it
  def find_or_create
    cc = ConditionsConstructor.new(["unique_id = ? and name = ?", unique_id, name])
    cc.add(["ticker = ?", ticker]) unless ticker.blank?
    if security = self.class.find(:first, :conditions => cc.conditions)
      return security
    else
      save!
      return self
    end
  end

  def to_s
    display_name = name || unique_id
    # valid stock symbols don't have numbers
    # REVIEW: we might want to create proper integer foreign keys instead of looking
    # up the stock by the ticker symbol.
    if !(ticker.blank? || ticker =~ /\d/) && stock = Stock.find_by_symbol(ticker)
      display_name = stock.name
    end
    return display_name
  end
end

class InvestmentAccount < Account
  has_many :txactions,
           :class_name => "InvestmentTxaction",
           :foreign_key => :account_id,
           :include => [:account],
           :conditions => ["investment_txactions.status = ?", Constants::Status::ACTIVE],
           :order => 'trade_date desc, investment_txactions.created_at desc'
  has_many :all_txactions,
           :class_name => "InvestmentTxaction",
           :foreign_key => :account_id,
           :dependent => :destroy
  has_many :all_positions,
           :class_name => "InvestmentPosition",
           :foreign_key => :account_id,
           :dependent => :destroy
  has_many :balances,
           :class_name => "InvestmentBalance",
           :foreign_key => :account_id,
           :order => 'date desc',
           :dependent => :destroy
  has_one :associated_last_balance,
          :class_name => 'InvestmentBalance',
          :include => [:account],
          :foreign_key => :account_id,
          :order => 'investment_balances.date desc, investment_balances.created_at desc'

  attr_accessor :date_as_of # used when building imports, since the DTASOF field for the statement is associated with the account

  def to_json(options={})
    { 'id' => id_for_user,
      'name' => name,
      'status' => status,
      'archived' => archived?,
      'active' => active?
    }.to_json
  end

  # implement last_balance instead of using the association because some investment statements don't actually contain
  # a balance section. So we fake out an InvestmentBalance object so the rest of PFC is happy
  def last_balance(_ = nil)
    associated_last_balance || InvestmentBalance.new(:account => self)
  end

  # return just the current positions
  # REVIEW: Can't think of how to do this in a single query
  def positions
    if last_position = all_positions.find(:first,
                                          :select => "upload_id",
                                          :order => "price_date desc, upload_id desc")
      return all_positions.find(:all,
                                :include => [:account, :investment_security],
                                :conditions => ["upload_id = ?", last_position.upload_id])
    else
      return []
    end
  end

  # market value is just the sum of the value of the positions
  def market_value
    Money.new(positions.sum{|p| p.market_value}, currency)
  end
end
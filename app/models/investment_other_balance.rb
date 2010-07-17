class InvestmentOtherBalance < ActiveRecord::Base
  self.inheritance_column = nil # used `type' for something else
  belongs_to :investment_balance
end

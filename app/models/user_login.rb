class UserLogin < ActiveRecord::Base
  belongs_to :user

  validates_presence_of :user_id
  validates_presence_of :login_date

  before_validation :ensure_login_date

private

  def ensure_login_date
    self.login_date = Date.today unless self.login_date
  end
end

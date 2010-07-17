# uploads concern for account
class Account
  has_and_belongs_to_many :uploads,
                          :order => 'accounts_uploads.created_at desc',
                          :conditions => ['uploads.status = ?', Constants::Status::ACTIVE]
  has_many :account_uploads,
           :dependent => :destroy

  # return the last upload for this account
  def last_upload
   @last_upload ||= uploads.find(:first)
  end
end
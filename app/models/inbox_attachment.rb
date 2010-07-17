class InboxAttachment < ActiveRecord::Base
  belongs_to :user, :foreign_key => 'account_key', :primary_key => 'account_key'
  belongs_to :attachment

  # create an InboxAttachment and the associated Attachment. See Attachment.generate for the params
  def self.generate(user, params)
    attachment = Attachment.generate(user, params)
    InboxAttachment.create(:account_key => user.account_key, :attachment => attachment)
  end
end
# attachments concern for Txaction
class Txaction
  has_many :txaction_attachments
  has_many :joined_attachments,
    :through => :txaction_attachments,
    :class_name => "Attachment",
    :source => :attachment,
    :dependent => :destroy

  # REVIEW: I decided to denormalize attachments because we need another join with txactions like a hole in the head.
  # return array of Attachment objects if this transaction has attachments
  def attachments
    if attachment_ids
      attachment_ids.map {|id| Attachment.find(id)}
    else
      []
    end
  end

  # return true of this txaction has an attachment
  def has_attachment?
    !!attachment_ids && attachment_ids.any?
  end

  # return true if any of the txactions provided has an attachment
  def self.has_attachments?(txactions)
    !txactions.find{|t| t.has_attachment?}.nil?
  end

  # attach an attachment to this transaction. Does not allow an attachment to be attached more than once
  def attach(attachment)
    if attachment_ids
      self.attachment_ids |= [attachment.id] if attachment_ids.size < MAX_ATTACHMENTS
    else
      self.attachment_ids = [attachment.id]
    end
    self.joined_attachments << attachment
  end

  # remove an attachment from this transaction
  def detach(attachment)
    self.attachment_ids -= [attachment.id] if attachment_ids
    self.joined_attachments -= [attachment]
  end
end
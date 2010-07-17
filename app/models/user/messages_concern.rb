# messages concern for User
class User
  has_many :message_receipts
  has_many :authored_messages, :class_name => "Message", :foreign_key => "sender_id"

  # Returns the number of unread messages a user has received. Memoized to
  # reduce database access. If +force_reload+ is true, discards the memoized
  # value and queries the database.
  def unread_message_count(force_reload = false)
    if force_reload || @unread_message_count.nil?
      @unread_message_count = message_receipts.count(
        :id,
        :conditions => {
          :recipient => true,
          :unread => true
        }
      )
    end
    return @unread_message_count
  end

end

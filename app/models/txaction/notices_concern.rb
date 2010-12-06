class Txaction
  after_create :send_appropriate_notices

  def send_appropriate_notices
    return if account.manual_account?

    # TODO: make this a per-user setting, it's pretty USD-centric
    begin
      if amount <= -500.to_d && !transfer?
        TxactionNotices.too_big(self).deliver
      end
    rescue Exception => e
      logger.error { "### error while sending txaction notices for #{self.inspect}:\n  #{e}\n#{e.backtrace.map{|l| "  #{l}" }.join("\n")}" }
    end

    # look for duplicates
    begin
      duplicate = self.class.
        where(:account_id => account_id, :amount => amount, :fi_date_posted => fi_date_posted).
        where(merchant ? ['merchant_id = ?', merchant_id] : ['filtered_name = ?', filtered_name]).
        where(['id != ?', id]).first

      if duplicate
        original = self
        original, duplicate = duplicate, original if original.fi_date_posted > duplicate.fi_date_posted
        TxactionNotices.duplicate(duplicate, original).deliver
      end
    rescue Exception => e
      logger.error { "### error while sending txaction notices for #{self.inspect}:\n  #{e}\n#{e.backtrace.map{|l| "  #{l}" }.join("\n")}" }
    end
  end
end

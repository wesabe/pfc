class Txaction
  after_create :send_appropriate_notices

  def send_appropriate_notices
    # TODO: make this a per-user setting, it's pretty USD-centric
    begin
      if amount <= -500.to_d && !transfer? && !account.manual_account?
        TxactionNotices.too_big(self).deliver
      end
    rescue Exception => e
      logger.error { "### error while sending txaction notices for #{self.inspect}:\n  #{e}\n#{e.backtrace.map{|l| "  #{l}" }.join("\n")}" }
    end
  end
end

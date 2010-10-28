module AccountsHelper
  def security_with_linked_ticker(security)
    str = security.to_s
    if !(security.ticker.blank? || security.ticker =~ /\d/)
      str += (" (%s)" % link_to(security.ticker, "http://finance.google.com/finance?q=#{security.ticker}", :target => "_new"))
    end
    return str
  end

  # helper so we can optionally display the investment memo
  # if there's no security, or the memo is the same as the security name, don't display the memo
  def investment_memo(txaction)
    # eww
    if txaction.memo &&
        txaction.investment_security &&
        txaction.investment_security.name &&
        (txaction.memo.gsub(/\s/,'') != txaction.investment_security.name.gsub(/\s/,''))
      txaction.memo
    end
  end
end

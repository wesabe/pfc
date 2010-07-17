# class to take a raw txaction name and remove any dates, transaction, numbers, etc.
# from it so that we are more likely to match subsequent txactions from the same merchant
class TxactionFilter
  FILTERS = [
    [/(^|\/)(MC|VISA)-/i, '\1'],
    [/\$\s*(\d+,?)+\d*\.\d+/i, ''], # remove dollar amounts
    [/\d*\.?\d+\s*%/i,''], # remove percentages
    [/Conf\s+#/i,''], # some banks put the merchant name behind a Conf # ("Trace #510460046 Conf #EARTHLINKINC OPS")
    [/Ref=.*?,Part=.*?,Code=.*/i, ''], # okay, seriously now Westpac (NZ), wtf.
    [/Ref \#\: \w{17}/i, ''], # cucardsonline.com ref nums (fb52179)
    [/(REF\.?(ERENCE)?|CO?NF(IRMATION)?|AUTH(ORIZATION)?|TRACE)\s*([#:]|NO\.)?\s*\S*/i, ''], # (ONLINE TRANSFER REF #IBEJLJRY5R, auth# 12345)
    [/(WWW (?:PAYMENT|TRANSFER)) - \d{4}/i, '\1'], # RBC txaction numbers (fb 20270) tweaked (fb 43912)
    [/  [A-Z0-9]{6}$/i, ''], # Canada Trust reference numbers (fb33110)
    [/\d+\.\d+\s*[A-Z]{3}\s*@\s*\d+\.\d+/i, ''], # conversion rates (101.00 USD @ 1.0189)
    [/\$?\s*[\d,.]+[.,]\d{2}(\D|$)/i, ''], # amounts
    [/ING DIRECT\s+(WITHDRAWAL|DEPOSIT)\s+(\d|X)+?(\d{4})$/i,'INGDIRECT\1\3'], # ING Direct account transfers
    [/X{2,}\d+/i,''], # get rid of blocked-out card numbers (XXXXXXX1234)
    [/(TO|FROM) A\/C \d+?(\d{4})\b/i, '\1 xxxx\2'], # Natwest (UK) account transfers
    [/(NET|GRS) \d+?(\d{4})\b/i, '\1 xxxx\2'], # Natwest (UK) interest payments
    [/(Transfer to \d+?)[^\d].*/i, '\1'], # Distinguish Nationwide (UK) transfers
    [/(CK#\d+)/i, '\1CK'], # GMAC checks should not be removed as dates
    [/CHECK (\d{3,4})/i, '\1CHECK'], # don't remove 4 digit check numbers as transaction-y numbers
    [/TRANSFER (FROM|TO|TO LOAN)\s+\d*?(\d{3,4})\b/i, 'TRANSFER \1 xxxx\2'], # account transfers (TRANSFER FROM 1010026062147, BugzID #1692)
    [/(Online (?:Banking|scheduled) (?:transfer|payment) (?:to|from) (?:CHK|SAV|CRD))(?: \d*(\d{4}))?(?:; (.*,.*))?/i, '\1 \2 \3'],
    [/^PAYPAL\W*INST\W*XFER.*/i, 'PAYPALINSTXFER'],
    [/PTS\s+(FRM|TO):\s+\d+?(\d{4})\b/i, 'PTS \1: xxxx\2'], # account transfers (PTS TO:  12345678901, BugzID #5851)
    [/\d{1,2}:\d{1,2}(:\d{2})?\s*(am|pm)?/i,''], # strip times
    [/\d{1,2}\s*H\s*\d{1,2}/i,''], # French times (Carte 1234567890123456 Retrait Dab Sg 11/06/08 18 H37 Paris Ternes 00904325)
    [/\b\d{3}\s+\d{4}\b/i,''], # some French bank's idea of month & year (Vir Recu 8847394340 De: Dassault Systemes France Motif: Salaire 006 2008)
    [/\d{1,2}-?(JAN(UARY)?|FEB(RUARY)?|MAR(CH)?|APR(IL)?|MAY|JUN(E)?|JUL(Y)?|AUG(UST)?|SEP(TEMBER)?|O(C|K)T(OBER)?|NOV(EMBER)?|DEC(EMBER)?)(\d{2})?/i, ''], # strip dates (19JAN71, 14-NOV)
    [/(JAN(UARY)?|FEB(RUARY)?|MAR(CH)?|APR(IL)?|MAY|JUN(E)?|JUL(Y)?|AUG(UST)?|SEP(TEMBER)?|O(C|K)T(OBER)?|NOV(EMBER)?|DEC(EMBER)?)\.?\s*\d+,?\s*(\d+)?/i, ''], # strip date/time ("Oct. 27, 2006 21:02", "Dec 29 7:02 Pm #460503 100 CAMBRIDGE SIDE4020500CAMBRIDGE MA ATM Transaction")
    [/^\d{2}[\/-]\d{2}(?=\D)/i, ''], # strip dates at the beginning (04/11BANKCARD DEPOSIT -032509250)
    [/\b\d{1,2}[\/-]\d{1,2}([\/-]\d{1,4})?\b/i, ''], # strip dates (dd-mm-yy[yy] or dd/mm/yy[yy], 025STAR ONE ATM WITHDRWL 02-15) (1-digit year catches cut-off years)
    [/(\b|\D)\d{1,2}[\/-]\d{1,2}(\D|\b)?/i, ''], # strip dates (025STAR ONE ATM WITHDRWL 02-15 #)
    [/\b([^#\s-])\s+(0[1-9]|1[0-2])(0[1-9]|[12]\d|3[01])\b/i, '\1'], # strip 4-digit numbers that may be dates
    [Oniguruma::ORegexp.new('(?<!#)\s*(0[1-9]|[12]\d|3[01])(0[1-9]|1[0-2])$'), ''], # strip 4-digit number that may be dates(DD/MM) at the end
    [/(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP)\s*\//i, ''], # strip months, sometimes they have lots of spaces.
    [/[#]?(?:[\d\.-]\s?){6,}(\D|\b)/i, '\1'], # strip transaction-like numbers (000204512 CHEVRON 0204 WEST LINN)
    [/\w\d \w\d \w\d$/i, ''], # strip A1 B2 C3 transaction numbers
    [/\d{3,}[A-Z]{1,4}\d+/i, ''], # more transaction-like numbers (7451899GF00)
    [/\b[A-Z]$/i, ''], # single characters at the end of the line
    [/(AMAZON.*?)\/\w{9}\s/i, '\1'], # Amazon.com memos (VTA9RGIM6 MERCHANDISE371705313951001)
    [/(\d{5,};\s*)+/i, ''], # AMZN PMTS 866-216-1/24692168093000866082056; 07399;
    [/CARD #.*/i, ''], # strip card numbers
    [/^Check Card:/i, ''],
    [/(Check Received).*/i, '\1'], # (Check Received 1,800.00)
    [/D\/C SET\s*\d\d\d/i, ''], # New Era Bank is crazy. And fond of "D/C SET <date> XXX".
    [/CUSTOMER \d+/i, ''], # BofA seems to include customer #s often
    [/CALLREFNO\d{4}$/i, ''], # Natwest (UK) likes adding call ref numbers to everything
    [/^(CKCD DEBIT)|(DEBIT)\/(\d+)?/i, ''],
    [/(DES:.*?)ID:.*?INDN:.*/i, '\1'], # I think this is Wells Fargo-speak
    [/^DIRECTDE(P|BIT)\/((MC|VISA)-)?/i, ''],
    [/(APY Earned).*/i, '\1'],
    [/CHECKPAYMT(.*?)\d{4,}/i, 'CHECKPAYMT\1'],
    [/(INTEREST PAID).*/i, '\1'],
    [/ANNUAL PERCENTAGE YIELD EARNED IS.*/i,''],
    [/PURCHASE\s*#\s*\S*/i,''], # PURCHASE #128AFS
    [/(IDP\s+)?PURCHASE\s*\d+/i,''], # PURCHASE 2029
    [/POS (PURCHASE|DEBIT)/i, ''],
    [/EFTPOS( \d{5})?/i, ''], # EFTPOS 02753
    [/^POS[\s\/]/i, ''],
    [/(POINT OF SALE|DEBIT CARD)?\s*PURCHASE/i, ''],
    [/(Withdrawal|Preauthorized) Debit (Card)?/i, ''],
    [/CHECK CA?RD\s*(?:PURCHASE)?/i, ''],
    [/PAY\s+NO\s+\d+/i, ''], # DEPOSIT - INTERNET ONLINE BANKING 2765035 PAYMENT PAY NO 36-WEBSTE 14-NOV
    [/ACHAT PDI.*/i, 'ACHAT PDI'], # BURGER KING #31/ACHAT PDI ---- 4324, CPC/SCP #273783/ACHAT PDI ---- 8888
    [/ \d\d\d\//i, '/'], # WaMu debit card transaction numbers
    [/ NZD\d+/i, ''], # Bank of New Zealand amounts in memos
    [/\w\d\w\d\w\d$/i, ''], # TD Canada Trust billpay ref numbers
    [/ - \d{4}$/i, ''], # RBC Royal Bank (Canada) txaction numbers (fb 59956)
    [/(CHASE.+ICES)\s\d+\//i, '\1'],# Payments to Chase show up as Chase Card Services #, strip the #
    [/\W/i, ''], # get rid of all non-word characters
  ]

  def self.filter(orig_str)
    return nil unless orig_str
    str = orig_str.dup
    FILTERS.each do |filter,replacement|
      case filter
      when Regexp
        str.gsub!(filter,replacement)
      when Oniguruma::ORegexp
        str = filter.gsub(str, replacement)
      end
      # puts "filter: #{filter}\nstr: #{str}" # debug
    end
    str = orig_str.dup if str.length < 3 # safety net
    return str.upcase
  end
end

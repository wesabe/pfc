require "rchardet"
require "xml/libxml" # libxml-ruby

# class to parse and import OFX 2.0 files
# used by upload_controller and [formerly] scripts/importofx2.rb

# FIXME: this class needs to be broken up a bit; most of the work is done in process_statements, which is a long run-on method.
# Anyone looking to clean this mess up should take a look at the investments importer (in app/models/ofx/), which is a lot cleaner
class OFX2Importer
  class UnsupportedStatementType < Exception; end
  class XMLParseException < Exception; end

  #----------------------------------------------------------------
  # Constants
  #

  VERSION = '1.0'
  MY_NAME = 'OFX2Importer'

  # REVIEW: move this to an external file?; YAML, perhaps
  MAP_CONSTS = { :creditcard => 'Credit Card', :brokerage => 'BROKERAGE' }
  MAP = {
    :fi_meta => {:org => "/OFX/SIGNONMSGSRSV1/SONRS/FI/ORG",
                :fid => "/OFX/SIGNONMSGSRSV1/SONRS/FI/FID"},
    :bank => {:root => "/OFX/BANKMSGSRSV1",
              :statements => {:root => "/OFX/BANKMSGSRSV1/STMTTRNRS/STMTRS",
                              :meta => {:currency => "./CURDEF",
                                        :routing_number => "./BANKACCTFROM/BANKID",
                                        :account_number => "./BANKACCTFROM/ACCTID",
                                        :account_type => "./BANKACCTFROM/ACCTTYPE",
                                        :start_date => "./BANKTRANLIST/DTSTART",
                                        :end_date => "./BANKTRANLIST/DTEND",
                                        :balance => "./LEDGERBAL/BALAMT",
                                        :balance_date => "./LEDGERBAL/DTASOF"},
                              :txactions => {:root => "./BANKTRANLIST/STMTTRN",
                                             :data => {:txaction_type => "./TRNTYPE",
                                                       :date_posted => "./DTPOSTED",
                                                       :amount => "./TRNAMT",
                                                       :txid => "./FITID",
                                                       :name => "./NAME",
                                                       :payee_name => "./PAYEE/NAME", # alternate place for the name
                                                       :check_num => "./CHECKNUM",
                                                       :ref_num => "./REFNUM",
                                                       :memo => "./MEMO"}}}},
    :investment => {:root => "/OFX/INVSTMTMSGSRSV1",
             :statements => {:root => "/OFX/INVSTMTMSGSRSV1/INVSTMTTRNRS/INVSTMTRS",
                             :meta => {:currency => "./CURDEF",
                                       :statement_date => "./DTASOF",
                                       :broker_id => "./INVACCTFROM/BROKERID",
                                       :account_number => "./INVACCTFROM/ACCTID",
                                       :account_type => :brokerage,
                                       :start_date => "./INVTRANLIST/DTSTART",
                                       :end_date => "./INVTRANLIST/DTEND",
                                       :balance => "./INVBAL/AVAILCASH",
                                       :balance_date => "./INVBAL/BALLIST/BAL/DTASOF"},
                             :txactions => {:root => "./INVTRANLIST/INVBANKTRAN/STMTTRN",
                                            :data => {:txaction_type => "./TRNTYPE",
                                                      :date_posted => "./DTPOSTED",
                                                      :amount => "./TRNAMT",
                                                      :txid => "./FITID",
                                                      :name => "./NAME",
                                                      :payee_name => "./PAYEE/NAME", # alternate place for the name
                                                      :check_num => "./CHECKNUM",
                                                      :ref_num => "./REFNUM",
                                                      :memo => "./MEMO"}}}},
    :creditcard => {:root => "/OFX/CREDITCARDMSGSRSV1",
                    :statements => {:root => "/OFX/CREDITCARDMSGSRSV1/CCSTMTTRNRS/CCSTMTRS",
                                    :meta => {:currency => "./CURDEF",
                                              :account_number => "./CCACCTFROM/ACCTID",
                                              :account_type => :creditcard,
                                              :start_date => "./BANKTRANLIST/DTSTART",
                                              :end_date => "./BANKTRANLIST/DTEND",
                                              :balance => "./LEDGERBAL/BALAMT",
                                              :balance_date => "./LEDGERBAL/DTASOF"},
                    :txactions => {:root => "./BANKTRANLIST/STMTTRN",
                                   :data => {:txaction_type => "./TRNTYPE",
                                             :date_posted => "./DTPOSTED",
                                             :amount => "./TRNAMT",
                                             :txid => "./FITID",
                                             :sic_code => "./SIC",
                                             :name => "./NAME",
                                             :payee_name => "./PAYEE/NAME", # alternate place for the name
                                             :memo => "./MEMO"}}}}
  }

  #----------------------------------------------------------------
  # Public Instance Methods
  #

  def self.logger
    Rails.logger
  end

  # import OFX 2.0 data
  # source is a String containing the ofx
  def self.import(upload)
    source = upload.converted_statement
    # strip ASCII control characters that are invalid UTF-8
    source.gsub!(/[\x00-\x08\x0e-\x1f]/, '')
    # parse the source
    logger.debug("parsing xml document...")
    # we can't trust the encoding in the statement
    # and rchardet doesn't always get it right, so try UTF-8 and latin1 if it fails
    encodings = %w[utf-8 iso-8859-1]
    CharDet.detect(source).tap do |cd|
      encodings << cd['encoding'].downcase if cd
    end

    for encoding in encodings.uniq
      if source.sub!(/encoding="(.*?)"\?>/,"encoding=\"#{encoding}\"?>")
        logger.debug("converted xml encoding from #{$1} to #{encoding}")
      end
      begin
        xml = XML::Parser.string(source).parse.root
        logger.debug("successfully parsed xml with encoding=\"#{encoding}\"")
        break
      rescue LibXML::XML::Error => e
        # raise exception only if we're out of encodings to try
        logger.debug("failed to parse xml with encoding=\"#{encoding}\"")
        raise XMLParseException, e.message, e.backtrace if encoding == encodings[-1]
      end
    end

    # bank statements
    process_statements(upload, xml, MAP[:bank][:statements]) if bank = get_node(xml, MAP[:bank][:root])

    # handle creditcard statements
    process_statements(upload, xml, MAP[:creditcard][:statements]) if cred = get_node(xml, MAP[:creditcard][:root])

    # handle investment accounts
    process_statements(upload, xml, MAP[:investment][:statements]) if inv = get_node(xml, MAP[:investment][:root])

    raise UnsupportedStatementType if !(bank || cred || inv)
  end

  #----------------------------------------------------------------------------
  # Private Class Methods
  #

  private

  include ApplicationHelper

  # return an xpath node, given the root node and path
  def self.get_node(root, path)
    root.find_first(path)
  end

  # return the text of an xpath node, given the root node and path
  def self.get_node_text(root, path)
    node = get_node(root, path)
    node && node.content ? node.content.strip : nil
  end

  #
  # process_statements - does all the work of parsing statements and saving them to the db
  #
  def self.process_statements(upload, xml, statements)
    user = upload.user
    xml.find(statements[:root]).each do | st_node |
      # get statement meta information
      stmt_meta = {}
      statements[:meta].keys.each do | key |
        value = statements[:meta][key]
        # allow for constant values (e.g. account_type => :creditcard)
        if value.is_a? Symbol
          stmt_meta[key] = MAP_CONSTS[value]
        else
          stmt_meta[key] = get_node_text(st_node, statements[:meta][key])
        end
      end

      # set the balance if we were passed one and it isn't already in the ofx
      if upload.balance && (stmt_meta[:balance].blank? || stmt_meta[:balance] == "UNKNOWN")
        stmt_meta[:balance] = upload.balance
      end

      # make sure balance is in the format n+.nn
      unless stmt_meta[:balance] == 'UNKNOWN' # preserve UNKNOWN so we can calculate it later
        stmt_meta[:balance] = Currency.normalize(stmt_meta[:balance])
      end

      # set the account type if it's not already set and we were passed one
      if upload.account_type && (stmt_meta[:account_type].blank? || stmt_meta[:account_type] == "UNKNOWN")
        stmt_meta[:account_type] = upload.account_type
      end

      # set the account number if it's not already set and we were passed one
      if stmt_meta[:account_number].blank? || stmt_meta[:account_number] == "UNKNOWN"
        stmt_meta[:account_number] = upload.account_number || 'XXXX'
      end

      account = self.get_account(upload, stmt_meta)

      # associate the upload with the account
      account.uploads << upload unless account.uploads.include?(upload)

      if upload.account_cred_id
        # associate account with account cred
        account.update_attribute(:account_cred_id, upload.account_cred_id)
        # don't save transactions for ssu-disabled accounts
        return if Constants::Status::DISABLED == account.status
      end

      # get transactions
      txaction_elements = st_node.find(statements[:txactions][:root]).to_a
      num_txactions = txaction_elements.size

      # determine if the transactions are in chronological or reverse chronological order
      txaction_list = txaction_elements.to_a
      if txaction_list.any?
        first_txaction = txaction_list.first
        last_txaction = txaction_list.last

        begin
          raw_date = get_node_text(first_txaction, statements[:txactions][:data][:date_posted])
          first_date_posted = Time.parse(raw_date)
          raw_date = get_node_text(last_txaction, statements[:txactions][:data][:date_posted])
          last_date_posted = Time.parse(raw_date)
        rescue ArgumentError => e
          raise e, "Could not parse time: #{raw_date}"
        end
        chron_order = first_date_posted < last_date_posted

        # save the account balance
        # use the greater of the given balance date and the most recent txaction date, since
        # some banks give bad balance dates (BugzId:7733)
        most_recent_txaction_date = chron_order ? last_date_posted : first_date_posted
        stmt_meta[:balance_date] ||= stmt_meta[:statement_date]
        balance_date = parse_date(stmt_meta[:balance_date]) if stmt_meta[:balance_date]
        # if the balance date is missing, old, or in the future, set it to the most recent txaction date
        if !balance_date || (balance_date < most_recent_txaction_date) || balance_date > 2.days.from_now
          balance_date = most_recent_txaction_date
        end
      else
        # no txactions, so just use what they give us for the balance date
        balance_date = parse_date(stmt_meta[:balance_date]) if stmt_meta[:balance_date]
        if !balance_date || balance_date > 2.days.from_now
          balance_date = Time.now
        end
      end

      prev_balance = account.last_balance ? account.last_balance.balance : 0 # save previous balance in case we need to calculate our own balance

      # negate the balance if a flag is set; this allows us to override stupid banks that [occasionally!] provide
      # the wrong account type (e.g. CHECKING instead of CREDITLINE)
      if stmt_meta[:balance] != 'UNKNOWN' && account.negate_balance?
        stmt_meta[:balance] = -stmt_meta[:balance].to_d
      end

      acct_balance = AccountBalance.create(
        :account_id => account.id,
        :upload_id => upload.id,
        :balance => stmt_meta[:balance],
        :balance_date => balance_date)

      #
      # process the transactions
      #

      # load hash of user's existing txactions in this account, for fast lookup
      # FIXME: this should be encapsulated elsewhere, but I think it needs to wait until I rewrite the importer
      txaction_hash = {}
      unless account.newly_created
        txactions = Txaction.find(:all,
          :conditions => ["account_id = ? and (status in (?) or (status = ? and merged_with_txaction_id is not null))",
                          account.id,
                          [Constants::Status::ACTIVE, Constants::Status::DISABLED],
                          Constants::Status::DELETED])
        # convert array to a hash
        txid_col = account.financial_inst.good_txid? ? :txid : :wesabe_txid
        txactions.each {|txaction| txaction_hash[txaction.send(txid_col)] = txaction}
        txactions = nil
      end

      tx_index = Hash.new(0)
      tx_signatures = {}
      new_txaction_amount = 0
      new_txaction_count = 0
      logger.debug("processing #{txaction_elements.size} transactions...")

      # preload TxactionTypes
      txaction_types = {}
      TxactionType.all.each {|tt| txaction_types[tt.name] = tt}

      txaction_elements.each_with_index do | tx_node, tx_count |
        txdata = {}
        statements[:txactions][:data].keys.each do | key |
          txdata[key] = get_node_text(tx_node, statements[:txactions][:data][key])
        end

        # start new txaction
        txaction_params = {
          :account => account,
          :upload => upload,
          :txaction_type => txaction_types[txdata[:txaction_type]] || TxactionType.new(:name => txdata[:txaction_type]),
          :sequence => chron_order ? num_txactions - tx_count : tx_count+1,
          :raw_name => txdata[:name] || txdata[:payee_name] || "UNKNOWN PAYEE",
          :txid => txdata[:txid],
          :amount => Currency.normalize(txdata[:amount]) || '0.00',
          :check_num => txdata[:check_num],
          :ref_num => txdata[:ref_num],
          :memo => txdata[:memo],
          :sic_code => txdata[:sic_code],
          :balance => tx_count == (chron_order ? num_txactions-1 : 0) &&
                      stmt_meta[:balance] != 'UNKNOWN' &&
                      !account.financial_inst.bad_balance? ? stmt_meta[:balance].to_d : nil
        }
        txaction = Txaction.new(txaction_params)

        # delete zero-amount transactions so the user doesn't get bugged by them
        txaction.status = Constants::Status::DELETED if txaction.amount.zero?

        # remove bogus check numbers
        txaction.check_num = nil if txaction.check_num == "0"

        # try to parse the date
        begin
          # REVIEW: we've decided that it's probably better to use Date.parse here and
          # ignore the time component of the date posted, since timezone differences could lead to the date being
          # displayed as a day earlier or later than what the bank displays on its own site. However, if we change
          # this we'll generate a lot of duplicate txactions, since the date_posted is used in the wesabe_txid. A
          # migration might be out of the question, since we don't know the original timezones of the dates in the
          # database; we'd have to go back and parse it out of the original statement, which is simply not realistic
          # for 8 million transactions. So we're punting for now. :(
          txaction.fi_date_posted = Time.parse(txdata[:date_posted])

          # Set the date_posted to the unadjusted date so that it accurately reflects what the bank thinks the
          # date is. We can only do this for FIs that have the date_adjusted flag set to true, which indicates that
          # a migration has already been run to fix the date on past txactions
          if account.financial_inst.date_adjusted?
            txaction.date_posted = txaction.fi_date_posted.in_time_zone(account.financial_inst.timezone).to_date.at_midnight
          end
        rescue ArgumentError => e
          raise e, " trying to parse timestamp \"#{txdata[:date_posted]}\""
        end

        # do  FI-specific modifications to the txid
        self.fix_txid(txaction)

        # it's possible to have duplicate txactions in a single OFX statement (BugzId: 9671), so
        # keep track of what we've seen and throw away any dups
        tx_signature = [txaction.txid,txaction.fi_date_posted.to_i,txaction.raw_name,txaction.amount].join(':')
        tx_signatures[tx_signature] = true

        # keep track of what order the transaction is within a given date and payee
        # this is to both avoid creating duplicate transactions if the txaction's position changes
        # from one statement to another and to allow for multiple legitimate txactions from the
        # same payee within a given day
        short_date_posted = txaction.fi_date_posted.strftime("%Y%m%d")
        tx_index_key = [short_date_posted,txaction.raw_name,txaction.amount].join
        tx_index[tx_index_key] += 1
        tx_index[tx_index_key_amount = "#{short_date_posted}#{txaction.amount}"] += 1 # keeping this for backwards-compatibility with the old method
        # generate our own txid in case the bank's is missing or unreliable
        txaction.wesabe_txid = [ account.id,
                                 short_date_posted,
                                 tx_index[tx_index_key],
                                 tx_index[tx_index_key_amount],
                                 "%.2f" % txaction.amount ].join(':')

        # either update the transaction or create a new one
        existing_txaction = nil
        unless account.newly_created
          existing_txaction = txaction_hash[txaction.send(txid_col)]
        end

        if existing_txaction
          # update txaction if certain fields have changed
          if existing_txaction.raw_name != txaction.raw_name ||
             existing_txaction.memo != txaction.memo ||
             existing_txaction.check_num != txaction.check_num ||
             existing_txaction.ref_num != txaction.ref_num ||
            (txaction.balance && (existing_txaction.balance != txaction.balance))
          then
            # don't update an existing txaction to remove the merchant
            new_merchant = (existing_txaction.find_merchant(user) || existing_txaction.merchant)

            # update the existing transaction, including filtered name and merchant
            existing_txaction.attributes = txaction_params
            existing_txaction.generate_filtered_and_cleaned_names!
            existing_txaction.merchant = new_merchant
            existing_txaction.save!
            existing_txaction.apply_autotags_for(user)
          end
        else
          begin
            txaction.generate_filtered_and_cleaned_names! # create the filtered_name and clean up check numbers
            txaction.merchant = txaction.find_merchant(user)

            txaction.save!
            txaction.attach_matching_transfer

            new_txaction_count += 1

            # Add any default tags for the txactions merchant
            txaction.apply_autotags_for(user)
            # keep track of total amount of new transactions, in case we need to set the balance manually,
            # which is the case for QIF files
            new_txaction_amount += txaction.amount if txaction.fi_date_posted <= balance_date
          rescue ActiveRecord::StatementInvalid => e
            # this means that the txaction already exists. Just log the error and continue
            # FIXME: this isn't a great fix. We should never get here in the first place.
            # Right now I see two ways this can happen:
            #   - the FI is marked as having good_txids, and the user uploads QIF and then OFX (or vice-versa). Since
            #     QIF doesn't include txids, we don't match the txaction
            #   - (unverified) there appears to be something that is causing identical statements to be uploaded at
            #     almost exactly the same time. This would fire off multiple importers, and you then have a race
            #     condition. We should probably have an account-level lock for imports.
            logger.warn("attempted to save duplicate transaction: #{e.message}")
          end
        end
      end

      # if we have no balance (e.g. QIF files from the FF plugin), calculate it based on the last known balance
      # and the transactions since then
      if stmt_meta[:balance] == 'UNKNOWN' || account.financial_inst.bad_balance?
        acct_balance.balance = prev_balance + new_txaction_amount
        acct_balance.save!
      end
    end
  end

  def self.generate_account_name(upload, financial_inst, account_type)
    name = upload.account_name || financial_inst.name
    name += " - #{account_type.name}" if account_type.name
    return name
  end

  # create/fetch Account
  def self.get_account(upload, stmt_meta)
    user = upload.user
    # get all prerequisites for an account
    if stmt_meta[:currency].blank?
      currency = user.default_currency
    else
      begin
        currency = Currency.new(stmt_meta[:currency])
      rescue Currency::UnknownCurrencyException
        logger.warn("Unknown currency: #{stmt_meta[:currency]}")
        currency = Currency.new('USD')
      end
    end

    account_type = AccountType.find_by_raw_name(stmt_meta[:account_type])
    financial_inst = FinancialInst.find(upload.financial_inst_id)

    # make sure we only use the "last 4" digits, and remove non-word characters
    short_account_number = Account.last4(stmt_meta[:account_number], financial_inst.account_number_regex)

    # FIXME: we should be able to replace this and the case statement below with some last4 regexes
    account_number_hash = Digest::SHA256.hexdigest(stmt_meta[:account_number])

    # get the account
    account =
      case financial_inst.wesabe_id
      when "us-003144", # America First Credit Union
           "us-003977" # Alternatives Federal Credit Union
        Account.find_account_by_account_number_hash(user, account_number_hash, account_type, financial_inst.id)
      else
        Account.find_account(user, short_account_number, account_type, financial_inst.id)
      end

    # if there's a regex for the account number, and we get an exact match on the account number, great;
    # else look for a match w/ the last 4 digits, and if found, use that and update the account number
    # this will help cut down on duplicate accounts created when switching from straight last 4 to an
    # expanded number; it won't matter if the regex is removing any of the standard last 4, however
    if !account && financial_inst.account_number_regex.present?
      old_account_number = Account.last4(stmt_meta[:account_number])
      account = Account.find_account(user, old_account_number, account_type, financial_inst.id)
      if account
        account.update_attribute(:account_number, short_account_number)
      end
    end

    if account && account.disabled? && !upload.from_ssu?
      account.update_attribute(:status, Constants::Status::ACTIVE)
    end

    if account
      # update the financial inst if it has changed
      if account.financial_inst.id != financial_inst.id
        logger.warn("financial inst has changed (#{account.financial_inst.wesabe_id} => #{financial_inst.wesabe_id}). updating...")
        account.financial_inst = financial_inst
        account.save!
      end
    else
      # create a new account
      account = Account.create(
        :name => generate_account_name(upload, financial_inst, account_type),
        :account_number => stmt_meta[:account_number],
        :account_number_hash => account_number_hash,
        :routing_number => stmt_meta[:routing_number],
        :account_key => user.account_key,
        :financial_inst => financial_inst,
        :account_type => account_type,
        :currency => currency.name
      )
      account.newly_created = true
    end

    return account
  end

  # parse a date, returning nil if there's an exception
  def self.parse_date(date)
    return Time.parse(date)
  rescue ArgumentError
    logger.warn("could not parse balance date: #{date}")
    return nil
  end

  def self.fix_txid(txaction)
    # Fix txid for Delta Snap accounts. The bulk importer combines the date posted with the sequence number to
    # get a unique FID. We need to do the same here.
    # FIXME: I was sorely tempted to start on the importer rewrite in order to
    # add this fix properly rather than bolting on yet another kludge, but as always, there's no time right now.
    # Anyway, another vote for rewriting the importer.
    if txaction.account.financial_inst.wesabe_id == "us-015635" && !txaction.txid.index('-')
      txaction.txid = [txaction.fi_date_posted.strftime("%Y%m%d"), txaction.txid].join('-')
    end
  end
end # class OFX2Importer
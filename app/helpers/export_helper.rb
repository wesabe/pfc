# REVIEW: None of these methods need to call Txaction#tags, they should all be using Txaction#taggings.
module ExportHelper
  # Takes one account and one list of transactions.
  def txactions_to_ofx2(xml, account, txactions)
    txactions.sort! {|a,b| a.date_posted <=> b.date_posted}

    xml.instruct!
    xml.instruct! :OFX, {:OFXHEADER => "200", :VERSION => "200", :SECURITY => "NONE",
                         :OLDFILEUID => "NONE", :NEWFILEUID => "NONE"}
    xml.OFX do
      xml.SIGNONMSGSRSV1 do
        xml.SONRS do
          xml.STATUS do
            xml.CODE("0")
            xml.SEVERITY("INFO")
          end
          xml.DTSERVER(Time.now.strftime("%Y%m%d%H%M%S"))
          xml.LANGUAGE("ENG")
        end
      end
      xml.BANKMSGSRSV1 do
        xml.STMTTRNRS do
          xml.TRNUID("1")
          xml.STATUS do
            xml.CODE("0")
            xml.SEVERITY("INFO")
          end
          xml.STMTRS do
            xml.CURDEF(account.currency.name)
            xml.BANKACCTFROM do
              xml.BANKID(account.routing_number)
              xml.ACCTID(account.account_number)
              xml.ACCTTYPE(account.account_type.raw_name)
            end
            if txactions.any?
              xml.BANKTRANLIST do
                # Since the transactions are sorted in descending order, "start" is last.
                xml.DTSTART(txactions.last.date_posted.strftime("%Y%m%d%H%M%S"))
                xml.DTEND(txactions.first.date_posted.strftime("%Y%m%d%H%M%S"))

                for txaction in txactions
                  xml.STMTTRN do
                    xml.TRNTYPE(txaction.txaction_type ? txaction.txaction_type.name : "OTHER")
                    xml.DTPOSTED(txaction.date_posted.strftime("%Y%m%d%H%M%S"))
                    xml.TRNAMT(sprintf("%.2f" % txaction.amount))
                    txaction.check_num ? (xml.CHECKNUM("#{txaction.check_num}")) : nil
                    xml.FITID(txaction.wesabe_txid)
                    xml.NAME(txaction.merchant_id ? txaction.merchant.name : txaction.raw_name)
                    memo_field = make_memo(txaction.memo, txaction.taggings)
                    if memo_field != ""
                      xml.MEMO(memo_field)
                    end
                  end
                end
              end
            end
            if account.last_balance
              xml.LEDGERBAL do
                xml.BALAMT(sprintf("%.2f" % account.last_balance.balance))
                xml.DTASOF(account.last_balance.balance_date.strftime("%Y%m%d%H%M%S"))
              end
            end
          end
        end
      end
    end
  end

  # Takes one account and one list of transactions.
  def txactions_to_ofx1(account, txactions)
    txactions.sort! {|a,b| a.date_posted <=> b.date_posted}

    ofx = ""
    ofx << "OFXHEADER:100\n"
    ofx << "DATA:OFXSGML\n"
    ofx << "VERSION:102\n"
    ofx << "SECURITY:NONE\n"
    ofx << "ENCODING:UNICODE\n"
    ofx << "CHARSET:1252\n"
    ofx << "COMPRESSION:NONE\n"
    ofx << "OLDFILEUID:NONE\n"
    ofx << "NEWFILEUID:NONE\n\n"

    ofx << "<OFX>\n"
    ofx << "  <SIGNONMSGSRSV1>\n"
    ofx << "    <SONRS>\n"
    ofx << "      <STATUS>\n"
    ofx << "        <CODE>0\n"
    ofx << "        <SEVERITY>INFO\n"
    ofx << "      </STATUS>\n"
    ofx << "      <DTSERVER>#{Time.now.strftime("%Y%m%d%H%M%S")}\n"
    ofx << "      <LANGUAGE>ENG\n"
    ofx << "    </SONRS>\n"
    ofx << "  </SIGNONMSGSRSV1>\n"
    ofx << "  <BANKMSGSRSV1>\n"
    ofx << "    <STMTTRNRS>\n"
    ofx << "      <TRNUID>1\n"
    ofx << "      <STATUS>\n"
    ofx << "        <CODE>0\n"
    ofx << "        <SEVERITY>INFO\n"
    ofx << "      </STATUS>\n"
    ofx << "      <STMTRS>\n"
    ofx << "        <CURDEF>#{account.currency.name}\n"
    ofx << "        <BANKACCTFROM>\n"
    ofx << "          <BANKID>#{account.routing_number}\n"
    ofx << "          <ACCTID>#{account.account_number}\n"
    ofx << "          <ACCTTYPE>#{account.account_type.raw_name}\n"
    ofx << "        </BANKACCTFROM>\n"

    if txactions.any?
      ofx << "        <BANKTRANLIST>\n"
      ofx << "          <DTSTART>#{txactions.last.date_posted.strftime("%Y%m%d%H%M%S")}\n"
      ofx << "          <DTEND>#{txactions.first.date_posted.strftime("%Y%m%d%H%M%S")}\n"

      for txaction in txactions
        ofx << "          <STMTTRN>\n"
        ofx << "            <TRNTYPE>#{txaction.txaction_type ? txaction.txaction_type.name : "OTHER"}\n"
        ofx << "            <DTPOSTED>#{txaction.date_posted.strftime("%Y%m%d%H%M%S")}\n"
        ofx << "            <TRNAMT>#{sprintf("%.2f" % txaction.amount)}\n"
        txaction.check_num ? (ofx << "            <CHECKNUM>#{txaction.check_num}\n") : nil
        ofx << "            <FITID>#{txaction.wesabe_txid}\n"
        ofx << "            <NAME>#{txaction.merchant_id ? txaction.merchant.name : txaction.raw_name}\n"
        memo_field = make_memo(txaction.memo, txaction.taggings)
        if memo_field != ""
          ofx << "            <MEMO>#{memo_field}\n"
        end
        ofx << "          </STMTTRN>\n"
      end

      ofx << "        </BANKTRANLIST>\n"
    end

    if account.last_balance
      ofx << "        <LEDGERBAL>\n"
      ofx << "          <BALAMT>#{sprintf("%.2f" % account.last_balance.balance)}\n"
      ofx << "          <DTASOF>#{account.last_balance.balance_date.strftime("%Y%m%d%H%M%S")}\n"
      ofx << "        </LEDGERBAL>\n"
    end
    ofx << "      </STMTRS>\n"
    ofx << "    </STMTTRNRS>\n"
    ofx << "  </BANKMSGSRSV1>\n"
    ofx << "</OFX>\n"

    return ofx
  end

  # Takes one account and one list of transactions.
  def txactions_to_qif(account, txactions)
    txactions.sort! {|a,b| a.date_posted <=> b.date_posted}
    qif = account.account_type.name == "Credit Card" ? "!Type:CCard\n" : "!Type:Bank\n"
    for txaction in txactions
      qif << "D" << txaction.date_posted.strftime("%m/%d/%Y") << "\n"
      qif << "T" << sprintf("%.2f" % txaction.amount) << "\n"
      txaction.check_num ? (qif << "N#{txaction.check_num}\n") : nil
      qif << "P#{txaction.merchant_id ? txaction.merchant.name : txaction.raw_name}\n"
      memo_field = make_memo(txaction.memo, txaction.taggings)
      if memo_field != ""
        qif << "M#{memo_field}\n"
      end
      qif << "^\n"
    end

    return qif
  end

  def accounts_to_csv(accounts)
    FasterCSV.generate do |csv|
      csv << %w{ id guid account-number name financial-institution-id financial-institution-name account-type currency current-balance last-uploaded-at }
      accounts.each do |account|
        account_data = []

        account_data << account.id_for_user
        account_data << account.guid
        account_data << account.account_number
        account_data << account.name

        if account.financial_inst
          account_data += [account.financial_inst.wesabe_id, account.financial_inst.name]
        else
          account_data += [nil, nil]
        end

        account_data << (account.account_type ? account.account_type.name : nil)
        account_data << (account.currency ? account.currency.name : nil)

        account_data << (account.has_balance? ? account.balance : nil)
        account_data << (account.last_upload ? account.last_upload.created_at.utc.xmlschema : nil)

        csv << account_data
      end
    end
  end

  # Presents a single txaction as an XML document.
  # options:
  #   :skip_instruct - don't include the xml header
  #   :concise - only display date, merchant name, amount, and tags (w/ split amounts)
  #   :currency - convert amounts to the given currency
  #   :show_id => true/false # temporary "secret" parameter to allow Tim to get the DB ids of txactions
  #                            this should be removed after we've added an id_for_account column to txactions
  def txaction_to_xml(xml, txaction, options = {})
    xml.instruct! unless options[:skip_instruct]
    xml.dasherize!
    xml.txaction do
      if options[:show_id]
        xml.id(txaction.id)
      else
        xml.guid(txaction.guid) unless options[:concise]
      end
      if txaction.transfer? && !options[:concise]
        if txaction.paired_transfer?
          xml.transfer { xml.guid(txaction.transfer_buddy.guid) }
        else
          xml.transfer
        end
      end
      xml.account_id(txaction.account.id_for_user) if options[:include_account]
      xml.date(txaction.date_posted.to_date.to_formatted_s(:db))
      xml.original_date(txaction.fi_date_posted.to_date.to_formatted_s(:db)) unless options[:concise]

      if txaction.check_num && !options[:concise]
        xml.check_number(txaction.check_num)
      end

      xml.amount(txaction.money_amount.to_s(:as_decimal => true), :type => "float")
      if options[:currency]
        options[:currency] = currency_object_from_param(options[:currency])
        if txaction.currency == options[:currency]
          converted_amount = txaction.money_amount # don't convert if we're already in the target currency
        else
          converted_amount = txaction.usd_money_amount.convert_to_currency(options[:currency])
        end
        xml.converted_amount(converted_amount.to_s(:as_decimal => true), :type => "float", :currency => options[:currency].name)
      end

      if txaction.merchant_id
        xml.merchant do
          xml.id(txaction.merchant_id) unless options[:concise]
          xml.name(txaction.merchant.name)
        end
      end

      unless options[:concise]
        xml.display_name(txaction.display_name(false))
        if !txaction.merchant_id && txaction.raw_name.blank? && !txaction.cleaned_name.blank?
          # the mobile site currently sets cleaned_name on an added txaction; this is not a field we want to expose, however
          # (it should probably be setting raw_name instead, or just creating a merchant), so output it as raw_name
          xml.raw_name(txaction.cleaned_name)
        elsif !txaction.raw_name.blank?
          xml.raw_name(txaction.raw_name)
        end
      end

      xml.raw_txntype(txaction.txaction_type ? txaction.txaction_type.name : "OTHER") unless options[:concise]

      unless txaction.memo.blank? || options[:concise]
        xml.memo(txaction.memo)
      end

      unless txaction.note.blank? || options[:concise]
        xml.note(txaction.note)
      end

      display_taggings = (txaction.rational_tag || txaction.taggings)
      if display_taggings.any?
        xml.tags(:type => "array") do
          display_taggings.each do |tagging|
            if tagging.split_amount
              xml.tag do
                xml.name(tagging.name_without_split)
                xml.display(tagging.display_name)
                split_amount = Money.new(tagging.split_amount, txaction.currency)
                xml.split_amount(split_amount.to_s(:as_decimal => true), :type => "float")
                if options[:currency]
                  converted_split_amount = Money.new(tagging.split_amount, txaction.currency).convert_to_currency(options[:currency], txaction.date_posted)
                  xml.converted_split_amount(converted_split_amount.to_s(:as_decimal => true), :type => "float", :currency => options[:currency].name)
                end
              end
            else
              xml.tag do
                xml.name(tagging.name)
                xml.display(tagging.display_name)
              end
            end
          end
        end
      end

    end
  end

  # render a txaction as JSON (called from views/txactions/show.json.erb)
  # options:
  #  :concise => true/false # if true, only show core fields
  #  :show_id => true/false # temporary "secret" parameter to allow Tim to get the DB ids of txactions
  #                           this should be removed after we've added an id_for_account column to txactions
  def txaction_to_json(txaction, options = {})
    txaction_to_hash(txaction, options).to_json
  end

  # create a hash representing a txaction. Used by txaction_to_json
  def txaction_to_hash(txaction, options = {})
    date = (User.current && User.current.time_zone) ?
            txaction.date_posted.in_time_zone(User.current.time_zone).to_date :
            txaction.date_posted.to_date
    fields = {
      :account_id => txaction.account.id_for_user,
      :date => date,
      :amount => txaction.money_amount.to_s(:as_decimal => true),
      :display_name => txaction.display_name(false)
    }
    if options[:show_id]
      fields.update(:id => txaction.id)
    else
      fields.update(:guid => txaction.guid)
    end
    fields.update(:original_date => txaction.fi_date_posted.to_date) unless options[:concise]
    fields.update(:transfer => txaction.transfer_buddy.guid) if txaction.transfer? && !options[:concise]
    fields.update(:check_number => txaction.check_num) if txaction.check_num && !options[:concise]
    if txaction.merchant_id
      merchant_fields = {
        :id => txaction.merchant_id,
        :name => txaction.merchant.name
      }
      fields.update(:merchant => merchant_fields)
    end

    unless options[:concise]
      if !txaction.merchant_id && txaction.raw_name.blank? && !txaction.cleaned_name.blank?
        # the mobile site currently sets cleaned_name on an added txaction; this is not a field we want to expose, however
        # (it should probably be setting raw_name instead, or just creating a merchant), so output it as raw_name
        fields.update(:raw_name => txaction.cleaned_name)
      elsif !txaction.raw_name.blank?
        fields.update(:raw_name => txaction.raw_name)
      end
    end

    fields.update(:memo => txaction.memo) unless txaction.memo.blank?
    fields.update(:raw_txntype => (txaction.txaction_type ? txaction.txaction_type.name : "OTHER")) unless options[:concise]
    display_taggings = (txaction.rational_tag || txaction.taggings)
    if display_taggings.any?
      sticky_tags = []
      one_time_tags = []
      tags = []
      display_taggings.each do |tagging|
        tag = { :name => tagging.name_without_split}
        tag.update(:display => tagging.display_name)
        if tagging.split_amount
          tag.update(:split_amount => Money.new(tagging.split_amount, txaction.currency).to_s(:as_decimal => true))
        end
        tags << tag
      end
      fields.update(:tags => tags) if tags.any?
    end
    fields.update(:note => txaction.note) unless txaction.note.blank?
    return fields
  end

  # Takes a list of accounts, each of which should hold a list of transactions.
  def txactions_to_csv(txactions, options = {})
    txactions.sort! {|a,b| a.date_posted <=> b.date_posted}
    csv_text = FasterCSV.generate(options) do |csv|
      csv << ["Account Id", "Account Name", "Financial Institution", "Account Type", "Currency",
              "Transaction Date", "Check Number", "Amount", "Merchant", "Raw Name",
              "Memo", "Note", "Rating", "Tags"]
      for txaction in txactions
        csv << [txaction.account.id_for_user,
                txaction.account.name,
                txaction.account.financial_inst_name,
                txaction.account.account_type.name,
                txaction.account.currency.name,
                txaction.date_posted.strftime("%Y-%m-%d"),
                txaction.check_num ? txaction.check_num : nil,
                number_to_currency(txaction.amount(:tag => @tag), :unit => '', :delimiter => ''),
                txaction.merchant_id ? txaction.merchant.name : nil,
                txaction.raw_name || txaction.cleaned_name,
                txaction.memo,
                txaction.note,
                txaction.taggings.map(&:name).join(", ")]
      end
    end

    return csv_text
  end

  # return a zip file of the attachments in this set of txactions
  def txactions_to_zip(filename, txactions)
    attachments = txactions.map {|t| t.attachments }.flatten
    if attachments.any?
      zip_file = Attachment.create_zip_file(filename, attachments)
      data = File.read(zip_file)
      File.delete(zip_file)
      return data
    end
  end

  def make_memo(memo, taggings)
    memo_field = memo ? "#{memo} " : "" # extra space to pad tag parens if needed
    memo_field << "(tags: #{taggings.map(&:name).join(", ")})" if taggings.any?
    return memo_field
  end

  # REVIEW:This is a bit of a hack, but it is the only way I could figure out how to
  # set a filename for the txaction exports. set_filename is called from the _as_* views
  def set_filename_for_account_export(account, txactions, ext)
    if params[:month]
      file_date = "%s %s" % [month_name(params[:month].to_i), params[:year]]
    elsif txactions.any?
      file_date = "%s-%s" % [txactions.last.date_posted.strftime("%B %e %Y"), txactions.first.date_posted.strftime("%B %e %Y")]
    else
      # not sure what else to put here
      file_date = Time.now.strftime("%B %e %Y")
    end

    filename = "%s - %s.%s" % [account.name, file_date, ext]
    # remove any problematic characters from the account name
    filename.gsub!(/[^\w .-]/,'')
    headers.update('Content-Disposition' => "attachment; filename=\"#{filename}\"")
    return filename
  end

  def set_filename_for_export(name, format)
    filename = "#{Sluggability.make_slug(name)}.#{format}"
    headers.update('Content-Disposition' => "attachment; filename=\"#{filename}\"")
    return filename
  end

private

  def currency_object_from_param(currency)
    begin
      Currency.new(currency)
    rescue Currency::UnknownCurrencyException
      current_user.default_currency
    end
  end
end


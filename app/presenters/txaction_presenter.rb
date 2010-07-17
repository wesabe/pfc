class TxactionPresenter < SimplePresenter
  def brcm_hash
    txaction_hash = brcm_hash_without_transfer

    if paired_transfer?
      transfer = present(transfer_buddy).brcm_hash_without_transfer
    elsif transfer?
      transfer = true
    else
      transfer = nil
    end

    txaction_hash["transfer"] = transfer
    txaction_hash
  end

  def brcm_hash_without_transfer
    tx = presentable
    txaction_hash = {
      "id" => tx.id,
      "uri" => "/transactions/#{tx.id}",
      "date" => tx.date_posted.strftime("%Y%m%d"),
      "original-date" => tx.fi_date_posted.strftime("%Y%m%d"),
      "unedited-name" => tx.full_raw_name,
      "note" => tx.note,
      "amount" => {
        "value" => tx.amount,
        "display" => tx.money_amount.to_s
      },
      "account" => {
        "id" => tx.account.id_for_user,
        "uri" => "/accounts/#{tx.account.id_for_user}",
        "type" => tx.account.account_type.name
      },
      "tags" => tx.tags.map do |t|
        {"name" => t.name, "uri" => "/tags/#{CGI.escape(t.name)}"}
      end
    }

    if tx.merchant_id && tx.merchant_name
      txaction_hash.merge!("merchant" => {
        "name" => tx.merchant_name,
        "id" => tx.merchant_id,
        "uri" => "/transactions/merchant/#{tx.merchant_id}",
      })
    else
      txaction_hash.merge!("merchant" => nil)
    end

    txaction_hash.merge!("attachments" => tx.txaction_attachments.map do |ta|
      a = ta.attachment
      { "guid" => a.guid, "filename" => a.filename, "content-type" => a.content_type }
    end) if tx.txaction_attachments.any?

    txaction_hash
  end
end

require 'exporter/txaction'

class Exporter::Txaction::Csv < Exporter::Txaction
  HEADERS = ["Account Id", "Account Name", "Financial Institution", "Account Type", "Currency",
          "Transaction Date", "Check Number", "Amount", "Merchant", "Bank Name", "Note", "Tags"].freeze

  def content_type
    "text/csv"
  end

  # convert the json txaction data to csv
  # currently used options are:
  #  :tag => scope output to a tag
  def convert
    options = @options.dup
    tag = options.delete(:tag)
    return FasterCSV.generate(options) do |csv|
      csv << HEADERS
      @data["transactions"].each do |txaction|
        csv << convert_txaction(txaction, tag)
      end
    end
  end

  def convert_txaction(tx_hash, tag = nil)
    account = find_account(tx_hash["account"]["id"])

    # if the conversion is scoped to a tag, show the amount for that tag
    if tag && (tag_hash = tx_hash["tags"].find {|t| t["name"] == tag}) && tag_hash["amount"]
      amount = tag_hash["amount"]["value"]
    else
      amount = tx_hash["amount"]["value"]
    end

    return [
      account.id_for_user,
      account.name,
      account.financial_inst_name,
      account.account_type.name,
      account.currency.name,
      Time.parse(tx_hash["date"]).strftime("%Y-%m-%d"),
      tx_hash["check-number"],
      amount,
      tx_hash["merchant"] && tx_hash["merchant"]["name"],
      tx_hash["unedited-name"],
      tx_hash["note"],
      convert_tags(tx_hash["tags"])
    ]
  end

  def convert_tags(tag_array)
    tag_array.map do |t|
      t["amount"] ?
        [t["name"], t["amount"]["value"].to_d.abs].join(':') :
        t["name"]
    end.join(", ")
  end
end
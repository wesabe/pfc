require 'pathname'
require 'active_support/json'

class Exporter::Wesabe
  attr_accessor :bundle

  def write(user, archive)
    path = Pathname.new(Dir.tmpdir) + archive.basename('.*') # /tmp/98a02e
    zip  = path.parent + archive.basename                    # /tmp/98a02e.zip

    Bundle.new(path) do |bundle|
      self.bundle = bundle

      write_user(user)
      write_preferences(user.preferences)
      write_inbox_attachments(user.inbox_attachments)

      # only grab active accounts
      user.accounts.each do |account|
        write_financial_institution(account.financial_inst) if account.financial_inst
        write_account(account)
      end

      write_account_merchant_tag_stats(user)
      write_merchants(user)

      user.targets.each do |target|
        write_target(target)
      end
    end

    Dir.chdir(path) do
      # we do this atomically to prevent a race condition -- Snapshot#built? checks only for existence
      archive.dirname.mkpath                                   # make sure the target directory exists
      system '/usr/bin/zip', '-rq', zip, *path.children(false) # zip up the contents to a temporary file
      FileUtils.move(zip, archive)                             # move the completed zip into place
    end

    if $?.success?
      path.rmtree
      return true
    else
      return false
    end
  end

  def write_user(user)
    bundle.add 'user.json' do
      content ActiveSupport::JSON.encode(
        :username         => user.username,
        :email            => user.email,
        :name             => user.name,
        :postal_code      => user.postal_code,
        :country          => user.country && user.country.code,
        :default_currency => user.default_currency && user.default_currency.to_s,
        :time_zone        => user.time_zone
      )

      # manifest info
      Name  user.name
      Email user.email
    end
  end

  def write_preferences(prefs)
    bundle.add "preferences.json" do
      content ActiveSupport::JSON.encode(prefs.to_hash)
    end
  end

  def write_inbox_attachments(inbox_attachments)
    attachment_data = inbox_attachments.map do |inbox_attachment|
      attachment_data(inbox_attachment.attachment)
    end

    bundle.add "inbox_attachments.json" do
      content ActiveSupport::JSON.encode(attachment_data)
    end
  end

  def write_financial_institution(financial_inst)
    bundle.add "financial-institutions/#{financial_inst.id}.json" do
      content ActiveSupport::JSON.encode(
        :name                 => financial_inst.name,
        :wesabe_id            => financial_inst.wesabe_id,
        :homepage_url         => financial_inst.homepage_url,
        :login_url            => financial_inst.login_url,
        :connection_type      => financial_inst.connection_type,
        :date_format          => financial_inst.date_format,
        :good_txid            => financial_inst.good_txid?,
        :bad_balance          => financial_inst.bad_balance,
        :country              => financial_inst.country && financial_inst.country.code,
        :timezone             => financial_inst.timezone,
        :date_adjusted        => financial_inst.date_adjusted?,
        :account_number_regex => financial_inst.account_number_regex
      )

      # manifest info
      Name      financial_inst.name
      Wesabe_ID financial_inst.wesabe_id
    end
  end

  def write_account(account)
    account_data = {
      :name                   => account.name,
      :currency               => account.currency.to_s,
      :id_for_user            => account.id_for_user,
      :account_number         => account.account_number,
      :account_number_hash    => account.account_number_hash,
      :account_type           => account.account_type.raw_name,
      :status                 => Constants::Status.string_for(account.status),
      :negate_balance         => account.negate_balance,
      :type                   => account.type,
      'financial-institution' => account.financial_inst && account.financial_inst.name
    }

    case account
    when InvestmentAccount
      account_data.update(
        :transactions => account.txactions.map {|txaction| investment_txaction_data(txaction) },
        :positions    => account.positions.map {|position| investment_position_data(position) },
        :balances     => account.balances.map {|balance| investment_balance_data(balance) }
      )
    when Account
      account_data.update(
        :transactions => account.txactions.map {|txaction| txaction_data(txaction) },
        :balances     => account.account_balances.map {|balance| balance_data(balance) }
      )
    end

    bundle.add "accounts/#{account.id_for_user}.json" do
      content ActiveSupport::JSON.encode(account_data)

      # manifest info
      Name    account.name
      Balance account.balance, :type => :money, :currency => account.currency
      Type    account.type
    end
  end

  def write_account_merchant_tag_stats(user)
    bundle.add "account_merchant_tag_stats.json" do
      content ActiveSupport::JSON.encode(AccountMerchantTagStat.all(:conditions => {:account_key => user.account_key}).map do |amts|
        {:merchant => amts.merchant.name,
         :name     => amts.name,
         :tag      => amts.tag.name,
         :count    => amts.count,
         :sign     => amts.sign,
         :forced   => amts.forced}
      end)
    end
  end

  def write_merchants(user)
    bundle.add "merchants.json" do
      content ActiveSupport::JSON.encode(MerchantUser.all(:conditions => {:user_id => user.id}).map do |mu|
        {:merchant          => mu.merchant.name,
         :sign              => mu.sign,
         :autotags_disabled => mu.autotags_disabled?}
      end)
    end
  end

  def balance_data(account_balance)
    {:balance      => account_balance.balance,
     :balance_date => account_balance.balance_date}
  end

  def investment_balance_data(investment_balance)
    {:avail_cash     => investment_balance.available_cash && investment_balance.available_cash.amount,
     :margin_balance => investment_balance.margin_balance && investment_balance.margin_balance.amount,
     :short_balance  => investment_balance.short_balance && investment_balance.short_balance.amount,
     :buy_power      => investment_balance.buy_power && investment_balance.buy_power.amount,
     :date           => investment_balance.date,
     :other_balances => investment_balance.other_balances.map do |other_balance|
      {:name        => other_balance.name,
       :description => other_balance.description,
       :date        => other_balance.date,
       :type        => other_balance.type,
       :value       => other_balance.value}
                        end}
  end

  def txaction_data(txaction)
    {:id             => txaction.id,
     :date_posted    => txaction.date_posted,
     :fi_date_posted => txaction.fi_date_posted,
     :raw_name       => txaction.raw_name,
     :filtered_name  => txaction.filtered_name,
     :cleaned_name   => txaction.cleaned_name,
     :txid           => txaction.txid,
     :wesabe_txid    => txaction.wesabe_txid,
     :merchant       => txaction.merchant && txaction.merchant.name,
     :memo           => txaction.memo,
     :amount         => txaction.amount,
     :usd_amount     => txaction.usd_amount,
     :sequence       => txaction.sequence,
     :check_num      => txaction.check_num,
     :note           => txaction.note,
     :transfer       => txaction.paired_transfer?? {:id => txaction.transfer_buddy.id} : txaction.transfer?,
     :taggings       => txaction.taggings.map {|tagging| tagging_data(tagging) },
     :attachments    => txaction.attachments.map {|attachment| attachment_data(attachment) },
     :type           => txaction.txaction_type &&
                        {:name => txaction.txaction_type.name,
                         :display_name => txaction.txaction_type.display_name}}
  end

  def investment_txaction_data(txaction)
    write_investment_security txaction.investment_security

    {:id                   => txaction.id,
     :txid                 => txaction.txid,
     :memo                 => txaction.memo,
     :original_trade_date  => txaction.original_trade_date,
     :original_settle_date => txaction.original_settle_date,
     :trade_date           => txaction.trade_date,
     :settle_date          => txaction.settle_date,
     :units                => txaction.units,
     :unit_price           => txaction.unit_price && txaction.unit_price.amount,
     :commission           => txaction.commission,
     :fees                 => txaction.fees,
     :withholding          => txaction.withholding,
     :currency             => txaction.currency.to_s,
     :currency_rate        => txaction.currency_rate,
     :total                => txaction.total && txaction.total.amount,
     :note                 => txaction.note,
     :buy_sell_type        => txaction.buy_sell_type,
     :income_type          => txaction.income_type,
     :investment_security  => txaction.investment_security.unique_id,
     :sub_account_type     => txaction.sub_account_type,
     :sub_account_fund     => txaction.sub_account_fund}
  end

  def investment_position_data(position)
    write_investment_security position.investment_security

    {:investment_security    => position.investment_security.unique_id,
     :sub_account_type       => position.sub_account_type,
     :position_type          => position.position_type,
     :units                  => position.units,
     :unit_price             => position.unit_price && position.unit_price.amount,
     :market_value           => position.market_value,
     :price_date             => position.price_date,
     :memo                   => position.memo,
     :reinvest_dividends     => position.reinvest_dividends,
     :reinvest_capital_gains => position.reinvest_capital_gains}
  end

  def write_investment_security(security)
    bundle.add "securities/#{security.unique_id}.json" do
      content ActiveSupport::JSON.encode(
        :unique_id      => security.unique_id,
        :unique_id_type => security.unique_id_type,
        :name           => security.name,
        :ticker         => security.ticker,
        :fi_id          => security.fi_id,
        :rating         => security.rating,
        :memo           => security.memo
      )

      # manifest info
      Name   security.name
      Ticker security.ticker
    end
  end

  def tagging_data(tagging)
    {:tag              => tagging.tag.name,
     :split_amount     => tagging.split_amount,
     :usd_split_amount => tagging.usd_split_amount}
  end

  def attachment_data(attachment)
    bundle.add "attachments/#{attachment.guid}" do
      content attachment.read

      # manifest info
      Filename     attachment.filename
      Description  attachment.description
      Content_type attachment.content_type
      Size         attachment.size,        :type => :filesize
    end

    {:guid         => attachment.guid,
     :filename     => attachment.filename,
     :description  => attachment.description,
     :content_type => attachment.content_type,
     :size         => attachment.size}
  end

  def write_target(target)
    bundle.add "targets/#{target.id}.json" do
      content ActiveSupport::JSON.encode(
        :tag => target.tag.name,
        :amount_per_month => target.amount_per_month,
        :tag_name => target.tag_name
      )

      # manifest info
      Tag           target.tag_name
      Monthly_limit target.amount_per_month, :type => :money, :currency => target.user.default_currency
    end
  end

  class Bundle
    attr_reader :path, :items

    def initialize(path)
      @path  = path
      @items = {}
      if block_given?
        yield self
        write
      end
    end

    def add(name, &block)
      item = BundleItem.new(self, name)
      item.instance_eval(&block) if block
      item.write
      items[item.name] = item
    end

    def write
      write_manifest
      write_index
    end

    private

    def filenames
      items.keys.sort
    end

    def write_manifest
      manifest = BundleItem.new(self, 'MANIFEST')
      manifest.content = filenames.join("\n")
      manifest.write
    end

    def write_index
      content = filenames.inject('') do |html, filename|
        html << %{<h3><a href="#{filename}">#{filename}</a></h3>}
        item = items[filename]
        if item.attributes.any?
          html << "<ul>"
          item.attributes.each do |key, value|
            html << "<li><strong>#{key.to_s.tr('_', ' ')}:</strong> #{value}</li>"
          end
          html << "</ul>"
        end
        html
      end

      index = BundleItem.new(self, 'index.html')
      index.content = <<-EOS
<html>
<head>
  <title>Wesabe Snapshot</title>
  <style type="text/css">
  h3, h4 {
    font-face: Menlo, Monaco, "Courier New";
  }
  </style>
</head>
<body>
  <h1>Wesabe Snapshot Manifest</h1>

  <p>
    This is a list of all the files contained within this snapshot along with some
    information about the data they contain. With the exception of attachments, all data
    is in <a href="http://en.wikipedia.org/wiki/JSON">JSON</a> format. If you wish to use
    the data yourself, here&rsquo;s an example of using it with the
    <a href="http://en.wikipedia.org/wiki/Ruby_(programming_language)">Ruby programming language</a>:

    <pre>
      # assumes that you have rubygems and the yajl-ruby gem installed
      require 'rubygems'
      require 'yajl'

      user = Yajl::Parser.parse(File.read('user.json'))
      puts "Hello \#{user['name']}, your email address is \#{user['email']}"
    </pre>
  </p>

#{content}

</body>
</html>
      EOS

      index.write
    end
  end

  class BundleItem
    include ActionView::Helpers::NumberHelper

    attr_reader :bundle, :name, :attributes

    def initialize(bundle, name)
      @bundle     = bundle
      @name       = name
      @attributes = []
    end

    def path
      bundle.path + name
    end

    def content(content=nil)
      if content.nil?
        @content
      else
        self.content = content
      end
    end

    def content=(content)
      @content = content
    end

    def add_attribute(name, value, options={})
      if options
        case options[:type]
        when :money
          value = Money.new(value, options[:currency] || 'USD').to_s
        when :filesize
          value = number_to_human_size(value)
        end
      end

      attributes << [name, value || 'n/a']
    end

    def write
      path.parent.mkpath
      path.open('w') {|f| f << content }
      self.content = nil
    end

    private

    def method_missing(*args)
      add_attribute(*args)
    end
  end
end
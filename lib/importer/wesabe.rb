require 'active_support/json'
require 'time'
require 'pathname'
require 'fileutils'

class Importer
  class Wesabe
    attr_accessor :bundle, :user, :options
    DEFAULT_PASSWORD = 'changeme!'

    def self.import(archive, options={})
      new(options).import(archive)
    end

    def initialize(options={})
      self.options = HashWithIndifferentAccess.new(options).reverse_merge(:password => DEFAULT_PASSWORD)
    end

    def say(msg)
      puts msg if options[:verbose]
    end

    def import(archive)
      self.bundle = TempfilePath.generate
      bundle.mkpath

      begin
        say "unzipping snapshot..."
        system '/usr/bin/unzip', '-qq', archive, '-d', bundle
        return nil unless $?.success?

        say "importing user..."
        self.user = import_user(ActiveSupport::JSON.decode((bundle + 'user.json').read))
        User.current = self.user
        say "importing user preferences..."
        import_preferences(ActiveSupport::JSON.decode((bundle + 'preferences.json').read))
        say "importing inbox attachments..."
        import_inbox_attachments(ActiveSupport::JSON.decode((bundle + 'inbox_attachments.json').read))

        say "importing account-merchant-tag stats..."
        import_account_merchant_tag_stats(ActiveSupport::JSON.decode((bundle + 'account_merchant_tag_stats.json').read))
        say "importing merchants..."
        import_merchants(ActiveSupport::JSON.decode((bundle + 'merchants.json').read))

        say "importing financial institutions..."
        each('financial-institutions') do |child|
          import_financial_institution(ActiveSupport::JSON.decode(child.read))
        end

        say "importing securities..."
        each('securities') do |child|
          import_investment_security(ActiveSupport::JSON.decode(child.read))
        end

        say "importing accounts..."
        each('accounts') do |child|
          import_account(ActiveSupport::JSON.decode(child.read))
        end

        say "importing attachments..."
        each('attachments') do |child|
          target = Attachment.find_by_guid(child.basename.to_s).filepath
          Pathname(target).parent.mkpath
          FileUtils.cp(child, target)
        end

        say "importing targets..."
        each('targets') do |child|
          import_target(ActiveSupport::JSON.decode(child.read))
        end

        say "associating transfers..."
        associate_transfers
        txactions.clear

        say "done!"
        return user
      ensure
        bundle.rmtree if bundle.exist?
      end
    end

    def each(name, &block)
      subdir = bundle+name
      subdir.exist? && subdir.children.each(&block)
    end

    def import_user(data)
      returning User.new do |user|
        user.email            = data['email']
        user.password         = options[:password]
        user.name             = data['name']
        user.postal_code      = data['postal_code']
        user.country          = Country.find_by_code(data['country'])
        user.default_currency = data['default_currency']

        user.save!
      end.authenticated_by(options[:password])
    end

    def import_preferences(data)
      returning UserPreferences.new do |prefs|
        prefs.user        = user
        prefs.preferences = data.symbolize_keys

        prefs.save(:validate => false)
      end
    end

    def import_inbox_attachments(data)
      data.map do |datum|
        returning InboxAttachment.new do |inbox_attachment|
          inbox_attachment.account_key = user.account_key
          inbox_attachment.attachment  = import_attachment(datum)

          inbox_attachment.save(:validate => false)
        end
      end
    end

    def import_financial_institution(data)
      FinancialInst.find_by_name(data['name']) || begin
        returning FinancialInst.new do |fi|
          fi.name                 = data['name']
          fi.wesabe_id            = data['wesabe_id']
          fi.homepage_url         = data['homepage_url']
          fi.login_url            = data['login_url']
          fi.username_label       = data['username_label']
          fi.password_label       = data['password_label']
          fi.connection_type      = data['connection_type']
          fi.date_format          = data['date_format']
          fi.good_txid            = data['good_txid']
          fi.bad_balance          = data['bad_balance']
          fi.featured             = true
          fi.country              = Country.find_by_code(data['country'])
          fi.timezone             = data['timezone']
          fi.date_adjusted        = data['date_adjusted']
          fi.account_number_regex = data['account_number_regex']
          fi.creating_user        = user

          fi.save(:validate => false)
        end
      end
    end

    def import_investment_security(data)
      InvestmentSecurity.find_by_unique_id(data['unique_id']) || begin
        returning InvestmentSecurity.new do |security|
          security.name           = data['name']
          security.ticker         = data['ticker']
          security.unique_id      = data['unique_id']
          security.unique_id_type = data['unique_id_type']
          security.fi_id          = data['fi_id']
          security.rating         = data['rating']
          security.memo           = data['memo']

          security.save(:validate => false)
        end
      end
    end

    def import_account(data)
      returning Account.new do |account|
        account.name                = data['name']
        account.currency            = data['currency']
        account.account_type        = AccountType.find_by_raw_name(data['account_type'])
        account.account_number      = data['account_number']
        account.account_number_hash = data['account_number_hash']
        account.status              = Constants::Status.for_string(data['status'])
        account.negate_balance      = data['negate_balance']
        account.account_key         = user.account_key
        account.type                = data['type']
        account.financial_inst      = data['financial-institution'] &&
                                      FinancialInst.find_by_name(data['financial-institution'])

        if id_for_user = data['id_for_user']
          account.id_for_user = id_for_user
        else
          account.__send__(:generate_id_for_user)
        end

        raise "Unable to create Account" unless account.save(:validate => false)
        account = Account.find(account.id) # get an InvestmentAccount if need be

        if account.is_a?(InvestmentAccount)
          import_investment_txactions(account, data['transactions'] || [])
          import_investment_positions(account, data['positions'] || [])
          import_investment_balances(account, data['balances'] || [])
        else
          import_txactions(account, data['transactions'] || [])
          import_balances(account, data['balances'] || [])
        end
      end
    end

    def import_txactions(account, data)
      data.map do |datum|
        returning Txaction.new do |txaction|
          txaction.account        = account
          txaction.date_posted    = datum['date_posted']
          txaction.fi_date_posted = datum['fi_date_posted']
          txaction.raw_name       = datum['raw_name']
          txaction.filtered_name  = datum['filtered_name']
          txaction.cleaned_name   = datum['cleaned_name']
          txaction.txid           = datum['txid']
          txaction.merchant       = datum['merchant'] && Merchant.find_or_create_by_name(datum['merchant'])
          txaction.memo           = datum['memo']
          txaction.amount         = datum['amount']
          txaction.usd_amount     = datum['usd_amount']
          txaction.sequence       = datum['sequence']
          txaction.check_num      = datum['check_num']
          txaction.note           = datum['note']

          if datum['type']
            txaction.txaction_type = TxactionType.find_by_name(datum['type']['name']) ||
                                     TxactionType.create!(datum['type'])
          end

          if account.financial_inst.nil? || account.financial_inst.good_txid?
            txaction.wesabe_txid = datum['wesabe_txid']
          elsif datum['wesabe_txid'].respond_to?(:split)
            # since the wesabe txid is based partly on the account,
            # we need to handle it specially.
            txaction.wesabe_txid = [account.id, *datum['wesabe_txid'].split(':')[1..-1]].join(':')
          end

          txaction.save(:validate => false)
          import_taggings(txaction, datum['taggings'] || [])
          import_attachments(datum['attachments'] || []).each do |attachment|
            txaction.attach(attachment)
            txaction.save(:validate => false)
          end

          txactions[datum['id']] = [txaction, datum]
        end
      end
    end

    def import_investment_txactions(account, data)
      data.map do |datum|
        returning InvestmentTxaction.new do |txaction|
          txaction.upload_id            = 0 # the schema enforces a non-null value
          txaction.account              = account
          txaction.txid                 = datum['txid']
          txaction.memo                 = datum['memo']
          txaction.original_trade_date  = datum['original_trade_date']
          txaction.original_settle_date = datum['original_settle_date']
          txaction.trade_date           = datum['trade_date']
          txaction.settle_date          = datum['settle_date']
          txaction.units                = datum['units']
          txaction.unit_price           = datum['unit_price']
          txaction.commission           = datum['commission']
          txaction.fees                 = datum['fees']
          txaction.withholding          = datum['withholding']
          txaction.currency             = datum['currency']
          txaction.currency_rate        = datum['currency_rate']
          txaction.total                = datum['total']
          txaction.note                 = datum['note']
          txaction.buy_sell_type        = datum['buy_sell_type']
          txaction.income_type          = datum['income_type']
          txaction.sub_account_type     = datum['sub_account_type']
          txaction.sub_account_fund     = datum['sub_account_fund']
          txaction.investment_security  = InvestmentSecurity.find_by_unique_id(datum['investment_security'])

          txaction.save(:validate => false)
        end
      end
    end

    def import_investment_positions(account, data)
      data.map do |datum|
        returning InvestmentPosition.new do |position|
          position.upload_id              = 0 # the schema enforces a non-null value
          position.account                = account
          position.sub_account_type       = datum['sub_account_type']
          position.position_type          = datum['position_type']
          position.units                  = datum['units']
          position.unit_price             = datum['unit_price']
          position.market_value           = datum['market_value']
          position.memo                   = datum['memo']
          position.price_date             = datum['price_date']
          position.reinvest_dividends     = datum['reinvest_dividends']
          position.reinvest_capital_gains = datum['reinvest_capital_gains']
          position.investment_security    = InvestmentSecurity.find_by_unique_id(datum['investment_security'])

          position.save(:validate => false)
        end
      end
    end

    def import_balances(account, data)
      data.map do |datum|
        returning account.account_balances.new do |account_balance|
          account_balance.balance      = datum['balance']
          account_balance.balance_date = datum['balance_date']
          account_balance.status       = Constants::Status::ACTIVE

          account_balance.save(:validate => false)
        end
      end
    end

    def import_investment_balances(account, data)
      data.map do |datum|
        returning InvestmentBalance.new do |balance|
          balance.upload_id      = 0 # the schema enforces a non-null value
          balance.account        = account
          balance.avail_cash     = datum['avail_cash']
          balance.margin_balance = datum['margin_balance']
          balance.short_balance  = datum['short_balance']
          balance.buy_power      = datum['buy_power']
          balance.date           = datum['date']

          balance.save(:validate => false)

          (datum['other_balances'] || []).map do |other_balance_datum|
            returning InvestmentOtherBalance.new do |other_balance|
              other_balance.investment_balance = balance
              other_balance.name               = other_balance_datum['name']
              other_balance.description        = other_balance_datum['description']
              other_balance.date               = other_balance_datum['date']
              other_balance.value              = other_balance_datum['value']
              other_balance.type               = other_balance_datum['type']

              other_balance.save(:validate => false)
            end
          end
        end
      end
    end

    def import_account_merchant_tag_stats(data)
      data.map do |datum|
        returning AccountMerchantTagStat.new do |amts|
          amts.account_key = user.account_key
          amts.name        = datum['name']
          amts.merchant    = Merchant.find_or_create_by_name(datum['merchant'])
          amts.tag         = Tag.find_or_create_by_name(datum['tag'])
          amts.count       = datum['count']
          amts.forced      = datum['forced']
          amts.sign        = datum['sign']

          begin
            amts.save(:validate => false)
          rescue => e
            Rails.logger.error "unable to create AMTS: #{e}"
          end
        end
      end
    end

    def import_merchants(data)
      data.map do |datum|
        returning MerchantUser.new do |mu|
          mu.user              = user
          mu.merchant          = Merchant.find_or_create_by_name(datum['merchant'])
          mu.sign              = datum['sign']
          mu.autotags_disabled = datum['autotags_disabled']

          mu.save(:validate => false)
        end
      end
    end

    def import_taggings(txaction, data)
      data.map do |datum|
        tag = Tag.find_or_create_by_name(datum['tag'])
        returning txaction.taggings.build do |tagging|
          tagging.name             = tag.name
          tagging.tag              = tag
          tagging.split_amount     = datum['split_amount']
          tagging.usd_split_amount = datum['usd_split_amount']

          begin
            tagging.save(:validate => false)
          rescue => e
            Rails.logger.error "unable to create tagging: #{e}"
          end
        end
      end
    end

    def import_attachments(data)
      data.map do |datum|
        import_attachment(datum)
      end
    end

    def import_attachment(data)
      returning Attachment.new do |attachment|
        attachment.account_key  = user.account_key
        attachment.guid         = data['guid']
        attachment.filename     = data['filename']
        attachment.description  = data['description']
        attachment.content_type = data['content_type']
        attachment.size         = data['size']

        attachment.save(:validate => false)
      end
    end

    def import_target(data)
      tag = Tag.find_or_create_by_name(data['tag'])
      returning Target.new do |target|
        target.user             = user
        target.tag              = tag
        target.tag_name         = data['tag_name']
        target.amount_per_month = data['amount_per_month']
        target.save(:validate => false)
      end
    end

    def txactions
      @txactions ||= {}
    end

    def associate_transfers
      txactions.each do |id, (txaction, datum)|
        case datum['transfer']
        when true
          txaction.mark_as_unpaired_transfer!
        when false, nil
          # nothing to do
        else
          transfer, = txactions[datum['transfer']['id']]
          if transfer
            txaction.set_transfer_buddy!(transfer)
          else
            Rails.logger.warn "Unable to locate transfer for transaction (#{txaction.inspect}), marking it as unpaired"
            txaction.mark_as_unpaired_transfer!
          end
        end
      end
    end
  end
end
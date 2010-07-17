# REVIEW: This should be moved to the lib directory.
class Currency
  class <<self
    # REVIEW: doing this to get number_to_currency. Definitely messed up
    # pulling in rails view helper. Maybe I should just pull out the methods needed?
    include ActionView::Helpers::NumberHelper
  end

  attr_reader :name, :unit, :separator, :delimiter, :decimal_places, :full_name

  class UnknownCurrencyException < Exception; end

  def initialize(name = nil)
    name = 'USD' if name.blank?
    name = name.name if name.is_a?(Currency)
    if @@DATA[name]
      @name = name
      @unit, @separator, @delimiter, @decimal_places, @full_name = @@DATA[name]
    else
      raise UnknownCurrencyException.new("Unknown currency: '#{name}'")
    end
  end

  def self.usd
    new('USD')
  end

  # compare Currency by name since all other data comes from the name
  def ==(other)
    if other.is_a?(Currency)
      name == other.name
    elsif other.is_a?(String)
      name == other
    end
  end

  def to_s
    name
  end

  # return true if the given currency code is known
  def self.known?(name)
    !!@@DATA[name]
  end

  # return true if we have exchange rate support for this currency
  def supported?
    CurrencyExchangeRate.supported?(self)
  end

  # return the currency data
  def self.data
    @@DATA
  end

  def self.all
    @@DATA.map {|name,| new(name)}
  end

  def self.units
    all.map {|currency| currency.unit}
  end

  def self.currencies_by_unit
    all.group_by {|currency| currency.unit}
  end

  def self.unambiguous_currencies
    currencies = []
    currencies_by_unit.each do |name, list|
      currencies << list.first if list.size == 1
    end
    currencies
  end

  # return an array of currencies
  def self.list
    @@DATA.keys.sort
  end

  # convert currency amounts to US-standard decimal
  # e.g. "$2,000.00" => "2000.00"
  #      "€2.000,00" => "2000.00"
  def self.normalize(amt)
    amt = amt.to_s
    return if amt.blank?
    # remove all special symbols
    amt.gsub!(/[^\d,.-]/,'')

    # if there is just a single delimiter, and it is a period, assume it is the decimal separator
    if amt.scan(/([,.])/).size == 1 && $1 == '.'
      amt.gsub!(/[^.\d-]/,'')
    else
      # if there is a comma or period followed by two digits at the end, assume that's the decimal place
      if m = amt.match(/[,.](\d{2})$/)
        decimal = ".#{m[1]}"
        amt = amt[0..-4].gsub(/[,.]/,'')
      else
        # remove thousands separators
        if m = amt.match(/\d+(\D)\d{3}($|\D)/)
          amt.gsub!(m[1],'')
        end
        # any comma left now should be a decimal separator; replace that w/ a period
        amt.tr!(',','.')
      end
    end

    ("%.02f" % "#{amt}#{decimal}".to_f).to_s
  end

  # format a number as currency
  # options:
  #   :markup - adds html markup around negative numbers if true (default: false)
  #   :hide_unit - does not display the unit symbol if true (default: false)
  #   :hide_delimiter - does not display the thousands delimiter if true (default: false)
  #   :force_decimal - always uses a '.' as the decimal point if true (default: false)
  #   :as_decimal - if true, shortcut for {:hide_unit => true, :hide_delimiter => true, :force_decimal => true} (default: false)
  #   :show_currency - adds the currency abbreviation before the currency symbol
  #   :precision - number of decimal places
  def self.format(amount, currency = nil, options = {})
    amount ||= 0
    currency ||= 'USD'
    currency = Currency.new(currency) if currency.kind_of?(String)

    formatted_amount = Money.new(amount, currency).to_s(
      :unit => (options[:hide_unit] || options[:as_decimal]) ? '' : currency.unit,
      :separator => options[:as_decimal] ? '.' : currency.separator,
      :delimiter => (options[:hide_delimiter] || options[:as_decimal]) ? '' : currency.delimiter,
      :precision => options[:precision] || currency.decimal_places
    )
    formatted_amount = currency.name + ' ' + formatted_amount if options[:show_currency]
    if options[:markup] && amount >= 0
      return %{<span class="credit">%s</span>} % formatted_amount
    else
      return formatted_amount
    end
  end

  # all ISO 4217 currencies
  # any currency with a '¤' as a symbol means that I couldn't find a symbol for that currency. (¤ is the symbol
  # used when the appropriate currency symbol is not available)
  # NOTE: TextMate appears to have a bug that messes up the display for some special-character currencies,
  # making it appear as if fields are swapped (e.g. first line, AED)
  # unit, separator (radix point), delimiter (thousands separator), digits after decimal, full name
  @@DATA = {
    'AED' => ['د.إ',',','.',2,'United Arab Emirates dirham'],
    'AFN' => ['¤',',','.',2,'Afghanistan afghani'],
    'ALL' => ['¤',',','.',2,'Albanian lek'],
    'AMD' => ['դր.',',','.',2,'Armenian dram'],
    'ANG' => ['ƒ',',','.',2,'Netherlands Antillian guilder'],
    'AOA' => ['Kz',',','.',2,'Angolan kwanza'],
    'ARS' => ['$',',','.',2,'Argentine peso'],
    'AUD' => ['$','.',',',2,'Australian dollar'],
    'AWG' => ['ƒ',',','.',2,'Aruban guilder'],
    'AZN' => ['m',',','.',2,'Azerbaijanian manat'],
    'BAM' => ['KM',',','.',2,'Bosnia and Herzegovina convertible marks'],
    'BBD' => ['Bds$',',','.',2,'Barbados dollar'],
    'BDT' => ['৳',',','.',2,'Bangladeshi taka'],
    'BGN' => ['лв',',','.',2,'Bulgarian lev'],
    'BHD' => ['BD',',','.',3,'Bahraini dinar'],
    'BIF' => ['FBu',',','.',0,'Burundian franc'],
    'BMD' => ['BD$',',','.',2,'Bermuda dollar'],
    'BND' => ['$','.',',',2,'Brunei dollar'],
    'BOB' => ['Bs.',',','.',2,'Bolivian boliviano'],
    'BRL' => ['R$',',','.',2,'Brazilian real'],
    'BSD' => ['BS$',',','.',2,'Bahamian dollar'],
    'BTN' => ['¤',',','.',2,'Bhutanese ngultrum'],
    'BWP' => ['P','.',',',2,'Botswana pula'],
    'BYR' => ['Br',',','.',0,'Belarusian ruble'],
    'BZD' => ['BZ$',',','.',2,'Belize dollar'],
    'CAD' => ['$','.',',',2,'Canadian dollar'],
    'CDF' => ['F',',','.',2,'Congolese franc'],
    'CHF' => ['CHF',',','.',2,'Swiss franc'],
    'CLP' => ['$',',','.',0,'Chilean peso'],
    'CNY' => ['¥',',','.',2,'Chinese renminbi'],
    'COP' => ['$',',','.',2,'Colombian peso'],
    'COU' => ['$',',','.',2,'Colombian Unidad de Valor Real'],
    'CRC' => ['₡',',','.',2,'Costa Rican colón'],
    'CUP' => ['$',',','.',2,'Cuban peso'],
    'CVE' => ['Esc',',','.',2,'Cape Verdean escudo'],
    'CYP' => ['£',',','.',2,'Cypriot pound'],
    'CZK' => ['Kč',',','.',2,'Czech koruna'],
    'DJF' => ['Fdj',',','.',0,'Djiboutian franc'],
    'DKK' => ['kr',',','.',2,'Danish krone'],
    'DOP' => ['RD$',',','.',2,'Dominican peso'],
    'DZD' => ['دج',',','.',2,'Algerian dinar'],
    'EEK' => ['KR',',',' ',2,'Estonian kroon'],
    'EGP' => ['£',',','.',2,'Egyptian pound'],
    'ERN' => ['Nfk',',','.',2,'Eritrean nakfa'],
    'ETB' => ['Br',',','.',2,'Ethiopian birr'],
    'EUR' => ['€',',',' ',2,'Euro'],
    'FJD' => ['FJ$',',','.',2,'Fijian dollar'],
    'FKP' => ['£',',','.',2,'Falkland Islands pound'],
    'GBP' => ['£','.',',',2,'UK Pound sterling'],
    'GEL' => ['¤',',','.',2,'Georgian lari'],
    'GHC' => ['¢',',','.',2,'Ghanaian cedi'],
    'GIP' => ['£',',','.',2,'Gibraltar pound'],
    'GMD' => ['D',',','.',2,'Gambian dalasi'],
    'GNF' => ['FG',',','.',0,'Guinea franc'],
    'GTQ' => ['Q',',','.',2,'Guatemalan quetzal'],
    'GYD' => ['$',',','.',2,'Guyanese dollar'],
    'HKD' => ['$','.',',',2,'Hong Kong dollar'],
    'HNL' => ['L',',','.',2,'Honduran lempira'],
    'HRK' => ['kn',',','.',2,'Croatian kuna'],
    'HTG' => ['G',',','.',2,'Haitian gourde'],
    'HUF' => ['Ft',',',' ',2,'Hungarian forint'],
    'IDR' => ['Rp',',','.',2,'Indonesian rupiah'],
    'ILS' => ['₪','.',',',2,'Israeli new sheqel'],
    'INR' => ['Rs','.',',',2,'Indian rupee'],
    'IQD' => ['ع.د',',','.',3,'Iraqi dinar'],
    'IRR' => ['﷼',',','.',2,'Iranian rial'],
    'ISK' => ['kr',',','.',2,'Icelandic króna'],
    'JMD' => ['$',',','.',2,'Jamaican dollar'],
    'JOD' => ['¤',',','.',3,'Jordanian dinar'],
    'JPY' => ['¥','.',',',0,'Japanese yen'],
    'KES' => ['KSh',',','.',2,'Kenyan shilling'],
    'KGS' => ['¤',',','.',2,'Kyrgyzstani som'],
    'KHR' => ['៛',',','.',2,'Cambodian riel'],
    'KMF' => ['¤',',','.',0,'Comorian franc'],
    'KPW' => ['₩','.',',',2,'North Korean won'],
    'KRW' => ['₩','.',',',0,'South Korean won'],
    'KWD' => ['د.ك',',','.',3,'Kuwaiti dinar'],
    'KYD' => ['$',',','.',2,'Cayman Islands dollar'],
    'KZT' => ['〒',',','.',2,'Kazakhstani tenge'],
    'LAK' => ['₭',',','.',2,'Lao kip'],
    'LBP' => ['ل.ل',',','.',2,'Lebanese lira'],
    'LKR' => ['₨','.',',',2,'Sri Lankan rupee'],
    'LRD' => ['L$',',','.',2,'Liberian dollar'],
    'LSL' => ['M',',','.',2,'Lesotho loti'],
    'LTL' => ['Lt',',','.',2,'Lithuanian litas'],
    'LVL' => ['Ls',',','.',2,'Latvian lats'],
    'LUF' => ['LD',',','.',3,'Libyan dinar'],
    'MAD' => ['د.م.',',','.',2,'Moroccan dirham'],
    'MDL' => ['¤',',','.',2,'Moldovan leu'],
    'MGA' => ['¤',',','.',0,'Malagasy ariary'],
    'MKD' => ['¤',',','.',2,'Macedonian denar'],
    'MMK' => ['K',',','.',2,'Myanma kyat'],
    'MNT' => ['₮',',','.',2,'Mongolian tugrug'],
    'MOP' => ['MOP$',',','.',2,'Macanese pataca'],
    'MRO' => ['UM',',','.',2,'Mauritanian ouguiya'],
    'MTL' => ['₤',',','.',2,'Maltese lira'],
    'MUR' => ['₨',',','.',2,'Mauritian rupee'],
    'MVR' => ['Rf',',','.',2,'Maldivian rufiyaa'],
    'MWK' => ['MK',',','.',2,'Malawian kwacha'],
    'MXN' => ['$',',','.',2,'Mexican peso'],
    'MXV' => ['$',',','.',2,'Mexican Unidad de Inversion'],
    'MYR' => ['RM','.',',',2,'Malaysian ringgit'],
    'MZN' => ['MTn',',','.',2,'Mozambican metical'],
    'NAD' => ['N$',',','.',2,'Namibian dollar'],
    'NGN' => ['₦','.',',',2,'Nigerian naira'],
    'NIO' => ['C$',',','.',2,'Nicaraguan córdoba'],
    'NOK' => ['kr',',','.',2,'Norwegian krone'],
    'NPR' => ['₨',',','.',2,'Nepalese rupee'],
    'NZD' => ['$','.',',',2,'New Zealand dollar'],
    'OMR' => ['﷼',',','.',3,'Omani rial'],
    'PAB' => ['PAB',',','.',2,'Panamanian balboa'],
    'PEN' => ['S/.',',','.',2,'Peruvian nuevo sol'],
    'PGK' => ['K',',','.',2,'Papua New Guinean kina'],
    'PHP' => ['₱','.',',',2,'Philippine peso'],
    'PKR' => ['Rs.','.',',',2,'Pakistani rupee'],
    'PLN' => ['zł',',','.',2,'Polish złoty'],
    'PYG' => ['G',',','.',0,'Paraguayan guaraní'],
    'QAR' => ['﷼',',','.',2,'Qatari riyal'],
    'ROL' => ['L',',','.',2,'Romanian leu'],
    'RON' => ['L',',','.',2,'Romanian new leu'],
    'RSD' => ['дин.',',','.',2,'Serbian dinar'],
    'RUB' => ['руб',',','.',2,'Russian ruble'],
    'RWF' => ['RF',',','.',0,'Rwandan franc'],
    'SAR' => ['﷼',',','.',2,'Saudi riyal'],
    'SBD' => ['SI$','.',',',2,'Solomon Islands dollar'],
    'SCR' => ['SR',',','.',2,'Seychellois rupee'],
    'SDD' => ['£Sd',',','.',2,'Sudanese dinar'],
    'SDG' => ['¤',',','.',2,'Sudanese pound'],
    'SEK' => ['kr',',','.',2,'Swedish krona'],
    'SGD' => ['S$','.',',',2,'Singapore dollar'],
    'SHP' => ['£',',','.',2,'Saint Helena pound'],
    'SKK' => ['Sk',',','.',2,'Slovak koruna'],
    'SLL' => ['Le',',','.',2,'Sierra Leonean leone'],
    'SOS' => ['So. Sh.',',','.',2,'Somali shilling'],
    'SRD' => ['$',',','.',2,'Surinamese dollar'],
    'STD' => ['Db',',','.',2,'São Tomé and Príncipe dobra'],
    'SYP' => ['S£',',','.',2,'Syrian pound'],
    'SZL' => ['E',',','.',2,'Swazi lilangeni'],
    'THB' => ['฿','.',',',2,'Thai bhat'],
    'TJS' => ['¤',',','.',2,'Tajikistani somoni'],
    'TMM' => ['m',',','.',2,'Turkmenistani manat'],
    'TND' => ['د.ت',',','.',3,'Tunisian dinar'],
    'TOP' => ['T$',',','.',2,"Tongan pa'anga"],
    'TRY' => ['YTL',',','.',2,'Turkish new lira'],
    'TTD' => ['$',',','.',2,'Trinidad and Tobago dollar'],
    'TWD' => ['$','.',',',2,'New Taiwan dollar'],
    'TZS' => ['TSh',',','.',2,'Tanzanian shilling'],
    'UAH' => ['₴',',','.',2,'Ukrainian hryvnia'],
    'UGX' => ['USh',',','.',2,'Ugandan shilling'],
    'USD' => ['$','.',',',2,'United States dollar'],
    'UYU' => ['$',',','.',2,'Uruguayan peso'],
    'UZS' => ['¤',',','.',2,'Uzbekistani som'],
    'VEB' => ['Bs',',','.',2,'Venezuelan bolívar'],
    'VEF' => ['BsF',',','.',2,'Venezuelan bolívar fuerte'],
    'VND' => ['₫',',','.',2,'Vietnamese đồng'],
    'VUV' => ['Vt',',','.',0,'Vanuatu vatu'],
    'WST' => ['WS$',',','.',2,'Samoan tala'],
    'XAF' => ['CFA',',','.',0,'Central African CFA franc'],
    'XCD' => ['$',',','.',2,'East Caribbean dollar'],
    'XOF' => ['CFA',',','.',0,'West African CFA franc'],
    'XPF' => ['F',',','.',0,'CFP franc'],
    'YER' => ['﷼',',','.',2,'Yemeni rial'],
    'ZAR' => ['R',',','.',2,'South African rand'],
    'ZMK' => ['ZK',',','.',2,'Zambian kwacha'],
    'ZWD' => ['$',',','.',2,'Zimbabwe dollar']
  }
end

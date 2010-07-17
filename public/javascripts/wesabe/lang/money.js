wesabe.provide('lang.money');

/**
 * Provides methods for formatting and converting money.
 */
wesabe.lang.money = {
  CURRENCIES: {
    USD: {unit: '$', name: 'USD', delimiter: ',', separator: '.', precision: 2}
  },

  toMoney: function(moneyOrNumber, currency) {
    if (moneyOrNumber.hasOwnProperty('currency')) {
      return moneyOrNumber;
    }
    else {
      currency = either(currency, wesabe.data.preferences.getDefaultCurrency());
      var money = {currency: currency};
      money[currency] = moneyOrNumber;
      return money;
    }
  },

  /**
  * Returns a copy of the money object passed in. Optionally function can be
  * passed in to mutate the cloning process.
  * @see #abs for example of using mutate
  * @public
  */

  clone: function(money, mutate) {
    var klone = {};

    for (var attr in money) {
      klone[attr] = (attr == 'currency') ?
        money[attr] : (mutate ? mutate(money[attr]) : money[attr]);
    }

    return klone;
  },

  /**
   * Returns a marked up formatted amount. If it's a positive amount,
   * it's wrapped in a +span+ with class +credit+.
   *
   * It takes the same parameters as #format.
   *
   * @see #format
   *
   * @public
   */
  formatWithMarkup: function(money, options) {
    money = wesabe.lang.money.toMoney(money);
    var html = wesabe.lang.money.format(money, options);
    return (money[money.currency] >= 0) ? '<span class="credit">'+html+'</span>' : html;
  },

  /**
   * Formats a money amount.
   *
   *   wesabe.lang.money.format(20) // => "$20.00"
   *
   * Custom currency units, separators, delimiters, and precision can be used:
   *
   *   wesabe.lang.money.format(4500,
   *     {unit: "¥", separator: "", delimiter: ",", precision: 0}) // => "¥4,500"
   *
   * Or you can set them by providing a currency:
   *
   *   wesabe.lang.money.format(4500, {currency: "JPY"}) // => "¥4,500"
   *
   * It also works by providing a +Money+ object:
   *
   *   wesabe.lang.money.format({GBP: 43.21, currency: "GBP"}); // => "£43.21"
   *
   * @param money [Money,Number]
   *   Either a number amount or a +Money+ object with currency.
   * @param options [Object]
   *   currency [String]
   *     3-letter abbreviation of the currency to use (defaults to 'USD')
   *   separator [String]
   *     separates the whole and fractional parts (defaults to '.')
   *   delimiter [String]
   *     delimits numeric groups in the whole part (defaults to ',')
   *   precision [Number]
   *     number of digits in the fractional part to show (defaults to 2)
   *   unit [String]
   *     the currency symbol to use (defaults to '$')
   *   negativePrefix [String]
   *     prepended when +money+ is negative
   *   negativeSuffix [String]
   *     appended when +money+ is negative
   *   positivePrefix [String]
   *     prepended when +money+ is positive
   *   positiveSuffix [String]
   *     appended when +money+ is positive
   *
   * @return [String]
   *   A formatted string representing the amount given.
   *
   * @public
   */
  format: function(money, options) {
    var string = '', prefix = '', suffix = '';
    options = options || {};
    money = wesabe.lang.money.toMoney(money, options.currency);

    var amount = wesabe.lang.money.amount(money, money.currency);
    var currency = wesabe.lang.money.currency(money.currency);

    var delimiter = either(options.delimiter, currency.delimiter, ',');
    var separator = either(options.separator, currency.separator, '.');
    var precision = either(options.precision, currency.precision, 2);
    var unit      = either(options.unit, currency.unit, '$');

    if (amount < 0) {
      amount = -amount;
      prefix += either(options.negativePrefix, '-');
      suffix += either(options.negativeSuffix, '');
    } else {
      prefix += either(options.positivePrefix, '');
      suffix += either(options.positiveSuffix, '');
    }
    prefix += unit;

    // breaks amount=23.45 into whole=23 and fractional=45 (depending on precision)
    var fractional = Math.round((amount-parseInt(amount))*Math.pow(10, precision));
    var whole = precision == 0 ? Math.round(amount) : parseInt(amount);

    string += whole.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1"+delimiter);
    if (precision) {
      string += separator;
      string += this._pad(fractional, precision);
    }

    return prefix+string+suffix;
  },

  /**
   * Left pads a string or number up to {length}.
   *
   * @param {number|string} object The value to add padding to.
   * @param {!number} length The total desired length of the return value.
   * @param {string=} padding The padding to use (' ' for strings, '0' for numbers).
   * @return {string}
   */
  _pad: function(object, length, padding) {
    if (!padding)
      padding = (typeof object == 'number') ? '0' : ' ';
    object = object+'';
    while (object.length < length)
      object += padding;
    return object;
  },

  currency: function(name) {
    if (typeof name == 'string' && wesabe.lang.money.CURRENCIES[name])
      return wesabe.lang.money.CURRENCIES[name];
    else
      return { name: name };
  },

  amount: function(money) {
    if (money)
      return money[money.currency];
  },

  abs: function (money) {
    return wesabe.lang.money.clone(money,function(attr){
      return Math.abs(attr);
    });
  }
};

wesabe.ready('wesabe.data.currencies.sharedCurrencySet', function(currencySet) {
  function updateCurrencies() {
    wesabe.lang.money.CURRENCIES = currencySet.get();
  }

  updateCurrencies();
  currencySet.subscribe(updateCurrencies);
});

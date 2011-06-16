/**
 * Manages a set of currencies and includes a shared set for global use.
 */
wesabe.$class('data.currencies.CurrencySet', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    /**
     * Currencies mapped by code.
     *
     * @type {object}
     */
    currencies: null,

    /**
     * Sorted array of currencies.
     *
     * @type {Array.<object>}
     */
    currencyList: function() {
      if (!this._currencyList) {
        var data = this._currencies, list = [];

        for (var key in data) {
          if (data.hasOwnProperty(key)) {
            data[key].code = key;
            list.push(data[key]);
          }
        }

        this._currencyList = list.sort(function(a, b) {
          return (a.code < b.code) ? -1 :
                 (a.code > b.code) ?  1 :
                                      0;
        });
      }

      return this._currencyList;
    },

    /**
     * Sets the data behind this +CurrencySet+. It should be a map from symbol to
     * either an array of properties or an object literal.
     *
     * @param {!object} data
     */
    setCurrencies: function(data) {
      this.currencies = this._normalize(data);
      this.trigger('change', [this._currencies]);
    },

    /**
     * Normalizes the data format to be a map of currency symbol to an object description.
     *
     * @param {!object} data
     * @return {object} the given argument, +data+.
     */
    _normalize: function(data) {
      var row;
      for (var currency in data) {
        row = data[currency]
        if ($.isArray(row))
          data[currency] = {unit:row[0], separator:row[1], delimiter:row[2], precision:row[3], name:row[4]}
      }
      return data;
    }
  });

  $.extend($package, {
    sharedCurrencySet: new $class(),

    get: function() {
      return $package.sharedCurrencySet.get('currencies');
    },

    set: function(data) {
      $package.sharedCurrencySet.set('currencies', data);
    }
  });
});

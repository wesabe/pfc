/**
 * Wraps a currency drop-down <select> element.
 */
wesabe.$class('views.widgets.CurrencyDropDownField', wesabe.views.widgets.DropDownField, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _currencySet: null,
    _currencySetChangeHandler: null,

    init: function(element, delegate, currencySet) {
      var me = this;

      if (!wesabe.isJQuery(element))
        currencySet = delegate, delegate = element, element = null;

      $super.init.call(me, element, delegate);

      me._currencySetChangeHandler = function(){ me.onCurrencySetChange() };
      me.setCurrencySet(currencySet || wesabe.data.currencies.sharedCurrencySet);
    },

    getCurrencySet: function() {
      return this._currencySet;
    },

    setCurrencySet: function(currencySet) {
      if (currencySet === this._currencySet)
        return;

      if (this._currencySet)
        this._currencySet.unbind('change', this._currencySetChangeHandler);

      this._currencySet = currencySet;
      this._currencySet.bind('change', this._currencySetChangeHandler);

      // trigger a refresh
      this._currencySetChangeHandler();
    },

    onCurrencySetChange: function() {
      this.clearOptions();

      var currencies = this._currencySet.getList();

      for (var i = 0, length = currencies.length; i < length; i++)
        this.addOption(currencies[i].code);
    }
  });
});

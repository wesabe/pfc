/**
 * Wraps an element for displaying a formatted monetary amount.
 */
wesabe.$class('wesabe.views.widgets.MoneyLabel', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import $ as jQuery
  var $ = jQuery;
  // import wesabe.lang.number
  var number = wesabe.lang.number;
  // import wesabe.lang.money
  var money = wesabe.lang.money;

  $.extend($class.prototype, {
    _money: null,
    _currency: null,
    _className: null,
    _amountClassesEnabled: false,
    _showSignum: null,

    init: function(element, money) {
      $super.init.call(this, element);
      if (money) this.setMoney(money);
    },

    /**
     * Sets the new value of the label, overriding any previous
     * calls to {#setCurrency} and instead using {money.display}.
     */
    setMoney: function(money) {
      if (this._money === money || (this._money && money &&
        this._money.value === money.value &&
        this._money.display === money.display))
        return;

      this._money = money && {
        display: money.display,
        value: number.parse(money.value)
      };
      this._currency = null;
      this._className = (money && money.value < 0) ? 'debit' : 'credit';
      this._redraw();
    },

    /**
     * Returns the override currency if one was specified.
     *
     * @return {string}
     */
    getCurrency: function() {
      return this._currency;
    },

    /**
     * Overrides the currency to use when formatting the amount for display,
     * overriding any display value included in the {money}. Changing the value
     * of this property will cause a redraw.
     *
     * @param {string} currency A 3-letter currency code, or null.
     */
    setCurrency: function(currency) {
      if (this._currency === currency)
        return;

      this._currency = currency;
      this._redraw();
    },

    /**
     * Returns the numerical value of the {money}, as for an edit field.
     */
    getValue: function() {
      if (!this._money) return;
      return this._money.value;
    },

    /**
     * Returns true if the "credit" and "debit" classes are applied to positive
     * and negative amounts, respectively, false otherwise.
     *
     * @return {boolean}
     */
    areAmountClassesEnabled: function() {
      return this._amountClassesEnabled;
    },

    /**
     * Sets whether or not this {MoneyLabel} applies the class "credit" to
     * positive amounts and "debit" to negative amounts. Changing the value of
     * this property will cause a redraw.
     *
     * @param {!boolean} amountClassesEnabled Whether to apply amount classes.
     */
    setAmountClassesEnabled: function(amountClassesEnabled) {
      if (amountClassesEnabled == this._amountClassesEnabled)
        return;

      this._amountClassesEnabled = amountClassesEnabled;
      this._redraw();
    },

    /**
     * Returns true or false if the signum should be forcibly shown or hidden,
     * respectively, or null if the signum should not be affected.
     *
     * @return {?boolean}
     */
    doesShowSignum: function() {
      return this._showSignum;
    },

    /**
     * Sets whether or not to show a signum prefix on the label, or null to
     * use the default setting for the particular value.
     *
     * @param {?boolean} showSignum
     */
    setShowSignum: function(showSignum) {
      this._showSignum = showSignum;
    },

    /**
     * Redraws the text of the label.
     *
     * @private
     */
    _redraw: function() {
      var text, className;

      if (!this._money) {
        // nothing we can do if we have no amount
        text = '';
      } else {
        if (!this._currency) {
          // no need to do formatting ourselves, just use the display value we're given
          text = this._money.display;
        } else {
          // alternate currency specified, format it ourselves
          text = money.format(this._money.value, {currency: this._currency});
        }

        var firstCharacter = text.substring(0,1),
            signum = (this._money.value < 0) ? '-' : '+';
        if (this._showSignum === true) {
          if (firstCharacter !== signum)
            text = signum+text;
        } else if (this._showSignum === false) {
          if (firstCharacter === signum)
            text = text.substring(1);
        }
      }

      if (this.areAmountClassesEnabled() && this._className)
        this.getElement().removeClass('credit debit').addClass(this._className);

      this.getElement().text(text);
    }
  });
});

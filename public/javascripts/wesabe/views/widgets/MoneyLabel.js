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
    /**
     * The override currency code if one was specified (e.g. "USD").
     *
     * @type {string}
     */
    currency: null,

    /**
     * The value of the label as a structured object.
     *
     * @type {object}
     */
    money: null,

    /**
     * true if the "credit" and "debit" classes are applied to positive
     * and negative amounts, respectively, false otherwise.
     *
     * @type {boolean}
     */
    amountClassesEnabled: false,

    /**
     * true or false if the signum should be forcibly shown or hidden,
     * respectively, or null if the signum should not be affected.
     *
     * @type {?boolean}
     */
    showSignum: null,

    /**
     * @private
     */
    _className: null,

    init: function(element, money) {
      $super.init.call(this, element);
      if (money) this.set('money', money);
    },

    /**
     * Sets the new value of the label, overriding any previous
     * calls to {#set('currency')} and instead using {money.display}.
     */
    setMoney: function(money) {
      if (this.money === money || (this.money && money &&
        this.money.value === money.value &&
        this.money.display === money.display))
        return;

      this.money = money && {
        display: money.display,
        value: number.parse(money.value)
      };
      this.set('currency', null);
      this._className = (money && money.value < 0) ? 'debit' : 'credit';
      this._redraw();
    },

    /**
     * Overrides the currency to use when formatting the amount for display,
     * overriding any display value included in the {money}. Changing the value
     * of this property will cause a redraw.
     */
    setCurrency: function(currency) {
      if (this.currency === currency)
        return;

      this.currency = currency;
      this._redraw();
    },

    /**
     * Returns the numerical value of the {money}, as for an edit field.
     */
    value: function() {
      if (!this.money) return;
      return this.money.value;
    },

    setAmountClassesEnabled: function(amountClassesEnabled) {
      if (amountClassesEnabled == this.amountClassesEnabled)
        return;

      this.amountClassesEnabled = amountClassesEnabled;
      this._redraw();
    },

    setShowSignum: function(showSignum) {
      if (this.showSignum === showSignum)
        return;

      this.showSignum = showSignum;
      this._redraw();
    },

    /**
     * Redraws the text of the label.
     *
     * @private
     */
    _redraw: function() {
      var text, className;

      if (!this.money) {
        // nothing we can do if we have no amount
        text = '';
      } else {
        if (!this.currency) {
          // no need to do formatting ourselves, just use the display value we're given
          text = this.money.display;
        } else {
          // alternate currency specified, format it ourselves
          text = money.format(this.money.value, {currency: this.currency});
        }

        var firstCharacter = text.substring(0,1),
            signum = (this.money.value < 0) ? '-' : '+';
        if (this.get('showSignum') === true) {
          if (firstCharacter !== signum)
            text = signum+text;
        } else if (this._showSignum === false) {
          if (firstCharacter === signum)
            text = text.substring(1);
        }
      }

      if (this.get('amountClassesEnabled') && this._className)
        this.get('element').removeClass('credit debit').addClass(this._className);

      this.get('element').text(text);
    }
  });
});

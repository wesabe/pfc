/**
 * CLASS DESCRIPTION
 */
wesabe.$class('wesabe.views.widgets.transactions.Transaction', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.number
  var number = wesabe.lang.number;

  $.extend($class.prototype, {
    _noteContainerElement: null,
    _noteLabel: null,

    _balanceLabel: null,
    _amountLabel: null,
    _dateLabel: null,
    _accountLabel: null,

    init: function(element) {
      $super.init.call(this, element);

      this._noteContainerElement = element.find('.notes');
      this._noteLabel = new wesabe.views.widgets.Label(this._noteContainerElement.find('.text-content'));
      this.registerChildWidget(this._noteLabel);

      this._balanceLabel = new wesabe.views.widgets.MoneyLabel(element.find('.balance'));
      this._amountLabel = new wesabe.views.widgets.MoneyLabel(element.find('.amount'));
      this._amountLabel.setShowSignum(false);
      this._amountLabel.setAmountClassesEnabled(true);
      this.registerChildWidgets(this._balanceLabel, this._amountLabel);

      this._dateLabel = new wesabe.views.widgets.Label(element.find('.transaction-date'), {
        format: function(date) {
          if (date) {
            return wesabe.lang.date.format(date, 'NNN') + ' ' + number.ordinalize(date.getDate()) +
              (date.getFullYear() != new Date().getFullYear() ? ' ' + date.getFullYear() : '');
          }
        }
      });
      this.registerChildWidget(this._dateLabel);

      this._accountLabel = new wesabe.views.widgets.Label(element.find('.account-name .text-content'), {
        format: function(account) {
          return account && account.name;
        }
      });
    },

    /**
     * Gets the text value of the note label.
     *
     * @return {?string}
     */
    getNote: function() {
      return this._noteLabel.getValue();
    },

    /**
     * Sets the text value of the note label.
     *
     * @param {?string} note
     */
    setNote: function(note) {
      this._noteLabel.setValue(note);
      if (note && note.length > 0) {
        this._noteContainerElement.addClass('on notes-on');
      } else {
        this._noteContainerElement.removeClass('on notes-on');
      }
    },

    /**
     * Gets the value of the date label.
     *
     * @return {date}
     */
    getDate: function() {
      return this._dateLabel.getValue();
    },

    /**
     * Sets the value of the date label.
     *
     * @param {date}
     */
    setDate: function(date) {
      this._dateLabel.setValue(date);
    },

    /**
     * Gets the account associated with this transaction.
     *
     * @return {object}
     */
    getAccount: function() {
      return this._accountLabel.getValue();
    },

    /**
     * Sets the account associated with this transaction.
     *
     * @param {object} account
     */
    setAccount: function(account) {
      if (account && !account.name) {
        var accounts = wesabe.data.accounts.sharedDataSource.getData().accounts;
        for (var i = accounts.length; i--;) {
          if (accounts[i].uri === account.uri) {
            account = accounts[i];
            break;
          }
        }
      }

      this._accountLabel.setValue(account);
    },

    /**
     * Gets the structured value of the balance label.
     *
     * @return {object}
     */
    getBalance: function() {
      return this._balanceLabel.getMoney();
    },

    /**
     * Sets the text value of the balance label.
     *
     * @param {?string|object} balance
     */
    setBalance: function(balance) {
      this._balanceLabel.setMoney(balance || {display: 'n/a'});
    },

    /**
     * Gets the structured value of the amount label.
     *
     * @return {object}
     */
    getAmount: function() {
      return this._amountLabel.getMoney();
    },

    /**
     * Sets the text value of the amount label.
     *
     * @param {?string|object} amount
     */
    setAmount: function(amount) {
      this._amountLabel.setMoney(amount);
    }
  });
});

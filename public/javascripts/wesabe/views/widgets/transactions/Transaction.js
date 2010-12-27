/**
 * CLASS DESCRIPTION
 */
wesabe.$class('wesabe.views.widgets.transactions.Transaction', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.number
  var number = wesabe.lang.number;

  $.extend($class.prototype, {
    /**
     * URI of this transaction if it has one.
     */
    uri: null,

    _noteContainerElement: null,
    _noteLabel: null,

    _checkNumberLabel: null,

    _balanceLabel: null,
    _amountLabel: null,
    _dateLabel: null,
    _accountLabel: null,

    _tags: undefined,
    _tagLinkList: null,

    _unedited: undefined,
    _merchant: undefined,
    _merchantLink: null,
    _merchantInfoElement: null,

    _account: undefined,
    _accountLink: null,

    _transfer: undefined,
    _transferContainerElement: null,
    _transferHoverBoxElement: null,
    _transferThisAccountLink: null,
    _transferOtherAccountLink: null,
    _transferFromOtherConjunctionLabel: null,
    _transferToOtherConjunctionLabel: null,

    init: function(element) {
      $super.init.call(this, element);

      this._noteContainerElement = element.find('.notes');
      this._noteLabel = new wesabe.views.widgets.Label(this._noteContainerElement.find('.text-content'));
      this.registerChildWidget(this._noteLabel);

      this._checkNumberLabel = new wesabe.views.widgets.Label(element.find('.check-number'), {
                                 format: function(c) {
                                   return c ? (' — Check #'+c) : '';
                                 }
                               });
      this.registerChildWidget(this._checkNumberLabel);

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

      this._accountLabel = new wesabe.views.widgets.HistoryLink(element.find('.account-name'), null, {
        format: function(account) {
          return account && account.name;
        }
      });
      this.registerChildWidget(this._accountLabel);

      this._tagLinkList = new wesabe.views.widgets.transactions.TagLinkList(element.find('.merchant-tags'));
      this.registerChildWidget(this._tagLinkList);

      this._merchantLink = new wesabe.views.widgets.HistoryLink(element.find('.merchant-name .text-content'));
      this._merchantInfoElement = element.find('.merchant-info');

      this._transferContainerElement = element.find('.transfer');
      this._transferHoverBoxElement = this._transferContainerElement.find('.hover-box');
      this._transferThisAccountLink = new wesabe.views.widgets.HistoryLink(this._transferContainerElement.find('.this-account'));
      this._transferOtherAccountLink = new wesabe.views.widgets.HistoryLink(this._transferContainerElement.find('.other-account'));
      this._transferFromOtherConjunctionLabel = new wesabe.views.widgets.Label(this._transferContainerElement.find('.from'));
      this._transferToOtherConjunctionLabel = new wesabe.views.widgets.Label(this._transferContainerElement.find('.to'));
    },

    /**
     * Sets the uri of this transaction if it has one.
     *
     * @param {?String} uri
     */
    setURI: function(uri) {
      this._uri = uri;
    },

    /**
     * Gets the text value of the note label.
     *
     * @return {?string}
     */
    getNote: function() {
      return this._noteLabel.get('value');
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
     * Gets the list of tags shown under the merchant.
     *
     * @return {array}
     */
    getTags: function() {
      return this._tags || [];
    },

    /**
     * Sets the list of tags to show under the merchant.
     *
     * @param {array} tags
     */
    setTags: function(tags) {
      this._tags = tags;
      this._tagLinkList.setTags(tags);
    },

    /**
     * Gets the merchant data for this transaction.
     *
     * @return {object}
     */
    getMerchant: function() {
      return this._merchant;
    },

    /**
     * Sets the merchant data for this transaction.
     *
     * @param {object} merchant
     */
    setMerchant: function(merchant) {
      var unedited = !merchant.name;

      this._merchant = merchant;
      this._merchantLink.setURI(unedited ? null : wesabe.views.shared.historyHash('/merchants/'+merchant.name));
      this._merchantLink.setText(merchant.name || merchant.uneditedName);
      this.setUnedited(unedited);
    },

    /**
     * Gets the value of the date label.
     *
     * @return {date}
     */
    getDate: function() {
      return this._dateLabel.get('value');
    },

    /**
     * Sets the value of the date label.
     *
     * @param {date}
     */
    setDate: function(date) {
      this._dateLabel.setValue(date && wesabe.lang.date.parse(date));
    },

    /**
     * Gets the account associated with this transaction.
     *
     * @return {object}
     */
    getAccount: function() {
      return this._accountLabel.get('value');
    },

    /**
     * Sets the account associated with this transaction.
     *
     * @param {object} account
     */
    setAccount: function(account) {
      account = account && this._getAccountDataByURI(account.uri);
      this._account = account;
      this._accountLabel.set('value', account);
      this._accountLabel.set('uri', account && account.uri);
    },

    /**
     * Returns whether or not the account label is shown.
     *
     * @return {boolean}
     */
    accountVisible: function() {
      return this._accountLabel.get('visible');
    },

    /**
     * Sets whether or not to show the account link.
     *
     * @param {!boolean} visible
     */
    setAccountVisible: function(visible) {
      this._accountLabel.set('visible', visible);
    },

    /**
     * Gets the structured value of the balance label.
     *
     * @return {object}
     */
    balance: function() {
      return this._balanceLabel.get('money');
    },

    /**
     * Sets the text value of the balance label.
     *
     * @param {?string|object} balance
     */
    setBalance: function(balance) {
      this._balanceLabel.set('money', balance || {display: 'n/a'});
    },

    /**
     * Returns the check number for this transaction or null if there is none.
     *
     * @return {?string}
     */
    checkNumber: function() {
      return this._checkNumberLabel.get('value');
    },

    /**
     * Sets the check number for this transaction, if it has one.
     *
     * @param {?string} checkNumber
     */
    setCheckNumber: function(checkNumber) {
      this._checkNumberLabel.set('value', checkNumber);
    },

    /**
     * Sets the balance text to an arbitrary string.
     *
     * @param {string} text
     */
    setBalanceText: function(text) {
      this.setBalance({display: text});
    },

    /**
     * Gets the structured value of the amount label.
     *
     * @return {object}
     */
    getAmount: function() {
      return this._amountLabel.get('money');
    },

    /**
     * Sets the text value of the amount label.
     *
     * @param {?string|object} amount
     */
    setAmount: function(amount) {
      this._amountLabel.setMoney(amount);
    },

    /**
     * Returns whether this transaction is considered unedited.
     *
     * @return {boolean}
     */
    isUnedited: function() {
      return this._unedited;
    },

    /**
     * Sets whether this transaction is considered unedited.
     *
     * @param {boolean} unedited
     */
    setUnedited: function(unedited) {
      if (unedited === this._unedited) return;

      this._unedited = unedited;
      if (this._unedited) {
        this._merchantInfoElement.addClass('unedited');
      } else {
        this._merchantInfoElement.removeClass('unedited');
      }
    },

    /**
     * Gets the transfer data for this transaction.
     *
     * @return {boolean|object}
     */
    getTransfer: function() {
      return this._transfer;
    },

    /**
     * Sets the transfer data for this transaction.
     *
     * @param {boolean|object}
     */
    setTransfer: function(transfer) {
      if (this._transfer === transfer) return;

      // TODO: move this to some sort of data wrapper for transactions
      if (transfer && transfer.amount)
        transfer.amount.value = number.parse(transfer.amount.value);

      this._transfer = transfer;

      if (!this.isTransfer()) {
        this._setTransferInfoVisible(false);
        this._transferContainerElement.removeClass('on transfer-on');
      } else if (!this.isPairedTransfer()) {
        this._setTransferInfoVisible(false);
        this._transferContainerElement.addClass('on transfer-on');
      } else {
        this._transferContainerElement.addClass('on transfer-on');

        var thisAccount = this.get('account'),
            otherAccount = transfer.account;

        thisAccount = thisAccount && this._getAccountDataByURI(thisAccount.uri);
        otherAccount = otherAccount && this._getAccountDataByURI(otherAccount.uri);

        if (!thisAccount || !otherAccount) {
          // one or both accounts are unavailable for some reason
          this._setTransferInfoVisible(false);
        } else {
          this._transferThisAccountLink.setText(thisAccount.name);
          this._transferThisAccountLink.setURI(thisAccount.uri);
          this._transferOtherAccountLink.setText(otherAccount.name);
          this._transferOtherAccountLink.setURI(otherAccount.uri);

          var isFromOther = transfer.amount.value < 0;
          this._transferFromOtherConjunctionLabel.setVisible(isFromOther);
          this._transferToOtherConjunctionLabel.setVisible(!isFromOther);

          this._setTransferInfoVisible(true);
        }
      }
    },

    /**
     * Returns whether or not this transaction is a transfer.
     *
     * @return {boolean}
     */
    isTransfer: function() {
      return !!this._transfer;
    },

    /**
     * Returns whether or not this transaction is a paired transfer.
     *
     * @return {boolean}
     */
    isPairedTransfer: function() {
      return this._transfer && (this._transfer !== true);
    },

    _getAccountDataByURI: function(uri) {
      return wesabe.data.accounts.sharedDataSource.getAccountDataByURI(uri);
    },

    _setTransferInfoVisible: function(visible) {
      if (visible) {
        // visible means "allow hover to make it display:block"
        this._transferHoverBoxElement.css('display', '');
        this._transferContainerElement.removeClass('solo');
      } else {
        // hidden means "set it to display:none so it won't show on hover"
        this._transferHoverBoxElement.css('display', 'none');
        this._transferContainerElement.addClass('solo');
      }
    }
  });
});

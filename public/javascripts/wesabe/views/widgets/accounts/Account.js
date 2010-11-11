/**
 * Wraps a <li class="account"> node in the accounts widget. Instances are
 * managed by an {AccountGroup} to which they delegate both selection and
 * DOM event handling.
 */
wesabe.$class('wesabe.views.widgets.accounts.Account', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.date
  var date = wesabe.lang.date;

  $.extend($class.prototype, {
    // state
    _editMode: false,

    // data
    _credential: null,
    _name: null,
    _uri: null,
    _currency: null,
    _status: null,
    _type: null,
    _balance: null,
    _marketValue: null,
    _lastBalanceDate: null,
    _investment_positions: null,
    _investment_balance: null,
    _data: null,

    // references
    _accountGroup: null,
    _nameElement: null,
    _editButtonElement: null,
    _cashAccountStatusElement: null,
    _ssuStatusElement: null,
    _ssuUpdateSpinner: null,
    _ssuErrorStatusElement: null,
    _manualUploadStatusElement: null,
    _uploadStatusElement: null,
    _accountStatusElements: null,

    // child widgets
    _total: null,
    _ssuErrorHoverBox: null,
    _manualUploadHoverBox: null,

    init: function(element, accountGroup) {
      $super.init.call(this, element);
      this._accountGroup = accountGroup;

      var container = element.children('span.account-name');
      this._nameElement = container.children('.text-content');
      this._total = new wesabe.views.widgets.MoneyLabel(container.children('.balance'));
      this._editButtonElement = element.find('.edit');

      this._accountStatusElements = element.children('.account-status');
      this._cashAccountStatusElement = this._accountStatusElements.filter('.cash');
      this._ssuStatusElement = this._accountStatusElements.filter('.update:not(.error)');
      this._ssuUpdateSpinner = this._ssuStatusElement.find('.updating-spinner');
      this._ssuErrorStatusElement = this._accountStatusElements.filter('.update.error');
      this._ssuErrorHoverBox = new $package.AutomaticUploaderErrorDialog(this._ssuErrorStatusElement.find('.hover-box'), this);
      this._manualUploadStatusElement = this._accountStatusElements.filter('.upload');
      this._manualUploadHoverBox = new $package.ManualUploadDialog(this._manualUploadStatusElement.find('.hover-box'), this);
      this._uploadStatusElement = this._accountStatusElements.filter('.upload');
      this._restoreAccountStatus();

      this.registerChildWidgets(this._total, this._ssuErrorStatusElement, this._manualUploadHoverBox);
    },

    /**
     * Gets the name of the account (e.g. "Bank of America - Checking").
     */
    getName: function() {
      return this._name;
    },

    /**
     * Sets the name of this {Account} and updates the text, but does not
     * update the name on the server.
     */
    setName: function(name) {
      if (this._name === name)
        return;

      this._name = name;
      this._nameElement.text(name);
    },

    setLastBalanceDate: function(lastBalanceDate) {
      if (this._lastBalanceDate === lastBalanceDate)
        return;

      this._lastBalanceDate = lastBalanceDate;
      this.getElement().attr('title', lastBalanceDate ? 'Updated ' + date.timeAgoInWords(lastBalanceDate) : '');
    },

    /**
     * Gets the URI for this {Account} (e.g. "/accounts/1").
     *
     * See {wesabe.views.pages.accounts#storeState}.
     */
    getURI: function() {
      return this._uri;
    },

    /**
     * Gets the transactions URI for this {Account} (e.g. "/accounts/1/transactions").
     *
     * See {wesabe.views.pages.accounts#storeState}.
     */
    getTransactionsURI: function() {
      if (this._type === "Investment")
        return this.getURI() + '/investment-transactions';
      else
        return this.getURI() + '/transactions';
    },

    /**
     * Gets the URL parameters for this {Account}.
     *
     * See {wesabe.views.pages.accounts#paramsForCurrentSelection}.
     */
    toParams: function() {
      return [{name: 'account', value: this.getURI()}];
    },

    /**
     * Gets the currency code for this account (e.g. "USD").
     */
    getCurrency: function() {
      return this._currency;
    },

    /**
     * Sets the display currency for this account, but does not update
     * the value of the currency on the server.
     */
    setCurrency: function(currency) {
      if (this._currency === currency)
        return;

      this._currency = currency;
      this._total.setCurrency(currency);
    },

    /**
     * Gets the single currency for this account as an array.
     *
     * See {wesabe.views.pages.accounts#paramsForCurrentSelection}.
     */
    getCurrencies: function() {
      return [this.getCurrency()];
    },

    /**
     * Returns the investment positions associated with this {Account}
     */
    getInvestmentPositions: function() {
      return this._investment_positions;
    },

    /**
     * Returns the investment balance associated with this {Account}
     */
    getInvestmentBalance: function(balance) {
      if (this._investment_balance) {
        if (balance)
          return this._investment_balance[balance];
        else
          return this._investment_balance;
      }
    },

    /**
     * Returns the {wesabe.util.Selection} associated with this {Account}.
     */
    getSelection: function() {
      return this._accountGroup.getSelection();
    },

    hasBalance: function() {
      return hasValue(this._total.getValue());
    },

    getBalance: function() {
      return this._balance;
    },

    getMarketValue: function() {
      return this._marketValue;
    },

    getTotal: function() {
      return this._total.getValue();
    },

    isCash: function() {
      return (this._type == "Cash" || this._type == "Manual");
    },

    isInvestment: function() {
      return this._type === "Investment";
    },

    isArchived: function() {
      return (this._status == "archived");
    },

    isSSU: function() {
      return this.getCredential() ? true : false;
    },

    lastSSUJob: function() {
      var cred = this.getCredential();
      return cred && cred.last_job;
    },

    hasSSUError: function() {
      var lastJob = this.lastSSUJob();
      return lastJob && lastJob.status == 'failed';
    },

    isUpdating: function() {
      var lastJob = this.lastSSUJob();
      return lastJob && lastJob.status == 'pending';
    },

    /**
     * Gets the credential (i.e. ssu sync status) for this {Account}.
     */
    getCredential: function() {
      return this._credential;
    },

    /**
     * Sets the credential and updates the UI accordingly.
     */
    setCredential: function(credential) {
      var oldIsSSU = this.isSSU(),
          oldHasSSUError = this.hasSSUError(),
          oldIsUpdating = this.isUpdating();

      this._credential = credential;

      if (this.isSSU() !== oldIsSSU || this.hasSSUError() !== oldHasSSUError || this.isUpdating() !== oldIsUpdating)
        this._restoreAccountStatus();
    },

    /**
     * Handle clicks on this {Account}.
     *
     * NOTE: There is no accompanying bind statement because
     * this widget uses event delegation for the entire list
     * of accounts, see {AccountWidget#onClick}.
     */
    onClick: function(event) {
      if (event.target === this._editButtonElement[0]) {
        this.onBeginEdit();
      } else if (event.target === this._ssuStatusElement[0]) {
        this._startUpdate();
      } else if (event.target === this._ssuErrorStatusElement[0]) {
        this._ssuErrorHoverBox.toggle();
        event.stopPropagation();
      } else if (event.target === this._manualUploadStatusElement[0]) {
        this._manualUploadHoverBox.toggle();
        event.stopPropagation();
      } else {
        if (event.ctrlKey || event.metaKey) {
          this.getSelection().toggle(this);
        } else {
          this.getSelection().set(this);
        }
      }
    },

    /**
     * Tells the server to begin updating the credential associated with
     * this {Account} and restarts polling for job completion.
     *
     * @private
     */
    _startUpdate: function() {
      if (!this.isSSU())
        return;

      var ds = this._accountGroup.getCredentialDataSource();
      $.post(this.getCredential().uri+'/jobs', function() {
        ds.pollUntilSyncDone();
      });
    },

    /**
     * Called by {wesabe.util.Selection} instances when this object
     * becomes part of the current selection.
     */
    onSelect: function() {
      if (this.getElement())
        this.getElement().addClass('on');
      // ensure that the containing group is expanded
      if (this._accountGroup)
        this._accountGroup.animateExpanded(true);
    },

    /**
     * Called when the user chooses to start editing this account.
     */
    onBeginEdit: function() {
      if (this._accountGroup)
        this._accountGroup.onBeginEdit(this);
    },

    /**
     * Called by {wesabe.util.Selection} instances when this object
     * ceases to be part of the current selection.
     */
    onDeselect: function() {
      if (this.getElement())
        this.getElement().removeClass('on');
    },

    /**
     * Update the display for this {Account} based on new data.
     */
    update: function(accountData) {
      this.setName(accountData.name);
      this._status = accountData.status;
      this._type = accountData.type;
      this._uri = accountData.uri;
      this._credential = this._accountGroup.getCredentialDataSource().getCredentialDataByAccountURI(this._uri);
      this._currency = accountData.currency;
      this.setLastBalanceDate(date.parse(accountData['last-balance-at']));
      this._balance = accountData.balance;
      this._marketValue = accountData["market-value"];
      this._total.setMoney(accountData.balance);
      this._data = accountData;
      this._investment_positions = accountData["investment-positions"];
      this._investment_balance = accountData["investment-balance"];
      this._restoreAccountStatus();
    },

    /**
     * Sets the flag indicating whether this {Account} is currently
     * in account edit mode.
     */
    setEditMode: function(editMode) {
      if (editMode === this._editMode)
        return;

      this._editMode = editMode;

      if (editMode) {
        this._editButtonElement.show();
      } else {
        this._editButtonElement.hide();
      }

      this._restoreAccountStatus();
    },

    /**
     * Shows the account status element appropriate for the current status
     * of this {Account}.
     *
     * @private
     */
    _restoreAccountStatus: function() {
      this._accountStatusElements.hide();
      if (this._editMode)
        return;

      if (this.isSSU()) {
        if (this.hasSSUError()) {
          this._ssuErrorStatusElement.show();
        } else {
          this._ssuStatusElement.show();
          this._ssuUpdateSpinner.css('visibility', this.isUpdating() ? 'visible' : 'hidden');
        }
      } else if (this.isCash()) {
        this._cashAccountStatusElement.show();
      } else {
        this._uploadStatusElement.show();
      }
    }
  });
});

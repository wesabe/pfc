/**
 * Wraps the <div id="accounts"> element containing the list of accounts
 * on the page. Manages an {AccountGroupList} and handles most DOM events
 * for its descendants (google "event delegation").
 *
 * NOTE: This is intended to be a long-lived singleton and therefore does not
 * have any sort of cleanup function.
 */
wesabe.$class('wesabe.views.widgets.accounts.AccountWidget', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _editButton: null,
    _doneButton: null,
    _updateButton: null,
    _updateButtonSpinner: null,
    _total: null,
    _accountGroupList: null,
    _accountEditDialog: null,
    _selectableObjects: null,
    _loading: false,
    _editMode: false,
    _hasDoneInitialLoad: false,
    _accountDataSource: null,
    _credentialDataSource: null,

    init: function(element, accountDataSource, credentialDataSource) {
      $super.init.call(this, element);

      var me = this;

      me._accountDataSource = accountDataSource;
      me._credentialDataSource = credentialDataSource;
      // set up children
      me._accountGroupList = new $package.AccountGroupList(element.find('ul.account-groups'), me);
      me._total = new wesabe.views.widgets.MoneyLabel(element.find('.accounts-total .total'));
      me._editButton = new wesabe.views.widgets.Button(element.find('div.module-header a.edit-button'));
      me._editButton.bind('click', me.onEditButtonClick, me);
      me._doneButton = new wesabe.views.widgets.Button(element.find('div.module-header a.done-button'));
      me._doneButton.bind('click', me.onDoneButtonClick, me);
      me._updateButton = new wesabe.views.widgets.Button(element.find('div.module-header .update-button'));
      me._updateButtonSpinner = me._updateButton.get('element').children('.updating-spinner');
      me._updateButton.bind('click', me.triggerUpdates, me);

      // set up data source callbacks
      me._accountDataSource.subscribe({
        change: me.onAccountDataChanged,
        error: me.onAccountDataError
      }, me);

      // if we already have the data (preloaded), use it, otherwise load it
      if (me._accountDataSource.hasData()) {
        me.onAccountDataChanged(me._accountDataSource.get('data'));
      } else {
        me.loadData();
      }

      var creds = me._credentialDataSource;

      // set up the credential data source callbacks
      creds.subscribe(me.onUploadStatusChanged, me);

      if (!creds.hasData() || (creds.hasData() && creds.isUpdating()))
        creds.pollUntilSyncDone();

      // set up DOM event handlers
      element.click(function(event){ me.onClick(event) });

      me.registerChildWidgets(me._total, me._accountGroupList, me._editButton, me._doneButton, me._updateButton);
    },

    /**
     * Returns a boolean indicating whether this widget has done at least
     * one painting of the accounts.
     */
    hasDoneInitialLoad: function() {
      return this._hasDoneInitialLoad;
    },

    /**
     * Returns the {wesabe.util.Selection} associated with this {AccountWidget}.
     */
    getSelection: function() {
      return this._accountGroupList.get('selection');
    },

    /**
     * Sets the {wesabe.util.Selection} associated with this {AccountWidget}.
     */
    setSelection: function(selection) {
      this._accountGroupList.setSelection(selection);
    },

    /**
     * Gets the {CredentialDataSource} used to populate this {AccountGroupList}.
     */
    getCredentialDataSource: function() {
      return this._credentialDataSource;
    },

    /**
     * Gets the {AccountGroupList} wrapping the <ul class="account-groups">.
     */
    getAccountGroupList: function() {
      return this._accountGroupList;
    },

    /**
     * Gets the account with the given {uri}, returning null if it's not found.
     *
     * @param {!string} uri The unique identifier for the account to find.
     * @return {Account}
     */
    getAccountByURI: function(uri) {
      return this.get('accountGroupList').getAccountByURI(uri);
    },

    /**
     * Gets the {wesabe.views.widgets.MoneyLabel} wrapping the net worth line.
     */
    getTotal: function() {
      return this._total;
    },

    /**
     * Gets the {AccountEditDialog} singleton for this widget, passing it to
     * the callback when it becomes available.
     *
     * NOTE: This is lazy-loaded because account editing is relatively rare.
     */
    asyncGetAccountEditDialog: function(callback) {
      var me = this;

      if (me._accountEditDialog) {
        callback(me._accountEditDialog);
      } else {
        wesabe.ready('wesabe.views.widgets.accounts.AccountEditDialog', function() {
          var editDialogElement = me.get('element').find('div.edit-dialog');
          me._accountEditDialog = new $package.AccountEditDialog(editDialogElement, me);
          callback(me._accountEditDialog);
        });
      }
    },

    /**
     * Begins loading the account data if it is not already loaded.
     */
    loadData: function() {
      this.setLoading(true);
      this.refresh();
    },

    /**
     * Refresh the data used to draw this widget.
     */
    refresh: function() {
      this._accountDataSource.requestData();
      this._credentialDataSource.pollUntilSyncDone();
    },

    /**
     * Triggers updates of out-of-date SSU accounts for the user.
     */
    triggerUpdates: function() {
      var ds = this._credentialDataSource;
      $.post('/accounts/trigger-updates', function() {
        ds.pollUntilSyncDone();
      });
    },

    /**
     * Returns a boolean indicating whether this {AccountWidget} is currently
     * loading data from the servers.
     */
    getLoading: function() {
      return this._loading;
    },

    /**
     * Sets the flag indicating whether this {AccountWidget} is currently
     * loading data from the servers, hiding and showing the account data
     * appropriately.
     */
    setLoading: function(loading) {
      if (this._loading !== loading) {
        loading ? this.get('element').addClass('loading') :
                  this.get('element').removeClass('loading');
        this._loading = loading;
      }
    },

    /**
     * Sets the flag indicating whether this {AccountWidget} is currently
     * in account edit mode (expands all groups, shows editing pencils).
     */
    setEditMode: function(editMode) {
      if (editMode === this._editMode)
        return;

      this._editMode = editMode;
      this._editButton.setVisible(!editMode);
      this._doneButton.setVisible(editMode);
      this._updateButton.setVisible(!editMode);

      if (!editMode) {
        if (this._accountEditDialog)
          this._accountEditDialog.onEndEdit();
      }

      this._accountGroupList.setEditMode(editMode);

      if (!$package.AccountEditDialog)
        wesabe.load($package, 'AccountEditDialog');
    },

    /**
     * Called when the account data has been refreshed and requires a repaint.
     *
     * @private
     */
    onAccountDataChanged: function() {
      this.setLoading(false);
      this.updateAccountListing(this._accountDataSource.get('data'));
      this._hasDoneInitialLoad = true;
      this.set('selectableObjects', null);
      this.trigger('loaded');
    },

    /**
     * Called when the account data fails to refresh.
     *
     * @private
     */
    onAccountDataError: function() {
      wesabe.error("Unable to load accounts! Oh no!");
    },

    /**
     * Update the listing of accounts only, not the update status.
     */
    updateAccountListing: function(data) {
      this.get('total').setMoney(data.total);
      this.get('accountGroupList').update(data['account-groups']);
    },

    /**
     * Called when the account upload status has changed.
     */
    onUploadStatusChanged: function() {
      this._updateButton.setVisible(this._credentialDataSource.hasCredentials());
      this.get('accountGroupList').updateUploadStatus(this._credentialDataSource);
      this._updateButtonSpinner.css('visibility', this.isUpdatingAccounts() ? 'visible' : 'hidden');
    },

    /**
     * Returns a boolean indicating whether any accounts are currently being
     * updated via the Automatic Uploader.
     */
    isUpdatingAccounts: function() {
      var groups = this.get('accountGroupList').get('items'),
          length = groups.length;

      while (length--)
        if (groups[length].isUpdatingAccounts()) return true;

      return false;
    },

    /**
     * Handles clicks for this {AccountWidget} and its descendants, delegating
     * to a child {AccountGroup} if necessary.
     */
    onClick: function(event) {
      var element = $(event.target),
          groupElement = element.parents('.group');

      if (groupElement.length) {
        var group = this.get('accountGroupList').getItemByElement(groupElement);
        if (group)
          group.onClick(event);
        return;
      }
    },

    /**
     * Called when the user chooses to start editing {account}.
     */
    onBeginEdit: function(account) {
      this.asyncGetAccountEditDialog(function(accountEditDialog) {
        accountEditDialog.onBeginEdit(account);
      });
    },

    /**
     * Called when the user clicks the Edit button.
     */
    onEditButtonClick: function() {
      this.setEditMode(true);
    },

    /**
     * Called when the user clicks the Done button.
     */
    onDoneButtonClick: function() {
      this.setEditMode(false);
    },

    /**
     * Returns a list of objects that may be selected in this {AccountWidget}.
     *
     * See {wesabe.views.pages.accounts#reloadState}.
     */
    selectableObjects: function() {
      if (!this._selectableObjects) {
        var groups = this.get('accountGroupList').get('items'),
            length = groups.length,
            objects = $.makeArray(groups);

        while (length--)
          objects = objects.concat(groups[length].get('items'));

        this._selectableObjects = objects;
      }

      return this._selectableObjects;
    }
  });
});

$(function() {
  wesabe.provide('views.widgets.accounts.__instance__',
    new wesabe.views.widgets.accounts.AccountWidget($('#accounts'),
      wesabe.data.accounts.sharedDataSource, wesabe.data.credentials.sharedDataSource)) });

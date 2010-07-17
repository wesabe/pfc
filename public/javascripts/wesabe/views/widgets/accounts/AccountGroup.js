/**
 * Wraps a <li class="group"> containing both the group name and balance
 * as well as the list of accounts. Instances are managed by an
 * {AccountGroupList} to which they delegate both selection and DOM event
 * handling.
 */
wesabe.$class('wesabe.views.widgets.accounts.AccountGroup', wesabe.views.widgets.BaseListWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.array
  var array = wesabe.lang.array;
  // import wesabe.data.preferences as prefs
  var prefs = wesabe.data.preferences;

  $.extend($class.prototype, {
    _template: null,
    _nameElement: null,
    _accountGroupList: null,
    _total: null,
    _name: null,
    _uri: null,
    _key: null,
    _expanded: false,
    _editMode: false,
    _wasExpanded: null,
    _items: null,

    init: function(element, accountGroupList) {
      $super.init.call(this, element);

      this._accountGroupList = accountGroupList;
      // extract the account template
      var template = element.children('ul').children('li.account.template');
      this._template = template.clone().removeClass('template');
      template.remove();

      // get name and total
      var header = element.children(':header');
      this._total = new wesabe.views.widgets.MoneyLabel(header.find('span.total'));
      this.registerChildWidget(this._total);
      this._nameElement = header.find('span.text-content');

      // get the account list element
      this.setListElement(element.children('ul'));
    },

    /**
     * Gets the name of the group (e.g. "Checking").
     */
    getName: function() {
      return this._name;
    },

    /**
     * Sets the name of this {AccountGroup} and updates the text, but does not
     * update the name on the server.
     */
    setName: function(name) {
      if (this._name === name)
        return;

      this._name = name;
      this._nameElement.text(name);
    },

    /**
     * Returns the short url-friendly name for this {AccountGroup} (e.g. "credit").
     *
     * @return {string}
     */
    getKey: function() {
      return this._key;
    },

    /**
     * Sets the short url-friendly name for this {AccountGroup}. This determines
     * which icon shows up next to the name.
     *
     * @param {!string} key
     */
    setKey: function(key) {
      if (this._key === key)
        return;

      if (this._key) this.getElement().removeClass(this._key);
      this._key = key;
      if (key) this.getElement().addClass(key);
    },

    /**
     * Gets the URI for this {AccountGroup} (e.g. "/account-groups/checking").
     *
     * See {wesabe.views.pages.accounts#storeState}.
     */
    getURI: function() {
      return this._uri;
    },

    /**
     * Gets the account with the given {uri}, returning null if it's not found.
     *
     * @param {!string} uri The unique identifier for the account to find.
     * @return {Account}
     */
    getAccountByURI: function(uri) {
      var items = this.getItems();

      for (var i = items.length; i--;) {
        var account = items[i];
        if (account.getURI() === uri) return account;
      }

      return null;
    },

    /**
     * Gets the URL parameters for this {AccountGroup}, which is the
     * collection of all the params of its children {Account} instances.
     *
     * See {wesabe.views.pages.accounts#paramsForCurrentSelection}.
     */
    toParams: function() {
      var params = [],
          accounts = this.getItems(),
          length = accounts.length;

      while (length--)
        params = params.concat(accounts[length].toParams());

      return params;
    },

    /**
     * Gets the currencies of all children {Account} instances.
     *
     * See {wesabe.views.pages.accounts#paramsForCurrentSelection}.
     */
    getCurrencies: function() {
      var items = this.getItems(),
          length = items.length,
          currencies = [];

      while (length--)
        currencies = currencies.concat(items[length].getCurrencies());

      return array.uniq(currencies);
    },

    /**
     * Returns the {wesabe.util.Selection} associated with this {AccountGroup}.
     */
    getSelection: function() {
      return this._accountGroupList.getSelection();
    },

    /**
     * Gets the {CredentialDataSource} used to populate this {AccountGroup}.
     */
    getCredentialDataSource: function() {
      return this._accountGroupList.getCredentialDataSource();
    },

    /**
     * Handle clicks on this {AccountGroup} and its descendants, delegating
     * to a child {Account} if necessary.
     *
     * NOTE: There is no accompanying bind statement because this widget uses
     * event delegation for the entire list of accounts,
     * see {AccountWidget#onClick}.
     */
    onClick: function(event) {
      event.preventDefault();

      var target = $(event.target);

      // did they click the expand/collapse button?
      if (target.hasClass('view')) {
        if (!this.getListElement().is(':animated')) {
          this.animateExpanded(!this.isExpanded());
          this._persistPreferences();
        }
        return;
      }

      // do we need to delegate to an account?
      var accountElement = target.parents('.account');
      if (accountElement.length) {
        var account = this.getItemByElement(accountElement);
        if (account)
          account.onClick(event);
        return;
      }

      // we got clicked somewhere that isn't a hotspot
      if (event.ctrlKey || event.metaKey) {
        this.getSelection().toggle(this);
      } else {
        this.getSelection().set(this);
        if (!this.isExpanded()) {
          this.animateExpanded(true);
          this._persistPreferences();
        }
      }
    },

    /**
     * Called by {wesabe.util.Selection} instances when this object
     * becomes part of the current selection.
     */
    onSelect: function() {
      if (this.getElement()) {
        this.getElement().addClass('on');
        if (this.getElement().hasClass('open'))
          this.getElement().addClass('open-on');
      }
    },

    /**
     * Called by {wesabe.util.Selection} instances when this object
     * ceases to be part of the current selection.
     */
    onDeselect: function() {
      if (this.getElement())
        this.getElement().removeClass('on').removeClass('open-on');
    },

    /**
     * Called when the user chooses to start editing {account}.
     */
    onBeginEdit: function(account) {
      if (this._accountGroupList)
        this._accountGroupList.onBeginEdit(account);
    },

    /**
     * Sets whether this {AccountGroup} is currently in edit mode
     * (forces expansion).
     */
    setEditMode: function(editMode) {
      if (this._editMode === editMode)
        return;

      this._editMode = editMode;
      if (editMode) {
        // entering edit mode, keep track of whether it was expanded
        this._wasExpanded = this._expanded;
        this.animateExpanded(true);
      } else {
        // leaving edit mode, collapse if it was previously collapsed
        if (this._wasExpanded === false)
          this.animateExpanded(false);
        this._wasExpanded = null;
      }

      var items = this.getItems(),
          length = items.length;

      while (length--)
        items[length].setEditMode(editMode);
    },

    /**
     * Returns a boolean indicating whether this {AccountGroup} is expanded.
     */
    isExpanded: function() {
      return this._expanded;
    },

    /**
     * Sets the expansion state of this {AccountGroup} immediately, as
     * opposed to the gradual animation provided by {#animateExpanded}.
     *
     * If the value of {expanded} is the same as the current expansion
     * state, this function has no effect.
     *
     * This does not update the user's preferences for this {AccountGroup}'s
     * expansion state.
     */
    setExpanded: function(expanded) {
      this.animateExpanded(expanded, 0);
    },

    /**
     * Sets the expansion state of this {AccountGroup} gradually using a
     * sliding animation, as opposed to the immediate expansion provided by
     * {#setExpanded}.
     *
     * If the value of {expanded} is the same as the current expansion
     * state, this function has no effect.
     *
     * This does not update the user's preferences for this {AccountGroup}'s
     * expansion state.
     */
    animateExpanded: function(expanded, speed) {
      var me = this;

      if (expanded === me.isExpanded())
        return;

      if (expanded) {
        me.getListElement().slideDown(speed, function() {
          me.getElement().addClass('open');
        });
      } else {
        me.getListElement().slideUp(speed, function() {
          me.getElement().removeClass('open');
        });
      }

      me._expanded = expanded;
    },

    /**
     * Updates the DOM for this {AccountGroup} with new data.
     */
    update: function(accountGroup) {
      this.setName(accountGroup.name);
      this._total.setMoney(accountGroup.total);
      this._uri = accountGroup.uri;
      this.setKey(accountGroup.key);

      var accounts = accountGroup.accounts,
          length = accounts.length,
          items = [];

      while (length--) {
        var accountDatum = accounts[length],
            item = this.getItemByURI(accountDatum.uri);

        if (!item) {
          item = new $package.Account(this._template.clone(), this);
          item.setEditMode(this._editMode);
        }

        items[length] = item;
        item.update(accountDatum);
      }

      this.setItems(items);
      if (!this._editMode)
        this._restorePreferences();
    },

    /**
     * Updates the upload statuses for the child {Account} items.
     */
    updateUploadStatus: function(credentialDataSource) {
      var items = this.getItems(),
          length = items.length;

      while (length--)
        items[length].setCredential(credentialDataSource.getCredentialDataByAccountURI(items[length].getURI()));
    },

    /**
     * Returns true if any of the accounts in this group are doing an SSU update, false otherwise.
     */
    isUpdatingAccounts: function() {
      var items = this.getItems(),
          length = items.length;

      while (length--)
        if (items[length].isUpdating())
          return true;

      return false;
    },

    /**
     * Store the current state of this {AccountGroup} with the
     * preferences service.
     *
     * @private
     */
    _persistPreferences: function() {
      prefs.update(this._fullPrefKey('expanded'), this.isExpanded());
    },

    /**
     * Reload the state of this {AccountGroup} from the preference service.
     *
     * @private
     */
    _restorePreferences: function() {
      this.setExpanded(prefs.get(this._fullPrefKey('expanded')));
    },

    _fullPrefKey: function(shortKey) {
      return 'accounts.groups.' + this._key + '.' + shortKey;
    }
  });
});

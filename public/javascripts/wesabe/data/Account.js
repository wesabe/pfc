/**
 * Represents an account.
 */
wesabe.$class('wesabe.data.Account', wesabe.data.Record, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _uri: null,
    _name: null,
    _lastBalanceAt: null,
    _currency: null,
    _archived: false,
    _type: null,
    _balance: null,

    getId: function() {
      return this.getURI();
    },

    setId: function(id) {
      this.setURI(id)
    },

    getURI: function() {
      return this._uri;
    },

    setURI: function(uri) {
      this._uri = uri;
      this.setDirty(true);
    },

    getName: function() {
      return this._name;
    },

    setName: function(name) {
      this._name = name;
      this.setDirty(true);
    },

    getLastBalanceAt: function() {
      return this._lastBalanceAt;
    },

    setLastBalanceAt: function(lastBalanceAt) {
      this._lastBalanceAt = lastBalanceAt;
      this.setDirty(true);
    },

    getCurrency: function(currency) {
      return this._currency;
    },

    setCurrency: function(currency) {
      this._currency = currency;
      this.setDirty(true);
    },

    getArchived: function(archived) {
      return this._archived;
    },

    setArchived: function(archived) {
      this._archived = archived;
      this.setDirty(true);
    },

    getType: function(type) {
      return this._type;
    },

    setType: function(type) {
      this._type = type;
      this.setDirty(true);
    },

    getBalance: function(balance) {
      return this._balance;
    },

    setBalance: function(balance) {
      this._balance = balance;
      this.setDirty(true);
    }
  });
});

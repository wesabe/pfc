/**
 * Represents a transaction.
 */
wesabe.$class('wesabe.data.Transaction', wesabe.data.Record, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _id: null,
    _uri: null,
    _date: null,
    _originalDate: null,
    _amount: null,
    _merchant: null,
    _checkNumber: null,
    _uneditedName: null,
    _note: null,
    _account: null,
    _tags: null,
    _transfer: null,

    getId: function() {
      return this._id;
    },

    setId: function(id) {
      this._id = id;
      this.setDirty();
    },

    getURI: function() {
      return this._uri;
    },

    setURI: function(uri) {
      this._uri = uri;
      this.setDirty();
    },

    getDate: function() {
      return this._date;
    },

    setDate: function(date) {
      this._date = date;
      this.setDirty();
    },

    getOriginalDate: function() {
      return this._originalDate;
    },

    setOriginalDate: function(originalDate) {
      this._originalDate = originalDate;
      this.setDirty();
    },

    getAmount: function() {
      return this._amount;
    },

    setAmount: function(amount) {
      this._amount = amount;
      this.setDirty();
    },

    getMerchant: function() {
      return this._merchant;
    },

    setMerchant: function(merchant) {
      this._merchant = merchant;
      this.setDirty();
    },

    getCheckNumber: function() {
      return this._checkNumber;
    },

    setCheckNumber: function(checkNumber) {
      this._checkNumber = checkNumber;
      this.setDirty();
    },

    getUneditedName: function() {
      return this._uneditedName;
    },

    setUneditedName: function(uneditedName) {
      this._uneditedName = uneditedName;
      this.setDirty();
    },

    getNote: function() {
      return this._note;
    },

    setNote: function(note) {
      this._note = note;
      this.setDirty();
    },

    getAccount: function() {
      return this._account;
    },

    setAccount: function(account) {
      this._account = account;
      this.setDirty();
    },

    getTags: function() {
      return this._tags;
    },

    setTags: function(tags) {
      this._tags = tags;
      this.setDirty();
    },

    getTransfer: function() {
      return this._transfer;
    },

    setTransfer: function(transfer) {
      this._transfer = transfer;
      this.setDirty();
    }
  });
});

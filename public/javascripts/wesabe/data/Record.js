/**
 * Base class for data records.
 */
wesabe.$class('wesabe.data.Record', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class, {
    INITIALIZED: 1 << 0,
    LOADING:     1 << 1,
    LOADED:      1 << 2,
    DIRTY:       1 << 3,
    PARTIAL:     1 << 4
  });

  $.extend($class.prototype, {
    _dataStore: null,
    _readyState: null,

    init: function(dataStore) {
      this._dataStore = dataStore;
      this._readyState = $package.Record.INITIALIZED;
    },

    refresh: function() {
      this._dataStore.refreshRecord(this);
    },

    /// State Management

    isLoaded: function() {
      return this._readyState & $package.Record.LOADED;
    },

    onLoad: function() {
      this._readyState = (this._readyState | $package.Record.LOADED) & ~$package.Record.LOADING & ~$package.Record.PARTIAL & ~$package.Record.DIRTY;
      this.trigger('change');
    },

    isLoading: function() {
      return this._readyState & $package.Record.LOADING;
    },

    onBeginLoading: function() {
      this._readyState = (this._readyState | $package.Record.LOADING) & ~$package.Record.LOADED;
      this.trigger('change');
    },

    isDirty: function() {
      return this._readyState & $package.Record.DIRTY;
    },

    setDirty: function(dirty) {
      this._readyState = dirty ? (this._readyState | $package.Record.DIRTY) : (this._readyState & ~$package.Record.DIRTY);
      this.trigger('change');
    },

    isPartiallyLoaded: function() {
      return this._readyState & $package.Record.PARTIAL;
    },

    setPartiallyLoaded: function(partiallyLoaded) {
      this._readyState = partiallyLoaded ? ((this._readyState | $package.Record.PARTIAL) & ~$package.Record.LOADED) : (this._readyState & ~$package.Record.PARTIAL);
      this.trigger('change');
    }
  });
});

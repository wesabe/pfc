/**
 * Represents the results of a +Query+.
 */
wesabe.$class('wesabe.data.ResultSet', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class, {
    INITIALIZED: 0,
    LOADING:     1,
    LOADED:      2,
    ERROR:       3
  });

  $.extend($class.prototype, {
    _count: 0,
    _records: null,
    _loadedIndexes: null,
    _readyState: null,
    _error: null,
    _dataStore: null,
    _dataSource: null,

    init: function(dataStore, query) {
      this._dataStore = dataStore;
      this._query = query;
      this._readyState = $class.INITIALIZED;
      this._records = [];
      this._loadedIndexes = new wesabe.lang.IndexSet();
    },

    refresh: function() {
      this._dataStore.refreshResultSet(this);
    },

    getDataStore: function() {
      return this._dataStore;
    },

    /**
     * @protected
     */
    setDataStore: function(dataStore) {
      this._dataStore = dataStore;
    },

    getQuery: function() {
      return this._query;
    },

    getDataSource: function() {
      return this._dataSource;
    },

    /**
     * @protected
     */
    setDataSource: function(dataSource) {
      this._dataSource = dataSource;
    },

    /// Record Accessors

    get: function(index) {
      if (index >= this._count)
        throw "index out of bounds ("+index+" not in 0..."+this._count+")";

      if (!this._loadedIndexes.contains(index))
        this._dataStore.executeQuery(this._query, this, index);

      return this._records[index];
    },

    /**
     * @protected
     */
    loadRecordsWithOffset: function(records, offset) {
      for (var i = 0, length = records.length; i < length; i++)
        this._records[i+offset] = records[i];

      this._loadedIndexes.addRange(offset, records.length);
      this.trigger('change');
    },

    getCount: function() {
      return this._count;
    },

    /**
     * @protected
     */
    setCount: function(count) {
      this._count = count;
      this.trigger('change');
    },

    /// State Management

    isLoaded: function() {
      return this._readyState == $class.LOADED;
    },

    onLoad: function() {
      this._readyState = $class.LOADED;
      this.trigger('change');
    },

    isLoading: function() {
      return this._readyState == $class.LOADING;
    },

    onBeginLoading: function() {
      this._readyState = $class.LOADING;
      this.trigger('change');
    },

    isError: function() {
      return this._readyState == $class.ERROR;
    },

    getError: function() {
      return this.isError() ? this._error : null;
    },

    setError: function(error) {
      this._readyState = $class.ERROR;
      this.trigger('change');
    }
  });
});

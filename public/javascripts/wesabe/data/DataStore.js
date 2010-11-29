/**
 * Manages access to records from data sources.
 */
wesabe.$class('wesabe.data.DataStore', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _cache: null,
    _queries: null,
    _dataSources: null,

    init: function(element) {
      this._cache       = {};
      this._queries     = {};
      this._dataSources = [];
    },

    /**
     * Registers a data source to be used when finding records via this store.
     */
    registerDataSource: function(dataSource) {
      this._dataSources.push(dataSource);
    },

    /**
     * Finds records of type +type+ with the given +options+.
     *
     * @param {!subclass of wesabe.data.Record} type
     * @param {Object} options
     * @return wesabe.data.ResultSet
     *
     * Or, just pass a +query+:
     *
     * @param {!wesabe.data.Query} query
     * @return wesabe.data.ResultSet
     */
    find: function(type, query) {
      if (type && type.isInstanceOf && type.isInstanceOf($package.Query))
        query = type, type = null;

      if (!query || !query.isInstanceOf || !query.isInstanceOf($package.Query))
        query = new $package.Query(type, query);

      var resultSet;

      if (resultSet = this.resultSetForQuery(query))
        return resultSet;

      var shouldRunQuery = true;
      resultSet = new $package.ResultSet(this, query),

      if (query.wantsSpecificRecords()) {
        var ids = query.getIds();

        // run the query if we didn't get all the records asked for
        shouldRunQuery = !this.addRecords(type, ids, resultSet);
      }

      if (shouldRunQuery)
        this.executeQuery(query, resultSet);

      return resultSet;
    },

    /**
     * Fetches a specific record.
     *
     * @param {!wesabe.data.Record} record
     * @return wesabe.data.ResultSet
     */
    refreshRecord: function(record) {
      var query = new $package.Query(record.getClass(), {id: record.getId()}),
          resultSet = new $package.ResultSet();

      resultSet.setRecords([record]);
      this.executeQuery(query, resultSet);

      return resultSet;
    },

    /**
     * Re-runs the query that generated +resultSet+.
     *
     * @param {!wesabe.data.ResultSet} resultSet
     * @return wesabe.data.ResultSet
     */
    refreshResultSet: function(resultSet) {
      this.executeQuery(resultSet.getQuery(), resultSet);
      return resultSet;
    },

    /**
     * @private
     */
    resultSetForQuery: function(query) {
      var resultSetAndQuery = this._queries[query.UID];
      return resultSetAndQuery && resultSetAndQuery.resultSet;
    },

    /**
     * @private
     */
    registerResultSetForQuery: function(query, resultSet) {
      this._queries[query.UID] = {query: query, resultSet: resultSet};
    },

    /**
     * Adds records of type +type+ with the given +ids+, if they can be found
     * in the cache, to +resultSet+. For records that cannot be found a
     * placeholder is inserted in its place.
     *
     * @private
     */
    addRecords: function(type, ids, resultSet) {
      var records = [], foundAll = true;

      for (var i = 0, length = ids.length; i < length; i++) {
        var record = this.getCachedRecord(type, ids[i]);

        if (!record) {
          foundAll = false;
          record = this.getOrCreateRecord(type, ids[i]);
          record.setId(ids[i]);
          record.setDirty(false);
          record.onBeginLoading();
        }

        records.push(record);
      }

      resultSet.loadRecordsWithOffset(records, 0);
      resultSet.setCount(ids.length);

      return foundAll;
    },

    /**
     * Finds a data source capable of handling +query+ and hands it off. If it
     * finds one, this returns +true+, otherwise it returns +false+.
     *
     * @private
     */
    executeQuery: function(query, resultSet, index) {
      this.registerResultSetForQuery(query, resultSet);
      index = index || 0;

      for (var i = 0, length = this._dataSources.length; i < length; i++) {
        var dataSource = this._dataSources[i];
        if (dataSource.fetchRecords(this, query, index)) {
          resultSet.setDataSource(dataSource);
          resultSet.onBeginLoading();
          return true;
        }
      }

      resultSet.setError();
      return false;
    },

    getOrCreateRecord: function(type, id) {
      var record = this.getCachedRecord(type, id);

      if (!record) {
        record = new type(this);

        if (id) {
          record.setId(id);
          this.cacheRecord(record);
        }
      }

      return record;
    },

    getCachedRecord: function(type, id) {
      return this._cache[this.getCacheKey(type, id)];
    },

    /**
     * @private
     */
    cacheRecord: function(record) {
      this._cache[this.getCacheKey(record.getClass(), record.getId())] = record;
    },

    /**
     * @private
     */
    getCacheKey: function(type, id) {
      return [type.__name__, id].join(':');
    },

    /**
     * Callback method for DataSources to notify us that they got new records.
     */
    dataSourceDidRetrieveRecordsForQuery: function(dataSource, query, records, index, count) {
      var resultSet = this.resultSetForQuery(query);

      if (!resultSet) {
        wesabe.warn("unable to find a record of this finished query:", query);
        return;
      }

      resultSet.loadRecordsWithOffset(records, index);
      resultSet.setCount(count || records.length);
    },

    /**
     * Callback method for DataSources to notify us that they failed to get new records.
     */
    dataSourceDidFailToRetrieveRecordsForQuery: function(dataSource, query, index, error) {
      wesabe.error("failed to execute query:", query, "; an error occurred:", error);

      var resultSet = this.resultSetForQuery(query);

      if (!resultSet) {
        wesabe.warn("unable to find a record of this errored query:", query);
        return;
      }

      resultSet.setError(error);
    }
  });
});

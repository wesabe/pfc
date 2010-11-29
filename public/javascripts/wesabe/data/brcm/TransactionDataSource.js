/**
 * Retrieves Transactions from BRCM for a DataStore.
 */
wesabe.$class('wesabe.data.brcm.TransactionDataSource', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.date
  var date = wesabe.lang.date;

  $.extend($class.prototype, {
    _defaultCurrency: null,
    _batchSize: null,

    init: function(defaultCurrency) {
      this._defaultCurrency = defaultCurrency;
    },

    getBatchSize: function() {
      return this._batchSize;
    },

    setBatchSize: function(batchSize) {
      this._batchSize = batchSize;
    },

    getDefaultCurrency: function() {
      return this._defaultCurrency;
    },

    setDefaultCurrency: function(defaultCurrency) {
      this._defaultCurrency = defaultCurrency;
    },

    fetchRecords: function(dataStore, query, index) {
      var me = this;

      if (query.getType() != wesabe.data.Transaction)
        return false;

      if (index && this._batchSize)
        index -= index % this._batchSize;

      $.ajax({
        type: 'GET',
        url: this.buildURL(query, index),
        data: this.buildParams(query, index),
        dataType: 'json',
        success: function(response) {
          var data = response.transactions,
              idFilter = null;

          if (!data)
            return [];

          // really, really naive implementation. DO NOT USE
          if (query.wantsSpecificRecords()) {
            idFilter = {};
            var ids = query.getIds();
            for (var i = 0, length = ids.length; i < length; i++)
              idFilter[ids[i]] = true;
          }

          var records = [];
          for (var i = 0, length = data.length; i < length; i++) {
            var datum = data[i], id = datum.id, record;
            if (!idFilter || idFilter[id]) {
              record = dataStore.getOrCreateRecord(query.getType(), id);
              me.updateRecordWithData(record, datum, query, dataStore);
              record.onLoad();
              records.push(record);
            }
          }

          dataStore.dataSourceDidRetrieveRecordsForQuery(me, query, records, index, response.count.total);
        },
        error: function(xhr, textStatus, errorThrown) {
          dataStore.dataSourceDidFailToRetrieveRecordsForQuery(me, query, index, textStatus);
        }
      });

      return true;
    },

    /**
     * @private
     */
    updateRecordWithData: function(record, data, query, dataStore) {
      record.setId(data.id);
      record.setURI(data.uri);
      record.setDate(date.parse(data.date));
      record.setOriginalDate(date.parse(data['original-date']));
      record.setAmount(data.amount);
      record.setMerchant(data.merchant);
      record.setCheckNumber(data['check-number']);
      record.setUneditedName(data['unedited-name']);
      record.setNote(data.note);

      var account = dataStore.getOrCreateRecord(wesabe.data.Account, data.account.uri)
      record.setAccount(account);

      if (query.shouldFetchAssociation('account') && !account.isLoaded())
        account.refresh();

      // make these use models
      record.setTags(data.tags);
      record.setTransfer(data.transfer);
    },

    /**
     * @private
     */
    buildURL: function(query, index) {
      return '/data/transactions/'+this._defaultCurrency;
    },

    /**
     * @private
     */
    buildParams: function(query, index) {
      if (this._batchSize && !query.wantsSpecificRecords())
        return {offset: index || 0, limit: this._batchSize};

      return {};
    }
  });
});

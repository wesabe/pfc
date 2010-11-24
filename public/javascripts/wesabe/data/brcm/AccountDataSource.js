/**
 * Retrieves Accounts from BRCM for a DataStore.
 */
wesabe.$class('wesabe.data.brcm.AccountDataSource', null, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.date
  var date = wesabe.lang.date;

  $.extend($class.prototype, {
    _defaultCurrency: null,

    init: function(defaultCurrency) {
      this._defaultCurrency = defaultCurrency;
    },

    getDefaultCurrency: function() {
      return this._defaultCurrency;
    },

    setDefaultCurrency: function(defaultCurrency) {
      this._defaultCurrency = defaultCurrency;
    },

    fetchRecords: function(dataStore, query) {
      var me = this;

      if (query.getType() != wesabe.data.Account)
        return false;

      $.ajax({
        type: 'GET',
        url: this.buildURL(query),
        dataType: 'json',
        success: function(response) {
          var data = response.accounts,
              groups   = response['account-groups'],
              idFilter = null;

          if (!data)
            return [];

          if (query.wantsSpecificRecords()) {
            idFilter = {};
            var ids = query.getIds();
            for (var i = 0, length = ids.length; i < length; i++)
              idFilter[ids[i]] = true;
          }

          var records = [];
          for (var i = 0, length = data.length; i < length; i++) {
            var datum = data[i], id = datum.uri, record;

            if (!idFilter || idFilter[id]) {
              record = dataStore.getOrCreateRecord(query.getType(), id);
              me.updateRecordWithData(record, datum);
              record.onLoad();
              records.push(record)
            }
          }

          dataStore.dataSourceDidRetrieveRecordsForQuery(me, query, records);
        },
        error: function(xhr, textStatus, errorThrown) {
          dataStore.dataSourceDidFailToRetrieveRecordsForQuery(me, query, textStatus);
        }
      });

      return true;
    },

    /**
     * @private
     */
    updateRecordWithData: function(record, data) {
      record.setURI(data.uri);
      record.setName(data.name);
      record.setLastBalanceAt(date.parse(data['last-balance-at']));
      record.setCurrency(data.currency);
      record.setArchived(data.status == 'archived');
      record.setType(data.type);
      record.setBalance(data.balance);
    },

    /**
     * @private
     */
    buildURL: function(query) {
      return '/data/accounts/all/'+this._defaultCurrency;
    }
  });
});

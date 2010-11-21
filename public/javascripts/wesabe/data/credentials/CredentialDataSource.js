/**
 * Provides access to user credentials and sync status.
 */
wesabe.$class('wesabe.data.credentials.CredentialDataSource', wesabe.data.BaseDataSource.dataSourceWithURI('/credentials'), function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.array
  var array = wesabe.lang.array;
  // import wesabe.lang.number
  var number = wesabe.lang.number;

  $.extend($class.prototype, {
    _syncDonePoller: null,

    /**
     * Returns credential data for the account with URI {accountUri}, or null if
     * no such credential can be found.
     */
    getCredentialDataByAccountURI: function(accountUri) {
      if (!this.hasData())
        return null;

      var credentials = this.getData(),
          length = credentials.length;

      while (length--)
        if (array.contains(credentials[length].accounts, accountUri))
          return credentials[length];

      return null;
    },

    /**
     * Destroys the credential at the given +uri+. If +uri+ is a credential
     * structure, the uri will be determined for you.
     *
     * @param {!String|Object} uri
     */
    destroy: function(uri) {
      if (uri && uri.uri)
        uri = uri.uri;

      if (!uri)
        return;

      var me = this;
      $.ajax({
        type: 'DELETE',
        url: uri,
        success: function(){ me.onDestroy(uri); },
        error: function(xhr, textStatus, errorThrown){ me.onDestroyFailed(uri, xhr, textStatus, errorThrown); }
      });
    },

    onDestroy: function(uri) {
      if (this.isCachingEnabled()) {
        // remove from the cache
        for (var k in this._cache) {
          var cache = this._cache[k], result = [];

          for (var i = 0, length = cache.length; i < length; i++)
            if (cache[i].uri != uri)
              result.push(cache[i]);

          this._cache[k] = result;
        }
      }

      this.trigger('destroy', [uri]);

      if (this.isCachingEnabled()) {
        var data = this.getCache({});
        if (data)
          this.trigger('change', [data]);
      }
    },

    onDestroyFailed: function(uri, xhr, textStatus, errorThrown) {
      this.trigger('destroy-failed', [uri, xhr, textStatus, errorThrown]);
    },

    /**
     * Returns true if there are any credentials still pending, false otherwise.
     */
    isUpdating: function() {
      var data = this.getData();

      if (!data)
        return false;

      for (var i = data.length; i--;) {
        var job = data[i].last_job;
        if (job && job.status === 'pending')
          return true;
      }

      return false;
    },

    /**
     * Returns whether or not there are any credentials in this data source.
     *
     * @return {boolean}
     */
    hasCredentials: function() {
      if (!this.hasData())
        return false;
      else if (this.getData().length > 0)
        return true;
      else
        return false;
    },

    /**
     * Begin polling for credentials every {duration} milliseconds until there
     * are no more running sync jobs.
     */
    pollUntilSyncDone: function(duration) {
      var me = this;

      if (!duration)
        duration = 6000 /* ms */;

      // start the sync done poller if it isn't started yet
      if (!me._syncDonePoller)
        me._syncDonePoller = me.startPoller(duration, function() {
          if (!me.isUpdating()) {
            me.stopPoller(me._syncDonePoller);
            me._syncDonePoller = null;
          }
        });

      return me._syncDonePoller;
    }
  });
  $package.sharedDataSource = new $class();
});

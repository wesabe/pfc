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

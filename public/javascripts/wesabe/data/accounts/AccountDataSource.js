/**
 * Provides access to user accounts.
 */
wesabe.$class('wesabe.data.accounts.AccountDataSource', wesabe.data.BaseDataSource, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.data.preferences as prefs
  var prefs = wesabe.data.preferences;

  $.extend($class.prototype, {
    /**
     * Gets the default set of options to pass to {jQuery.ajax}.
     */
    getRequestOptions: function() {
      return $.extend($super.getRequestOptions.apply(this, arguments), {
        url: '/data/accounts/all/' + prefs.getDefaultCurrency(),
        data: {include_archived: true},
        cache: false
      });
    },

    /**
     * Sets the data for this {AccountDataSource}.
     */
    setData: function(data) {
      if (data) {
        var accounts = data.accounts,
            groups = data['account-groups'],
            accountLookup = {};

        for (var i = accounts.length; i--;)
          accountLookup[accounts[i].uri] = accounts[i];

        for (var i = groups.length; i--;) {
          var group = groups[i],
              groupAccounts = groups[i].accounts;
          group.key = group.uri.replace(/^.*\//, '');
          for (var j = groupAccounts.length; j--;)
            groupAccounts[j] = accountLookup[groupAccounts[j].uri];
        }
      }

      $super.setData.call(this, data);
    },

    /**
     * Returns account data for the account with URI {uri}, or null if
     * no such account can be found.
     */
    getAccountDataByURI: function(uri) {
      if (!this.hasData())
        return null;

      var accounts = this.getData().accounts,
          length = accounts.length;

      while (length--)
        if (accounts[length].uri === uri)
          return accounts[length];

      return null;
    }
  });
  $package.sharedDataSource = new $class();
});

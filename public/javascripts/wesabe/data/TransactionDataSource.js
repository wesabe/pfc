wesabe.$class('wesabe.data.TransactionDataSource', wesabe.data.BaseDataSource, function($class, $super) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang as lang
  var lang = wesabe.lang;
  // import wesabe.data.preferences as prefs
  var prefs = wesabe.data.preferences;

  $.extend($class.prototype, {
    _params: null,

    init: function(params) {
      if (params)
        this.setParams(params);
    },

    /**
     * Returns the URI to use to retrieve transactions.
     *
     * @return {string}
     * @override
     */
    getSourceURI: function() {
      // REVIEW: I'm sure this is not the right way to do this, but it works
      var accountSelections = page.selection.getByClass(wesabe.views.widgets.accounts.Account);
      if (accountSelections[0] && accountSelections[0].isInvestment()) // main selection needs to be investment account
        return '/data/investment-transactions/'+this._getCurrency();
      else
        return '/data/transactions/'+this._getCurrency();
    },

    /**
     * Returns the XHR options to pass to {jQuery.ajax}.
     *
     * @return {jQuery.ajax.data}
     * @override
     */
    getRequestOptions: function() {
      return $.extend($super.getRequestOptions.call(this), {
        data: this.getRequestQueryParams()
      });
    },

    /**
     * Returns the currency to be used in a transaction request.
     *
     * @private
     */
    _getCurrency: function() {
      return this._params && this._params.currency || prefs.getDefaultCurrency();
    },

    /**
     * Get the parameters to be used to make a request for transactions.
     *
     * @return {jQuery.ajax.data}
     */
    getParams: function() {
      return this._params && lang.params.copy(this._params);
    },

    /**
     * Sets the parameters to be used to make a request for transactions.
     *
     * @param {jQuery.ajax.data} params A jQuery-compatible data object.
     */
    setParams: function(params) {
      this._params = params;
    },

    /**
     * Gets a jQuery-compatible data object to use for requesting transactions.
     *
     * @return {jQuery.ajax.data}
     */
    getRequestQueryParams: function() {
      return this.getParams();
    },

    /**
     * Returns the page number derived from the offset/limit params.
     *
     * @private
     */
    _getPageNumber: function() {
      return Math.floor(lang.params.get(this._params, 'offset') / lang.params.get(this._params, 'limit')) + 1;
    },

    /**
     * Determines whether the params in this data source would be a search.
     *
     * @return {boolean}
     */
    isSearch: function() {
      return this._params && lang.params.has(this._params, 'query');
    }
  });
});

/**
 * Retrieves transaction summary information.
 */
wesabe.$class('wesabe.data.TransactionSummaryDataSource', wesabe.data.TransactionDataSource, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.date
  var date = wesabe.lang.date;

  $.extend($class.prototype, {
    type: null,
    startDate: null,
    endDate: null,

    sourceURI: function() {
      return '/data/analytics/summaries/'+this.get('type')+'/'+date.toParam(this.get('startDate'))+'/'+date.toParam(this.get('endDate'))+'/'+this.get('currency');
    },

    setParams: function(params) {
      params = wesabe.lang.params.copy(params);

      this.set('startDate', wesabe.lang.params.get(params, 'start'));
      this.set('endDate', wesabe.lang.params.get(params, 'end'));
      wesabe.lang.params.remove(params, 'start');
      wesabe.lang.params.remove(params, 'end');

      $super.setParams.call(this, params);
    }
  });
});

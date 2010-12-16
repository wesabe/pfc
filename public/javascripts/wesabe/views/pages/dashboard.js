wesabe.$class('views.pages.DashboardPage', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    init: function() {
      wesabe.views.shared
        .setCurrentTab("dashboard")
        .setPageTitle("Dashboard")
        .enableDefaultAccountsSearch()
        .enableDefaultAccountSidebarBehavior();

      var targetDataSource = new wesabe.data.TargetDataSource();
      targetDataSource.set('cachingEnabled', true);
      this._targets = new wesabe.views.widgets.targets.TargetWidget($("#spending-targets"), targetDataSource);

      var width = 630,
          height = 185;

      var sveController = new wesabe.controllers.SvEChartController(),
          sveContainer = new wesabe.views.widgets.Module($('#chart-sve')),
          sve = new wesabe.views.widgets.SeriesChart(sveContainer.get('contentElement').find('.canvas-container')),
          dataSource = new wesabe.data.TransactionSummaryDataSource();

      var sveHeader = sveContainer.get('headerElement'),
          intervalButtons = sveController.get('intervalButtons').get('buttons');

      for (var i = 0; i < intervalButtons.length; i++)
        sveHeader.prepend(intervalButtons[i].get('element'));

      sve.set('width', width);
      sve.set('height', height);

      sveController.set('chart', sve);
      sveController.set('dataSource', dataSource);

      sveController.reload();
    }
  });
});

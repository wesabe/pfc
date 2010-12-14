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
          sveContainer = $('<div></div>').width(width).height(height).css('background-color', 'white'),
          sve = new wesabe.views.widgets.SeriesChart(sveContainer),
          dataSource = new wesabe.data.TransactionSummaryDataSource();

      sveContainer.css({top: 0, left: 0, position: 'absolute', zIndex: 1000});
      sveContainer.appendTo(document.body);
      sve.set('width', width);
      sve.set('height', height);

      sveController.set('chart', sve);
      sveController.set('dataSource', dataSource);

      sveController.reload();
    }
  });
});

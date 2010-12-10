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
    }
  });
});

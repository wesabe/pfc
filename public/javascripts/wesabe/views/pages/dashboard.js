wesabe.provide('views.pages.dashboard', function() {
  wesabe.views.shared
    .setCurrentTab("dashboard")
    .setPageTitle("Dashboard")
    .enableDefaultAccountsSearch()
    .enableDefaultAccountSidebarBehavior();

  var me = this;
  $(function() {
    var targetDataSource = new wesabe.data.TargetDataSource();
    targetDataSource.setCachingEnabled(true);
    me.targets = new wesabe.views.widgets.targets.TargetWidget($("#spending-targets"), targetDataSource);
  });
});

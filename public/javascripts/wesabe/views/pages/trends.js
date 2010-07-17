wesabe.provide('views.pages.trends', function() {
  wesabe.views.shared
    .setCurrentTab("trends")
    .setPageTitle("Trends")
    .enableDefaultAccountsSearch()
    .enableDefaultAccountSidebarBehavior()
    .enableDefaultTagSidebarBehavior();
});

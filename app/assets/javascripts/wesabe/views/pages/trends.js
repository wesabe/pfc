/*
 *= require wesabe/data/credentials/CredentialDataSource.js
 *= require wesabe/views/pages/trends.js
 *= require wesabe/views/widgets/MoneyLabel.js
 *= require wesabe/views/widgets/accounts/AccountWidget.js
 *= require wesabe/views/widgets/accounts/AccountGroupList.js
 *= require wesabe/views/widgets/accounts/AccountGroup.js
 *= require wesabe/views/widgets/accounts/Account.js
 *= require wesabe/views/widgets/accounts/Merchant.js
 *= require wesabe/views/widgets/accounts/AutomaticUploaderErrorDialog.js
 *= require wesabe/views/widgets/accounts/ManualUploadDialog.js
 *= require wesabe/views/widgets/spending-summary.js
 *= require_tree ../widgets/tags
 *= require wesabe/views/widgets/tags.js
 *= require wesabe/date-range-picker.js
*/

wesabe.provide('views.pages.trends', function() {
  wesabe.views.shared
    .setCurrentTab("trends")
    .setPageTitle("Trends")
    .enableDefaultAccountsSearch()
    .enableDefaultAccountSidebarBehavior()
    .enableDefaultTagSidebarBehavior();
});

(function() {
  var $package = wesabe.views.widgets.accounts;
  var mocks = wesabe.mocks;

  describe("wesabe.views.widgets.accounts.AccountGroupList", {
    before: function() {
      element = $('<ul><li class="group template"></li></ul>');
      widget = new Object();
      credentialDataSource = new mocks.CredentialDataSourceMock();
      widget.getCredentialDataSource = function(){ return credentialDataSource };
      accountGroupList = new $package.AccountGroupList(element, widget);
      accountGroupData = [{
        uri: '/account-groups/cash',
        key: 'cash',
        name: 'Cash',
        accounts: [{
          uri: '/accounts/1',
          name: 'Cash',
          currency: 'USD',
          position: 0,
          status: 'active',
          type: 'Cash'
        }]
      },
      {
        uri: '/account-groups/credit',
        key: 'credit',
        name: 'Credit',
        accounts: [{
          uri: '/accounts/2',
          name: 'Amex Blue',
          currency: 'USD',
          position: 1,
          status: 'active',
          type: 'Credit'
        },
        {
          uri: '/accounts/3',
          name: 'Discover',
          currency: 'USD',
          position: 2,
          status: 'active',
          type: 'Credit'
        }]
      },
      {
        uri: '/account-groups/checking',
        key: 'checking',
        name: 'Checking',
        accounts: [{
          uri: '/accounts/4',
          name: 'Chase Checking',
          currency: 'USD',
          position: 3,
          status: 'active',
          type: 'Checking'
        },
        {
          uri: '/accounts/5',
          name: 'Euro Checking',
          currency: 'EUR',
          position: 4,
          status: 'active',
          type: 'Checking'
        }]
      }];
    },

    "knows its object type": function() {
      expect(accountGroupList.getClass()).to(be, $package.AccountGroupList);
    },

    "updates an empty list by creating an AccountGroup for each group datum": function() {
      expect(accountGroupList.getItems()).to(be_empty);
      accountGroupList.update(accountGroupData);
      expect(accountGroupList.getItems().length).to(equal, accountGroupData.length);
      accountGroup = accountGroupList.getItems()[0];

      expect(accountGroup.get('uri')).to(equal, accountGroupData[0].uri);
      expect(accountGroup.get('name')).to(equal, accountGroupData[0].name);
      expect(accountGroup.get('element')).to(match_selector, 'li.group');
    },

    "can get an AccountGroup given a valid child element": function() {
      accountGroupList.update(accountGroupData);
      expect(accountGroupList.getItemByElement(element.find('li.group:nth(2)'))).to(be, accountGroupList.getItems()[2]);
    },

    "gets null when looking for an AccountGroup by an invalid child element": function() {
      accountGroupList.update(accountGroupData);
      expect(accountGroupList.getItemByElement($('<li></li>'))).to(be_null);
    },

    "does not remove the existing groups when updated with the same groups": function() {
      // update the list with the data
      accountGroupList.update(accountGroupData);

      // mock out AccountGroup#remove
      accountGroupList.getItems()[0].remove = function() {
        fail("expected AccountGroup#remove not to be called when updating");
      };

      // update the list with the same data as before
      accountGroupList.update(accountGroupData);
    },

    "removes existing groups that are not in the updated list": function() {
      var removeCount = 0;

      accountGroupList.update(accountGroupData);

      var items = accountGroupList.getItems(),
          length = items.length;

      // mock out AccountGroup#remove
      while (length--)
        items[length].remove = function(){ removeCount++ };

      // refresh with the 2nd group removed
      accountGroupData.splice(1, 1);
      accountGroupList.update(accountGroupData);

      // we only removed the first group
      expect(removeCount).to(be, 1);

      // make sure the other groups are intact
      expect(accountGroupList.getItems().length).to(be, 2);
      expect(accountGroupList.getItems()[0].getURI()).to(be, "/account-groups/cash");
      expect(accountGroupList.getItems()[1].getURI()).to(be, "/account-groups/checking");
    }
  });
})();

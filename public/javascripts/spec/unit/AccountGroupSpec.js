(function() {
  var $package = wesabe.views.widgets.accounts;
  var mocks = wesabe.mocks;

  describe("wesabe.views.widgets.accounts.AccountGroup", {
    before: function() {
      accountGroupData = {
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
      };

      element = $('<li class="group"><ul><li class="account template"></li></ul></li>');
      accountGroupList = new Object();
      credentialDataSource = new mocks.CredentialDataSourceMock();
      accountGroupList.getCredentialDataSource = function(){ return credentialDataSource };
      accountGroup = new $package.AccountGroup(element, accountGroupList);
    },

    "knows its object type": function() {
      expect(accountGroup.getClass()).to(be, $package.AccountGroup);
    },

    "converts itself to url parameters by getting all the parameters for the contained accounts": function() {
      accountGroup.update(accountGroupData);

      expect(accountGroup.toParams()).to(
        contain_the_same_elements_as_with_matcher(function(a, b) {
          return (a.name === b.name) && (a.value === b.value);
        }),
        [
          {name: 'account', value: '/accounts/2'},
          {name: 'account', value: '/accounts/3'}
        ]
      );
    },

    "gets a unique list of currencies for its contained accounts": function() {
      accountGroup.update(accountGroupData);
      expect(accountGroup.getCurrencies()).to(equal, ["USD"]);
    },

    "toggles the class 'on' when selecting/deselecting": function() {
      accountGroup.onSelect();
      expect(element).to(match_selector, '.on');
      accountGroup.onDeselect();
      expect(element).to(match_selector, ':not(.on)');
    },

    "defaults to not expanded": function() {
      expect(accountGroup.isExpanded()).to(be_false);
    },

    "toggles the class 'open' when expanding/collapsing": function() {
      accountGroup.setExpanded(true);
      expect(element).to(match_selector, '.open');
      expect(accountGroup.isExpanded()).to(be_true);

      accountGroup.setExpanded(false);
      expect(element).to(match_selector, ':not(.open)');
      expect(accountGroup.isExpanded()).to(be_false);
    },

    "can get an Account given a valid child element": function() {
      accountGroup.update(accountGroupData);
      expect(accountGroup.getItemByElement(element.find('li.account:first'))).to(be, accountGroup.getItems()[0]);
    },

    "gets null when looking for an Account by an invalid child element": function() {
      accountGroup.update(accountGroupData);
      expect(accountGroup.getItemByElement($('<li></li>'))).to(be_null);
    },

    "does not remove the existing accounts when updated with the same accounts": function() {
      // update the list with the data
      accountGroup.update(accountGroupData);

      // mock out AccountGroup#remove
      accountGroup.getItems()[0].remove = function() {
        fail("expected Account#remove not to be called when updating");
      };

      // update the list with the same data as before
      accountGroup.update(accountGroupData);
    },

    "adds the new key as a class": function() {
      accountGroup.setKey('credit');
      expect(element).to(match_selector, '.credit');
    },

    "removes the old key from the class": function() {
      accountGroup.setKey('credit');
      accountGroup.setKey('cash');
      expect(element).to(match_selector, '.cash:not(.credit)');
    }
  });
})();

(function() {
  var array = wesabe.lang.array;
  var number = wesabe.lang.number;
  var date = wesabe.lang.date;
  var shared = wesabe.views.shared;
  var preferences = wesabe.data.preferences;

  var TRANSACTIONS_PER_PAGE = 30;

  wesabe.provide('views.pages.accounts', function() {
    this.init();
  });

  wesabe.views.pages.accounts.prototype = {
    // Contains the current selection for the page.
    // @type wesabe.util.Selection
    selection: null,

    // The current search term in use, if any.
    search: null,

    // References the #accounts node wrapped in a jQuery object.
    accounts: null,

    // References the #account-transactions node wrapped in a jQuery object.
    transactions: null,

    // References the #tags node wrapped in a jQuery object.
    tags: null,

    // essentially, what page of transactions are we on?
    offset: null,
    limit: TRANSACTIONS_PER_PAGE,

    // what date range should we be showing transactions in?
    start: null,
    end: null,

    // are we showing only unedited transactions?
    unedited: false,

    // have the various page components been loaded yet?
    _hasLoadedAccounts: false,
    _hasLoadedTags: false,
    _hasLoadedTransactions: false,

    init: function() {
      var self = this;

      shared
        .setPageTitle('My Accounts')
        .setCurrentTab('accounts');

      // create a shared selection for this page
      self.selection = new wesabe.util.Selection();
      self.selection.bind('changed', function(event, newsel, oldsel) {
        self.onSelectionChanged();
      });

      $.address.change(function() {
        self.attemptToReloadState();
      });

      // load all accounts view
      $('#accounts .module-header :header a, #nav-accounts > a')
        .click(function(event) {
          self.selection.clear();
          $.address.value('/accounts');
          return false;
        });

      wesabe.ready('wesabe.views.widgets.accounts.__instance__', function() {
        self.setUpAccountsWidget();
      });

      wesabe.ready('wesabe.views.widgets.account-transactions', function() {
        self.setUpTransactionWidget();
      });

      wesabe.ready('wesabe.views.widgets.tags.__instance__', function() {
        self.setUpTagsWidget();
      });

      shared.addSearchListener(function(query) {
        self.onSearch(query);
      });

      $(function(){ self.attemptToReloadState() });
    },

    onSearch: function(query) {
      this.search = query;
      this.storeState();
    },

    setUpAccountsWidget: function() {
      var self = this;

      self.accounts = wesabe.views.widgets.accounts.__instance__;
      // use the shared selection for the accounts widget's selection
      self.accounts.setSelection(self.selection);
      // wait until the accounts have loaded to try to restore selection
      function loaded() {
        self.accounts.unbind('loaded', loaded);
        self._hasLoadedAccounts = true;
        self.attemptToReloadState();
      }

      self.accounts
        .bind('loaded', loaded)
        .bind('account-updated', function() {
          // setTimeout(..., 0) cargo-culted from GWT -- I think it's like Thread.pass,
          // and won't block other callbacks to the account-updated event
          setTimeout(function() {
            self.refresh();
          }, 0);
        });

      if (self.accounts.hasDoneInitialLoad()) loaded();
    },

    setUpTransactionWidget: function() {
      var self = this;

      self.transactions = $('#account-transactions');
      // use the shared selection for the transaction widget's selection
      self.transactions.fn('selection', self.selection);
      // set the default offset/limit
      self.transactions.fn('offset', 0);
      self.transactions.fn('limit', TRANSACTIONS_PER_PAGE);
      // try to restore the selection in case this is the last widget loaded
      self._hasLoadedTransactions = true;
      self.attemptToReloadState();

      self.transactions
        // when a transaction is added/saved, reload the list, chart, accounts, and tags
        .bind('transaction-changed', function() {
          self.refreshTransactions();
          self.redrawChart();
          wesabe.data.accounts.sharedDataSource.requestData();
          wesabe.data.tags.sharedDataSource.requestData();
        })
        // toggle between All / Unedited
        .kvobserve('unedited', function(_, unedited) {
          if (self.unedited !== unedited) {
            self.unedited = unedited;
            self.storeState();
            self.reload();
          }
        })
        // handle clicking Earlier / Later buttons
        .kvobserve('offset', function(_, offset) {
          if (self.offset !== offset) {
            self.offset = offset;
            self.storeState();
            self.reload();
          }
        })
        // if the limit changes just refresh the data with the new value
        .kvobserve('limit', function(_, limit) {
          if (self.limit !== limit) {
            self.limit = limit;
            self.refresh();
          }
        });

      self.transactions.fn('transactionDataSource').subscribe({
        change: function(data) {
          self.transactions.fn('transactions', data);
        }
      });
    },

    // refreshing just means repopulating the list with new data
    refreshTransactions: function() {
      var ds = this.transactions.fn('transactionDataSource');
      ds.setParams(this.paramsForCurrentSelection());
      ds.requestData();
    },

    // reloading means hiding the list while refreshing
    reloadTransactions: function() {
      this.transactions.fn('loading', true);
      this.refreshTransactions();
    },

    setUpTagsWidget: function() {
      var self = this;

      function loaded() {
        self.tags.unbind('loaded', loaded);
        self._hasLoadedTags = true;
        self.attemptToReloadState();
      }

      self.tags = wesabe.views.widgets.tags.__instance__;
      // use the shared selection for the tags widget's selection
      self.tags.setSelection(self.selection);
      // wait until the tags have loaded to try to restore selection
      self.tags.bind('loaded', loaded);

      if (self.tags.hasDoneInitialLoad()) loaded();
    },

    attemptToReloadState: function(state) {
      if (this._hasLoadedAccounts && this._hasLoadedTransactions && this._hasLoadedTags) {
        this.reloadState(state);
      }
    },

    reloadState: function(state) {
      var state = state || shared.parseState(),
          path = state.path,
          params = state.params,

          selectableObjects,
          selectableObjectsByURI,

          selectedObjects = [],
          m = null,

          search = null,
          unedited = false,
          offset = null,
          start = null,
          end = null,

          length;

      selectableObjects = this.accounts.getSelectableObjects();
      selectableObjects = selectableObjects.concat(this.tags.getSelectableObjects());
      length = selectableObjects.length;

      while (length--)
        selectableObjects[selectableObjects[length].getURI()] = selectableObjects[length];

      for (var key in params) {
        if (!params.hasOwnProperty(key)) return;

        var value = params[key];
        switch (key) {
          case 'selection':
            for (var i = 0; i < value.length; i++) {
              var selectableObject = selectableObjects[value[i]];
              if (selectableObject)
                selectedObjects.push(selectableObject);
            }
            break;

          case 'unedited':
            unedited = (value == true) || (value == 'true');
            break;

          case 'q':
            search = value;
            break;

          case 'offset':
            offset = number.parse(value);
            break;

          case 'limit':
            limit = number.parse(value);
            break;

          case 'start':
            start = date.parse(value);
            break;

          case 'end':
            end = date.parse(value);
            break;
        }
      }

      if (this.unedited != unedited) {
        this.unedited = unedited;
        this.transactions.fn('unedited', unedited);
      }

      if (selectableObjects[path])
        selectedObjects.push(selectableObjects[path]);
      else if (m = path.match(/^\/merchants\/([^\/]+)$/))
        selectedObjects.push(new wesabe.views.widgets.accounts.Merchant(m[1]));

      this.selection.set(selectedObjects);

      if (!offset)
        offset = 0;

      this.offset = offset;
      this.transactions.fn('offset', offset);

      // restore the date range
      this.start = start;
      this.end = end;

      // restore the search term
      this.search = search;

      this.repaint();
      this.reload();
    },

    onSelectionChanged: function() {
      this.storeState();
    },

    reload: function() {
      this.redrawChart();
      this.reloadTransactions();
    },

    refresh: function() {
      this.repaint();
      this.redrawChart();
      this.refreshTransactions();
    },

    repaint: function() {
      var tags = [], accounts = [], groups = [], merchants = [],
          items = this.selection.get(), length = items.length;

      while (length--) {
        var item = items[length];
        if (item.isInstanceOf(wesabe.views.widgets.tags.TagListItem)) {
          tags.push(item);
        } else if (item.isInstanceOf(wesabe.views.widgets.accounts.Account)) {
          accounts.push(item);
        } else if (item.isInstanceOf(wesabe.views.widgets.accounts.AccountGroup)) {
          groups.push(item);
        } else if (item.isInstanceOf(wesabe.views.widgets.accounts.Merchant)) {
          merchants.push(item);
        }
      }

      shared.setSearch(this.search || '');
      this.setTitleForState(accounts, groups, tags, merchants, this.search);
      this.setAddTransactionAvailabilityForState(accounts, groups, tags, merchants, this.search);
    },

    storeState: function() {
      var path = '/accounts',
          params = {},
          selection = this.selection.get();

      // handle the selection
      if (selection.length == 1) {
        path = selection[0].getURI();
      } else if (selection.length > 1) {
        params.selection = [];
        for (var i = 0; i < selection.length; i++) {
          params.selection.push(selection[i].getURI());
        }
      }

      if (this.search) {
        path = '/accounts/search';
        params.q = this.search;
      }

      // handle the unedited flag
      if (this.unedited)
        params.unedited = true;

      if (this.offset)
        params.offset = this.offset;

      if (this.start)
        params.start = date.toParam(this.start);

      if (this.end)
        params.end = date.toParam(this.end);

      var state = {path: path, params: params};
      // create the history entry
      shared.pushState(state);

      return state;
    },

    setTitleForState: function(accounts, groups, tags, merchants, search) {
      var title = null, subtitle = null;
      var quote = function(item) {
        if (typeof item != 'string') item = item.getName();
        return '“'+item+'”'
      };

      if (search) {
        title = quote(search);
        subtitle = 'Search Results';
      } else if (accounts.length + groups.length + tags.length + merchants.length == 0) {
        title = 'All';
        subtitle = 'Accounts';
      } else {
        var tagsDisplay = [], merchantsDisplay = [], accountsDisplay = [], title, subtitle;

        if (tags.length) {
          if (tags.length > 3) {
            tagsDisplay.push(tags.length + ' Tags');
            tagsDisplay.push('Summary');
          } else {
            tagsDisplay.push($.map(tags, quote).join(' + '));
            tagsDisplay.push('Tag Summary');
          }
        }

        if (merchants.length) {
          if (merchants.length > 3) {
            merchantsDisplay.push(merchants.length + ' Merchants');
            merchantsDisplay.push('Summary');
          } else {
            merchantsDisplay.push($.map(merchants, quote).join(' + '));
            merchantsDisplay.push('Merchant Summary');
          }
        }

        if (accounts.length + groups.length > 1) {
          $.each(groups, function(i, group){ $.merge(accounts, $(group).fn('items')) });
          accountsDisplay.push($.unique(accounts).length + ' Accounts');
        } else if (accounts.length) {
          accountsDisplay.push(accounts[0].getName());
        } else if (groups.length) {
          accountsDisplay.push(groups[0].getName())
          accountsDisplay.push('Account Group');
        }

        if (tagsDisplay.length && merchantsDisplay.length && accountsDisplay.length) {
          title = [tagsDisplay[0], merchantsDisplay[0]].join(' and ');
          subtitle = 'in ' + accountsDisplay[0];
        } else if ((tagsDisplay.length || merchantsDisplay.length) && accountsDisplay.length) {
          title = (tagsDisplay[0] || merchantsDisplay[0]);
          subtitle = 'in ' + accountsDisplay[0];
        } else if (tagsDisplay.length && merchantsDisplay.length) {
          title = [tagsDisplay[0], merchantsDisplay[0]].join(' and ');
          subtitle = 'Summary';
        } else if (tagsDisplay.length) {
          title = tagsDisplay[0];
          subtitle = tagsDisplay[1];
        } else if (merchantsDisplay.length) {
          title = merchantsDisplay[0];
          subtitle = merchantsDisplay[1];
        } else if (accountsDisplay.length) {
          title = accountsDisplay[0];
          subtitle = accountsDisplay[1];
        }
      }

      this.transactions.fn('setTitle', {display: title, subtitle: subtitle || ''});
      shared.setPageTitle(title + ' ' + (subtitle || ''));
    },

    setAddTransactionAvailabilityForState: function(accounts, groups, tags, merchants, search) {
      var oneAccountSelected = (accounts.length == 1) && (groups.length + tags.length + merchants.length == 0),
          testerForPendingTransactions = preferences.hasFeature('pending_txactions'),
          accountIsManual = oneAccountSelected && accounts[0].isCash(),
          accountIsInvestment= oneAccountSelected && accounts[0].isInvestment(),
          addTransactionEnabled = oneAccountSelected && !search && !accountIsInvestment && (testerForPendingTransactions || accountIsManual);

      $('.add-transaction .edit', this.transactions).css('visibility', addTransactionEnabled ? '' : 'hidden');
      if (addTransactionEnabled) $('.add-transaction', this.transactions).fn('account', accounts[0]);
    },

    redrawChart: function() {
      if (!wesabe.charts || !wesabe.charts.txn) {
        var self = this;
        wesabe.ready('wesabe.charts.txn', function(){ self.redrawChart(); });
        return;
      }

      var chart = wesabe.charts.txn;
      chart.params = this.paramsForCurrentSelection();

      var account = page.selection.getByClass(wesabe.views.widgets.accounts.Account)[0];
      if (account && account.isInvestment()) {
        chart.hide();
        this.displayInvestmentHeader(account);
      } else {
        $("#investment-header").hide();
        chart.redraw();
        chart.show();
      }
    },

    displayInvestmentHeader: function(account) {
      var positions = account.getInvestmentPositions();
      $("#investment-positions .position").remove();
      for (i = 0; i < positions.length; i++) {
        var position = positions[i];
        var security = position["investment-security"];
        var cell = {
          name: $('<td>' + (security["display-name"] || security.name) + '</td>'),
          units: $('<td class="amount">' + position.units + '</td>'),
          unitPrice: $('<td class="amount">' + position["unit-price"].display + '</td>'),
          marketValue: $('<td class="total amount">' + position["market-value"].display + '</td>')
        };

        if (security.ticker) {
          cell.name.append(' (<a href="http://www.google.com/finance?q=' + security.ticker + '">' + security.ticker + '</a>)');
        }

        var row = $("<tr class='position'/>")
                    .append(cell.name, cell.units, cell.unitPrice, cell.marketValue);
        $("#investment-positions tr.header").after(row);
      }

      var availableCash = account.getInvestmentBalance("available-cash");
      if (availableCash) {
        $("#available-cash").html(availableCash.display)
        $("tr.available-cash").show();
      } else {
        $("tr.available-cash").hide();
      }

      $("#market-value").html(account.getMarketValue().display);
      $("#account-value").html(account.getBalance().display);
      $("#investment-header").show();
    },

    paramsForCurrentSelection: function() {
      var selection = this.selection.get(),
          length = selection.length,
          params = [],
          currencies = [];

      while (length--) {
        var selectedObject = selection[length];
        if (jQuery.isFunction(selectedObject.toParams))
          params = params.concat(selectedObject.toParams());
        if (jQuery.isFunction(selectedObject.getCurrencies))
          currencies = currencies.concat(selectedObject.getCurrencies());
      }

      if (this.start && this.end) {
        params.push({name: 'start', value: date.toParam(this.start)});
        params.push({name: 'end', value: date.toParam(this.end)});
      }

      if (this.search != null)
        params.push({name: 'query', value: this.search});

      // when not searching we don't necessarily need offset and limit
      if (this.offset !== null)
        params.push({name: 'offset', value: this.offset});
      if (this.limit !== null)
        params.push({name: 'limit', value: this.limit});

      params.push({name: 'unedited', value: this.unedited ? 'true' : 'false'});

      currencies = array.uniq(currencies);
      params.currency = (currencies.length == 1) ?
                          currencies[0] :
                          wesabe.data.preferences.getDefaultCurrency();

      return params;
    }
  };
})();

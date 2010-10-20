/**
 * Wraps a <div class="edit-dialog"> containing the editing controls for
 * an account. This is a singleton class managed by {AccountWidget}
 * instances. This class handles its own DOM events.
 */
wesabe.$class('wesabe.views.widgets.accounts.AccountEditDialog', wesabe.views.widgets.Dialog, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $class.prototype = $.extend($.extend({}, $super), {
    _accountWidget: null,
    _account: null,
    _trackBalanceBox: null,
    _archivedBox: null,
    _name: null,
    _currency: null,
    _currentBalance: null,
    _password: null,
    _currentBalanceText: null,
    _editText: null,
    _editButtons: null,
    _deleteText: null,
    _deleteButtons: null,
    _deleteConf: null,
    _saveError: null,
    _deleteCancelButton: null,
    _deleteButton: null,
    _deleteError: null,
    _ssuTab: null,
    _balanceTab: null,
    _archiveTab: null,
    _tabs: null,
    _tabTexts: null,
    _archiveText: null,
    _ssuText: null,
    _ssuErrorText: null,
    _spinner: null,

    init: function(element, accountWidget) {
      var me = this;

      $super.init.call(this, element);
      this._accountWidget = accountWidget;

      // Initialize instance variables
      me._trackBalanceBox = element.find('input[name=track-balance]');
      me._archivedBox = element.find('input[name=archive-account]');
      me._name = element.find('input[name=account-name]');
      me._currency = element.find('select[name=account-currency]');
      me._currentBalance = element.find('input[name=current-balance]');
      me._password = element.find('input[name=delete-account-password]');

      me._currentBalanceText = element.find('div.current-balance');
      me._editText = element.find('div.top div.edit-details');
      me._editButtons = element.find('div.bottom div.edit-details');
      me._deleteText = element.find('div.top div.delete-details');
      me._deleteButtons = element.find('div.bottom div.delete-details');

      me._deleteConf = me._editButtons.find('a.delete.conf');
      me._saveError = element.find('div.right > p.error-message');

      me._deleteCancelButton = me._deleteButtons.find('a.cancel');
      me._deleteButton = me._deleteButtons.find('a.delete');
      me._deleteError = element.find('div.delete-details p.error-message');

      me._ssuTab = element.find('span.ssu').parent();
      me._balanceTab = element.find('span.track-balance').parent();
      me._archiveTab = element.find('span.archive-account').parent();

      me._tabs = element.find('a.edit-dialog-inset-tab');
      me._tabTexts = element.find('div.inset-tab-text');
      me._archiveText = me._tabTexts.filter('.archive-account');
      me._ssuText = me._tabTexts.filter('.ssu');
      me._ssuErrorText = me._tabTexts.filter('.ssu-error');

      me._spinner = element.find('img.spinner');

      element.find('.reset-creds').bind('click', function(){ me.onResetCredentials() });
      element.find('.delete-creds').bind('click', function(){ me.onDeleteCredentials() });

      // Bind the buttons to their events
      me._deleteConf.bind('click', function(){ me.onDeleteConf() });

      // Bind the track balance checkbox to show/hide the balance field
      me._trackBalanceBox.bind('click', function(){ me.showHideBalance() });

      // Bind the tabs to switch the visible tab
      element.find('a.edit-dialog-inset-tab').bind('click', function(){
        me.switchToTab($(this));
      });
    },

    /**
     * Called when the user wants to edit a certain {Account}. This is the
     * final link in a chain of {#onBeginEdit} calls from {Account} to here.
     */
    onBeginEdit: function(account) {
      var me = this;
      me._account = account;

      me.setButtonsDisabled(false);

      // Position and show the edit dialog
      var aPos = account.getPosition();
      me.getElement().css({top: aPos.top-12, left: aPos.left+299});
      me.showModal();

      // Fill in data
      me.setName(account.getName());
      me.setBalance(account.getTotal());
      me.setCurrency(account.getCurrency());
      me._trackBalanceBox.attr('checked', account.hasBalance());
      me._archivedBox.attr('checked', account.isArchived());
      me.getElement().find('.account-name-text').text(account.getName());

      // Reset panel and field visibility
      me._saveError.hide();
      me.showHideBalance();
      me._resetTabsAndPanels();

      // Show Track Balance tab for cash accounts
      if (account.isCash()) me._balanceTab.show();

      // Show SSU tab for SSU accounts
      if (account.isSSU()) me._ssuTab.show();

      // Fix the styling on the first visible tab, select it
      me.getElement().find('a.edit-dialog-inset-tab:visible:first')
        .addClass('first-child')
        .trigger('click');

      me._name.focus();
      return me;
    },

    onEndEdit: function() {
      $super.onCancel.apply(this, arguments);
    },

    isDeletePanel: function() {
      return this._deleteButtons.is(':visible');
    },

    /**
     * Called by {Dialog} when this dialog receives a cancel event,
     * either from a Cancel button or by pressing ESC.
     */
    onCancel: function() {
      if (this.isDeletePanel())
        this.onDeleteCancel();
      else
        $super.onCancel.apply(this, arguments);
    },

    /**
     * Called by {Dialog} when this dialog receives a confirm event,
     * either from a Save/Submit/Confirm button or by pressing ENTER.
     */
    onConfirm: function() {
      if (this.isDeletePanel())
        this.onDelete();
      else
        this.onSave();
    },

    onSave: function() {
      var me = this,
          account = me._account,
          dirty = false,
          accountURI = "/data"+me._account.getURI(),
          shouldTrackBalance = me._trackBalanceBox.attr('checked');

      function commitAttributes() {
        var data = {
          name: me._name.val(),
          currency: me._currency.val()
        };

        if (data.name === account.getName() && data.currency === account.getCurrency()) {
          // nothing changed
          enableOrDisableBalance();
        } else {
          dirty = true;
          $.ajax({
            type: "PUT",
            url: accountURI,
            data: data,
            beforeSend: busy,
            success: enableOrDisableBalance,
            error: error
          });
        }
      }

      function enableOrDisableBalance() {
        if (!account.isCash() || !(shouldTrackBalance ^ account.hasBalance())) {
          // can't do anything about it or nothing has changed
          commitBalance();
        } else {
          dirty = true;
          $.ajax({
            type: "PUT",
            url: accountURI+"/"+(shouldTrackBalance ? "enable" : "disable")+"-balance",
            beforeSend: busy,
            success: commitBalance,
            error: error
          })
        }
      }

      function commitBalance() {
        var newBalance = me._currentBalance.val();

        if (!shouldTrackBalance || !hasValue(newBalance) || (newBalance === "") || (newBalance === account.getTotal())) {
          // not tracking balance or nothing changed
          notBusy();
          done();
        } else {
          dirty = true;
          $.ajax({
            type: "POST",
            url: accountURI+"/balances",
            data: {balance: newBalance && newBalance.replace(/[^\d\.,]+/g, '')},
            beforeSend: busy,
            success: done,
            error: error,
            complete: notBusy
          });
        }
      }

      function busy() {
        me._spinner.show();
        me.setButtonsDisabled(true);
      }

      function notBusy() {
        me._spinner.hide();
        me.setButtonsDisabled(false);
      }

      function error() {
        me._saveError.slideDown();
      }

      function done() {
        if (dirty)
          me._accountWidget.refresh();
        me.onEndEdit();
      }

      commitAttributes();
    },

    onDeleteConf: function() {
      this._editText.slideUp();
      this._editButtons.hide();
      this._deleteText.slideDown();
      this._deleteButtons.show();
    },

    onDeleteCancel: function() {
      var me = this;

      me._deleteButtons.hide();
      me._deleteText.slideUp(function(){ me._password.val(''); });
      me._editButtons.show();
      me._editText.slideDown();
      me._deleteError.slideUp();
    },

    onDelete: function() {
      var me = this;

      $.ajax({
        type: "DELETE",
        data: {'password': me._password.val()},
        url: me._account.getURI(),
        dataType: "text",
        beforeSend: function() {
          me._spinner.show();
          me.setButtonsDisabled(true);
        },
        success: function() {
          me._account.getElement().hide();
          me._accountWidget.refresh();
          me.onEndEdit();
        },
        error: function(XMLHttpRequest, textStatus, errorThrown) {
          if (XMLHttpRequest.status == 403)
            me._deleteError.text(XMLHttpRequest.responseText).slideDown();
          else
            me._deleteError.text("Sorry, something has gone wrong.").slideDown();
        },
        complete: function() {
          me._spinner.hide();
          me.setButtonsDisabled(false);
        }
      });
    },

    onResetCredentials: function() {
      if (this._account.isSSU())
        wesabe.views.shared.navigateTo('/credentials/destroy/'+this._account.getCredential().id);
    },

    onDeleteCredentials: function() {
      if (this._account.isSSU()) {
        var me = this, credential = me._account.getCredential();
        $.ajax({
          url: '/credentials/destroy/'+credential.id,

          success: function() {
            me._accountWidget.refresh();
          },

          error: function(xhr, opts, error) {
            wesabe.error('there was a problem deleting credentials: status=', xhr.status, ' client error: ', error);
            // it didn't work, restore the credential info
            me._account.setCredential(credential);
            // show the ssu tab again
            me._ssuTab.show();
            me.switchToFirstVisibleTab();
          }
        });
        // be optimistic and assume it'll work
        me._account.setCredential(null);
        // hide the ssu tab
        me._ssuTab.hide();
        me.switchToFirstVisibleTab();
      }
    },

    setName: function(name) {
      this._name.val(name);
    },

    setBalance: function(balance) {
      this._currentBalance.val(hasValue(balance) ? balance : '');
    },

    setCurrency: function(currency) {
      if (currency) this._currency.val(currency);
    },

    showHideBalance: function() {
      if (this._trackBalanceBox.attr('checked')) {  this._currentBalanceText.show(); }
      else { this._currentBalanceText.hide(); }
    },

    switchToTab: function(tab) {
      this._tabs.add(this._tabTexts).removeClass('on');

      var tabName = tab.children('span').attr('class');
      tab.add('div.inset-tab-text.'+tabName, this.getElement()).addClass('on');

      if (tabName == 'ssu') this.showHideSSUError();
    },

    switchToFirstVisibleTab: function() {
      this.switchToTab(this._tabs.filter(':visible:first'));
    },

    showHideSSUError: function() {
      if (this._account && this._account.hasSSUError()) {
        this._ssuText.removeClass('on');
        this._ssuErrorText.addClass('on');
      } else {
        this._ssuText.addClass('on');
        this._ssuErrorText.removeClass('on');
      }
    },

    /**
     * Restores the default visibity/values for all tabs and panels.
     *
     * @private
     */
    _resetTabsAndPanels: function() {
      // Hide delete panel, error, and buttons
      this._deleteButtons.hide();
      this._deleteText.hide();
      this._deleteError.hide();

      // Show edit panel and buttons
      this._editButtons.show();
      this._editText.show();

      // Clear the password field
      this._password.val('');

      this._ssuTab.add(this._balanceTab).removeClass('on').hide();
      this._tabs.removeClass('on');
      this._archiveTab.show().addClass('on');
      this._archiveText.addClass('on');
    }
  });
});

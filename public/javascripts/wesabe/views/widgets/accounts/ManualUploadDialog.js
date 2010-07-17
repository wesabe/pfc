/**
 * Handles the dialog for uploading files to non-SSU accounts.
 */
wesabe.$class('wesabe.views.widgets.accounts.ManualUploadDialog', wesabe.views.widgets.Dialog, function($class, $super, $package) {
  $.extend($class.prototype, {
    _account: null,
    _form: null,
    _accountUriInput: null,
    _fiLink: null,

    init: function(element, account) {
      $super.init.call(this, element);
      this._account = account;
      this._accountUriInput = element.find('input[name=account_uri]');
      this._fiLink = element.find('a.fi-link');
      this._form = element.find('form');
    },

    show: function() {
      this._accountUriInput.val(this._account.getURI());
      this._fiLink.attr('href', this._account.getURI()+'/financial_institution_site');
      $super.show.apply(this, arguments);
    },

    onBlur: function() {
      this.hide();
    },

    onConfirm: function() {
      this._form[0].submit();
    }
  });
});

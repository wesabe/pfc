/**
 * Displays an error along with a reset link for an account's credentials.
 */
wesabe.$class('wesabe.views.widgets.accounts.AutomaticUploaderErrorDialog', wesabe.views.widgets.Dialog, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _account: null,
    _resetCredLink: null,

    init: function(element, account) {
      $super.init.call(this, element);
      this._account = account;
      this._resetCredLink = element.find('a.reset-creds');
    },

    onBlur: function() {
      this.hide();
    },

    show: function() {
      // FIXME: This shouldn't be done as a GET, but this is a historical artifact
      // from when SSU was first created. It should instead do an ajax DELETE or
      // a form POST with _method=DELETE and then send the user to the right page
      // to re-enter their credentials.
      this._resetCredLink.attr('href', '/credentials/destroy/'+this._account.getCredential().id);
      $super.show.call(this);
    }
  });
});

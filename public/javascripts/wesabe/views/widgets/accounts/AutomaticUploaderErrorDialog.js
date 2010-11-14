/**
 * Displays an error along with a reset link for an account's credentials.
 */
wesabe.$class('wesabe.views.widgets.accounts.AutomaticUploaderErrorDialog', wesabe.views.widgets.Dialog, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _account: null,
    _resetCredLink: null,

    init: function(account) {
      $super.init.call(this);
      this._account = account;

      this.addClassName("hover-box");
      this.setContentElement(this.getTopElement());

      var contents = $('<div class="contents">'+
                         '<div class="header">Automatic Uploader Error</div>'+
                         '<p>Your bank has reported an error. To reset your bank credentials, click <a class="reset-creds">here</a>.</p>'+
                       '</div>');

      this.appendElement(contents);
      this._resetCredLink = contents.find('a.reset-creds');
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

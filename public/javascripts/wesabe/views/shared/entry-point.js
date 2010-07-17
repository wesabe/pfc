// shared entry point (login, signup) methods
jQuery(function($){
  wesabe.provide('views.shared.entryPoint', {
    checkCookies: function() {
      var value = new Date().getTime().toString();
      $.cookie('cookie-'+value, 'yes');
      if ($.cookie('cookie-'+value) !== 'yes') {
        $("#login-error .title").text("Cookies Disabled");
        $("#login-error .message").text("It looks like your browser has cookies disabled. Cookies are needed to use our site.");
        $("#login-error").show();
      } else {
        $.cookie('cookie-'+value, null);
      }
    },
    getTimezone: function() { $("#tz_offset").val(new Date().getTimezoneOffset()); }
  });

  $(function(){
    wesabe.views.shared.entryPoint.checkCookies();
    wesabe.views.shared.entryPoint.getTimezone();
  });
});
// shared form methods
jQuery(function($){
  wesabe.provide('views.shared.form', {
    enable: function(form) {
      this.enableSubmit(form);
      this.enableCancel(form);
    },
    // enable link-submit buttons on forms, adding a hidden submit button so that
    // hitting enter to submit works
    enableSubmit: function(form) {
      form.append('<input type="submit" style="position:absolute;left:-10000px;width:1px"/>');
      $(".submit", form).unbind("click").bind("click", function(){ $(this).parents("form").submit(); });
    },
    // enable hitting escape to hide the hover box
    enableCancel: function(form) {
      $(":input", form).keyup(function(event) {
        if (event.which == 27 /* esc */) {
          var hoverBox = $(this).parents('.hover-box');
          if (hoverBox.length) {
            hoverBox.hideModal();
            event.preventDefault();
          }
        }
      });
    },
    setFocus: function() {
      $("form .initial-focus").focus();
    }
  });

  var forms = $("form");
  wesabe.views.shared.form.enableSubmit(forms);
  wesabe.views.shared.form.enableCancel(forms);
  wesabe.views.shared.form.setFocus();
});

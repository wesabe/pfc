$(function(){
  wesabe.ready('$.historyInit', function() {
    $.historyInit(function(hash) {
      $(window).trigger('hash-changed', hash);
    });
  });

  $.fn.include = $.fn.fn;

  // Keep the navbar buttons in hover while their menus are open
  $('#global-nav ul > li').hover(
    function() { $(this).children("a, ul").addClass("menu-on"); },
    function() { $(this).children("a, ul").removeClass("menu-on"); }
  );

  $.support.goodStackingModel = function() {
    // fuck you, IE7, and your stacking contexts too.
    if ($.browser.msie) {
      if ($.browser.version.slice(0,1) == "8") {
        return true;
      } else {
        return false;
      }
    } else {
      return true;
    }
  };

  jQuery.fn.extend({
    showModal: function(callback) {
      var modal = $(this);

      if ($.support.goodStackingModel()) {
        $('body').append("<div id='modal-mask'></div>");
        var mask = $('#modal-mask');

        mask
          .css("height", $(document).height()+'px')
          .css("width", $(document).width()+'px')
          .show()
          .fadeTo("fast", 0.4);

        // Clicking on the mask removes it and hides the element
        mask.one("click", function(){ modal.hideModal(); });
      }

      if ($.isFunction(callback))
        modal.one('hideModal', callback);

       // Index the element on top of the mask and fade in
       modal
        .css("z-index", "1001")
        .fadeIn();

      return modal;
    },

    hideModal: function(callback) {
      var mask = $('#modal-mask');
      mask.fadeOut("fast", function(){ mask.remove(); });
      this
        .fadeOut(callback)
        .trigger('hideModal');
    }
  });

  // don't allow text on buttons to be selected
  $(".button, .toggle-button")
    .mousedown(function() {return false;})
    .each(function() {this.onselectstart = function() {return false;};}); // ie
});

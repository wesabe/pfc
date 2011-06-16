jQuery(function($) {
  var root = $('#trends-summary');

  var behaviors = wesabe.provide('views.trendsSummaryWidget', {
    root: {
      init: function() {
        var self = $(this);

        $(window).bind('hash-changed', function(_, hash) { self.fn("_restoreFromHash", hash); });
        if (window.location.hash)
          self.fn("_restoreFromHash", window.location.hash);

        return self;
      },

      _restoreFromHash: function(hash) {
        var match = hash.match(/spending|earnings/);
        if (match) {
          $("#spending-earnings-summary li", this).removeClass("on");
          $("." + match[0], this).addClass("on");
        }
      }
    }
  });

  root.include(behaviors.root).fn('init');
});

(function($) {
  $.fn.clippy = function(text, bgcolor) {
    if (!bgcolor)
      bgcolor = Color.backgroundForElement($(this), '#ffffff').toHexString();

    $(this)
      .after($('<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" width="110" height="14" id="clippy"> <param name="movie" value="/clippy.swf"/> <param name="allowScriptAccess" value="always" /> <param name="quality" value="high" /> <param name="scale" value="noscale" /> <param NAME="FlashVars" value="text='+escape(text)+'"> <param name="bgcolor" value="'+bgcolor+'"> <embed src="/clippy.swf" width="110" height="14" name="clippy" quality="high" allowScriptAccess="always" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" FlashVars="text='+escape(text)+'" bgcolor="'+bgcolor+'" /> </object>'))
      .after('&nbsp;');
  };

  function Color(r, g, b, a) {
    this.red   = parseInt(r, 10);
    this.green = parseInt(g, 10);
    this.blue  = parseInt(b, 10);
    this.alpha = (typeof(a) == 'undefined') ? 255 : parseInt(a, 10);
  }
  Color.prototype = {
    toHexString: function() {
      // FIXME: this doesn't account for alpha -- can it?
      return '#'+$.map([this.red, this.green, this.blue], function(b) {
        var s = b.toString(16);
        return (s.length > 1) ? s : ('0'+s);
      }).join('');
    },

    isTransparent: function() {
      return this.alpha == 0;
    }
  };
  Color.parse = function(string) {
    var m;

    if (string == 'transparent') {
      return new Color(0, 0, 0, 0);
    } else if (m = string.match(/^rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*(\d+)\s*)?\)$/i)) {
      return new Color(m[1], m[2], m[3], m[4]);
    } else if (m = string.match(/^#([a-f0-9]{6})$/i)) {
      var r = parseInt(m[1].substring(0, 2), 16),
          g = parseInt(m[1].substring(2, 4), 16),
          b = parseInt(m[1].substring(4, 6), 16);
      return new Color(r, g, b);
    }
  };
  Color.backgroundForElement = function(element, defaultColor) {
    while (element.length && !element.is('body')) {
      var color = Color.parse(element.css('background-color'));
      if (!color.isTransparent())
        return color;
      element = element.parent();
    }

    return Color.parse(defaultColor);
  };
})(jQuery);

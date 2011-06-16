jQuery.fn.extend({
  // allow reset to be called directly on jQuery selectors
  reset: function() { this.each(function() { this.reset(); }); },

  disable: function(value) {
    this.attr("disabled", true);
    if (value != undefined) {
      if (this.is("select")) {
        this.append("<option class='disable-message' selected>"+value+"</option>");
      } else {
        this.val(value);
      }
    }
    return this;
  },

  enable: function() {
    if (this.is("select")) {
      this.remove("option.disable-message");
    } else {
      this.val('');
    }
    this.attr("disabled", false);
    return this;
  },

  exists: function() {
    return this.length > 0;
  }

});

// set up jQuery's ajax to filter /*-secure- header
jQuery.ajaxSetup({
  'dataFilter': function(data, type) { return (typeof data == "string") ? data.replace(/^\/\*-secure-([\s\S]*)\*\/\s*$/, "$1") : data; }
});

jQuery.same = function(a, b) {
  a = $.unique($.makeArray(a)); b = $.unique($.makeArray(b));
  var length = a.length;
  return (a.length == b.length) && ($.unique($.merge(a, b)).length == length);
};

jQuery.getsettext = function(finder) {
  return jQuery.getset({
    node: function() {
      return finder.apply(this, arguments);
    },

    get: function(getset) {
      return getset.node().text();
    },

    set: function(value, getset) {
      getset.node().text(value);
    }
  });
};

jQuery.getsetclass = function(className, finder) {
  return jQuery.getset({
    get: function(getset) {
      return getset.node().hasClass(className);
    },

    set: function(value, getset) {
      if (value != getset.get())
        getset.node().toggleClass(className);
    },

    node: function() {
      return finder ? finder.apply(this, arguments) : $(this);
    }
  });
};

jQuery.getsetdata = function(key) {
  return jQuery.getset({
    get: function() {
      return $(this).kvo(key);
    },

    set: function(value) {
      $(this).kvo(key, value);
    }
  });
};

jQuery.getset = function(getset) {
  return function() {
    var self = this, wrapper = {};

    var wrap = function(wrapper, name) {
      wrapper[name] = function() {
        var args = $.makeArray(arguments);
        args.push(wrapper);
        return getset[name].apply(self, args);
      };
    };

    for (var k in getset) {
      if (getset.hasOwnProperty(k)) {
        wrap(wrapper, k);
      }
    }

    var value = arguments[0];
    if (value === undefined) {
      if (jQuery.isFunction(wrapper.get)) {
        return wrapper.get();
      } else {
        throw new Error("No getter defined for " + this);
      }
    } else {
      if (jQuery.isFunction(wrapper.set)) {
        wrapper.set.apply(wrapper, arguments);
        return $(this);
      } else {
        throw new Error("No setter defined for " + this);
      }
    }
  };
};

// cookie access from http://www.stilbuero.de/2006/09/17/cookie-plugin-for-jquery/
jQuery.cookie = function(name, value, options) {
    if (typeof value != 'undefined') { // name and value given, set cookie
        options = options || {};
        if (value === null) {
            value = '';
            options.expires = -1;
        }
        var expires = '';
        if (options.expires && (typeof options.expires == 'number' || options.expires.toUTCString)) {
            var date;
            if (typeof options.expires == 'number') {
                date = new Date();
                date.setTime(date.getTime() + (options.expires * 24 * 60 * 60 * 1000));
            } else {
                date = options.expires;
            }
            expires = '; expires=' + date.toUTCString(); // use expires attribute, max-age is not supported by IE
        }
        // CAUTION: Needed to parenthesize options.path and options.domain
        // in the following expressions, otherwise they evaluate to undefined
        // in the packed version for some reason...
        var path = options.path ? '; path=' + (options.path) : '';
        var domain = options.domain ? '; domain=' + (options.domain) : '';
        var secure = options.secure ? '; secure' : '';
        document.cookie = [name, '=', encodeURIComponent(value), expires, path, domain, secure].join('');
    } else { // only name given, get cookie
        var cookieValue = null;
        if (document.cookie && document.cookie != '') {
            var cookies = document.cookie.split(';');
            for (var i = 0; i < cookies.length; i++) {
                var cookie = jQuery.trim(cookies[i]);
                // Does this cookie string begin with the name we want?
                if (cookie.substring(0, name.length + 1) == (name + '=')) {
                    cookieValue = decodeURIComponent(cookie.substring(name.length + 1));
                    break;
                }
            }
        }
        return cookieValue;
    }
};

// fix browser version regex (IE 7 sometimes has both MSIE 7.0 and later MSIE 6.0 in the user agent)
jQuery.browser.version = (navigator.userAgent.toLowerCase().match( /.+?(?:rv|it|ra|ie)[\/: ]([\d.]+)(?!.+opera)/ ) || [])[1];

// shortcut for performing a PUT
jQuery.put = function(url, data, callback, type) {
  if ( jQuery.isFunction( data ) ) {
    callback = data;
    data = {};
  }

  return jQuery.ajax({
    type: "PUT",
    url: url,
    data: data,
    success: callback,
    dataType: type
  });
};

// extracted from http://digitalbush.com/projects/masked-input-plugin/
// allows for $("#textarea-yay").caret(beginPos, endPos)
(function($) {
  //Helper Function for Caret positioning
  $.fn.caret=function(begin,end){
    if(this.length==0) return;
    if (typeof begin == 'number') {
      end = (typeof end == 'number')?end:begin;
      return this.each(function(){
        if(this.setSelectionRange){
          this.focus();
          this.setSelectionRange(begin,end);
        }else if (this.createTextRange){
          var range = this.createTextRange();
          range.collapse(true);
          range.moveEnd('character', end);
          range.moveStart('character', begin);
          range.select();
        }
      });
    } else {
      if (this[0].setSelectionRange){
        begin = this[0].selectionStart;
        end = this[0].selectionEnd;
      }else if (document.selection && document.selection.createRange){
        var range = document.selection.createRange();
        begin = 0 - range.duplicate().moveStart('character', -100000);
        end = begin + range.text.length;
      }
      return {begin:begin,end:end};
    }
  };
})(jQuery);

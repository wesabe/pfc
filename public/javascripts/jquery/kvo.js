(function($) {
  function makeExpando() {
    var o = {}, expando, id;
    $(o).data('expando');
    for (var k in o) {
      if (/^jQuery/.test(k)) {
        expando = k;
        id = o[expando];
        break;
      }
    }
    return {expando: expando, id: id};
  }

  $.fn.kvobservable = function(observable) {
    return this.data('kvo', observable);
  };

  $.fn.kvobserve = function(property, fn) {
    return this.bind('kvo-'+property+'-set', fn).kvobservable(true);
  };

  $.fn.kvone = function(property, fn) {
    return this.one('kvo-'+property+'-set', fn).kvobservable(true);
  };

  $.fn.kvunobserve = function(property, fn) {
    return this.unbind('kvo-'+property+'-set', fn).kvobservable(true);
  };

  $.fn.kvo = function(property, value) {
    if (value === undefined) {
      if (typeof property == 'string')
        return this.data('kvo-'+property+'-value');
      else
        for (var p in property) this.kvo(p, property[p]);
    } else {
      var oldvalue = this.kvo(property);
      if (value === oldvalue)
        return this;
      else
        return this
          .data('kvo-'+property+'-value', value)
          .each(function() {
            // prevent bubbling
            $(this).triggerHandler('kvo-'+property+'-set', [value, oldvalue]);
          });
    }
  };

  $.fn.kvobind = function(observable, key, options) {
    if (typeof observable == 'string') {
      options = key;
      var kvo = $.kvo.find(observable);
      observable = kvo.observable;
      key  = kvo.key;
    }

    options = options || {};

    // some option aliases
    options.transform = options.when || options.transform;
    options.property  = options.hasClass || options.attr || options.property;

    // preset transforms
    if (!options.transform || options.transform == 'present') {
      options.transform = function(o){ return o };
    }

    observable = $(observable);
    observable.kvobservable(true);
    var self = this;

    observable.bind('kvo-'+key+'-set', function(event, newvalue, oldvalue) {
      $.kvo.change(self, options.transform(newvalue), oldvalue, key, options);
    });

    $.kvo.change(this, options.transform(observable.kvo(key)), null, key, options);
    return this;
  };

  $.kvo = {
    setters: {
      html: function(e,v){ e.html(v ? v.toString() : '') },
      text: function(e,v){ e.html('').append(document.createTextNode(v)) },
      value: function(e,v){ e.val(v) },
      checked: function(e,v){ e.val(v ? '1' : '0').attr('checked', v) },
      visible: function(e,v){ v ? e.show() : e.hide() },
      hidden: function(e,v){ v ? e.hide() : e.show() }
    },

    setterFor: function(element, options) {
      var setters = $.kvo.setters;
      var property = options.property;

      if (property) {
        return setters[property] || (
          options.attr ? function(e,v){ e.attr(options.attr, v) } :
                         function(e,v){ v ? e.addClass(property) : e.removeClass(property) }
        );
      } else {
        return (
          element.is(':text')     ? setters.value   :
          element.is(':checkbox') ? setters.checked :
          element.is(':radio')    ? setters.checked :
          element.is(':input')    ? setters.value   :
                                    setters.text
        );
      }
    },

    set: function(element, value, options) {
      $.kvo.setterFor(element, options).call($.kvo, element, value);
    },

    change: function(elements, newvalue, oldvalue, key, options) {
      $(elements).each(function() {
        $.kvo.set($(this), newvalue, options);
      });
    },

    defineGetter: function(object, key) {
      object.getter(key, function(){ return $(this).kvo(key) });
    },

    defineSetter: function(object, key) {
      object.setter(key, function(value){ $(this).kvo(key, value) });
    },

    find: function(path, scope) {
      if (!scope) scope = window;
      var observable, valuepath = [];

      $.each(path.split('.'), function() {
        if ($(scope).kvobservable()) {
          valuepath = [];
          observable = scope;
        }
        valuepath.push(this);
        scope = scope[this];
      });

      return {observable: observable, valuepath: valuepath};
    },

    getValue: function(valuepath, value) {
      $.each(valuepath, function(){ value = value[this] });
      return value;
    }
  };
})(jQuery);

// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// add trim function to String class
String.prototype.trim = function() { return this.replace(/^\s*|\s*$/g,""); };

var SessionTimer = {
  start: function() {
    SessionTimer.interval_id = setTimeout(SessionTimer.check, 60000);
  },
  disable: function() {
    window.clearTimeout(SessionTimer.interval_id);
  },
  check: function() {
    jQuery.getScript('/session');
    SessionTimer.start();
  },
  reset: function() {
    jQuery.ajax({
      type: 'PUT',
      url: '/session',
      dataType: 'script'
    });
  }
};


var wesabe = {
  __name__: 'wesabe',

  get: function(pkg, module, base, callback) {
    var name  = wesabe._fqn(pkg, module),
        parts = name.split('.');

    if (!base)
      base = window;

    if (base.__name__)
      parts.unshift(base.__name__);

    if (!callback)
      callback = function(o){ return o };

    if (typeof module == 'string')
      parts.push(module);

    for (var i = 0; i < parts.length; i++) {
      base = base[parts[i]] = callback(base[parts[i]], parts.slice(0, i+1).join('.'));
      if (!base) return null;
    }

    return base;
  },

  _fqn: function(pkg, module) {
    var result = pkg && pkg.__name__ || pkg;

    if (module)
      result += '.' + module;

    return result;
  },

  /**
   * Define a namespace under the toplevel 'wesabe' namespace.
   *
   * @param {!string} module A dot-separated namespace (e.g. lang.string).
   * @param {?*} value An optional value for the namespace (defaults to {}).
   * @return {*}
   */
  provide: function(module, value) {
    if (!/^wesabe\./.test(module))
      module = 'wesabe.' + module;

    return wesabe.get(module, null, null, function(part, name) {
      part = ((module == name) && value) || part || {};
      part.__name__ = name;
      return part;
    });
  },

  /**
   * Takes a callback to be run once the given module has been loaded.
   *
   *   wesabe.ready("$.historyInit", function() {
   *     wesabe.privacy.registerSanitizer(...);
   *   });
   *
   * @param {!string} name The dot-separated name of the module/class to watch for.
   * @param {!function(*)} callback A function to call when the module is ready.
   * @param {?number} ttl Number of times to check for the module (default: 100).
   */
  ready: function(name, callback, ttl) {
    ttl = ttl || 100;

    (function() {
      var obj = wesabe.get(name);

      if (obj) {
        // got it, fire the callback
        callback(obj);
      } else if (ttl--) {
        // not yet, try again in 50ms
        setTimeout(arguments.callee, 50);
      }
    })();
  },

  /* Dynamically load a javascript module.
   *
   * @param {!string|object} pkg The path to a javascript file or a JS package object.
   * @param {?string} module The name of the module to load within pkg, if given a JS object.
   * @param {?function(object)} callback A function to call after the module has been loaded.
   */
  load: function(pkg, module, callback) {
    var src;

    var obj = wesabe.get(pkg, module);
    if (obj) {
      callback(obj);
      return;
    }

    src = /\//.test(pkg) ? pkg
                         : wesabe._fqn(pkg, module).replace(/\./g, '/');

    if (!src.match(/\.js$/))
      src = src+'.js?'+(new Date().getTime());
    if (!src.match(/^(http(s)?:|\/javascripts\/)/))
      src = '/javascripts/' + src;

    var script = document.createElement('script');
    script.type = 'text/javascript';
    script.src = src;
    document.getElementsByTagName('body')[0].appendChild(script);

    if (callback)
      wesabe.ready(wesabe._fqn(pkg, module), callback);
  },

  /**
   * Builds a class with +name+ with an optional superclass given by +$super+,
   * yielding the class, superclass, and package to +callback+.
   *
   * @param {!string} name The full name of the class "foo.Bar".
   * @param {?function()} $super Optional superclass, used as callback if no 3rd
   *                             argument is given, defaults to wesabe.lang.Subscribable.
   * @param {?function(function, function, object)} callback
   * @return {function()} The class that was built.
   */
  $class: function(name, $super, callback) {
    if (callback === undefined) {
      callback = $super;
      $super = undefined;
    }

    // make sure everything is Subscribable by default
    if ($super === undefined) $super = wesabe.lang.Subscribable;

    // use the prototype if they gave us a class
    if ($super && $super.prototype) $super = $super.prototype;

    // create the constructor and inject it into the tree
    var $class = wesabe.provide(name, function() {
      if (this.init)
        this.init.apply(this, arguments);
    });

    // build the class
    $class.prototype = $.extend($super ? $.extend({}, $super) : {}, {
      getClass: function(){ return $class },
      isInstanceOf: function(klass){ return klass === this.getClass() }
    });

    // get the package
    var $package = wesabe.get($class.__name__.replace(/\.[^\.]+$/, ''));

    if (callback)
      callback($class, $super, $package);

    return $class;
  }
};

var either = function() {
  for (var i = 0; i < arguments.length; i++)
    if (arguments[i]!==null && arguments[i]!==undefined)
      return arguments[i];
};

var hasValue = function(val) {
  return val !== undefined && val !== null
};

// from http://dominiek.com/108-ajax-snippet-blank-out-a-div-with-a-spinner
function spinDiv(div) {
  // see if the spinDiv exists already, and remove it to toggle off
  if (div.children(".spin_div").remove().length == 0) {
    var container = div[0]; // assumes jQuery element
    var positioning = 'top: '+container.offsetTop+'px; width: '+container.offsetWidth+'px; height: '+container.offsetHeight+'px; left: ' + container.offsetLeft + 'px;';
    div.append('<div class="spin_div" style="position: absolute; ' + positioning + '"></div>');
  }
}

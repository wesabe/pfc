(function() {
  // import jQuery as $
  var $ = jQuery;
  // import window.console
  var console = window.console;

  /* @const */ var LEVELS = ['debug', 'log', 'info', 'warn', 'error'];
  /* @const */ var LEVEL_MAP = {debug: 0, log: 1, info: 2, warn: 3, error: 4};

  /**
   * Module that includes logging methods that delegate to a _log method that
   * you define with type {function(string, Array.<*>)}.
   */
  wesabe.provide('util.Loggable', {
    debug: function() {
      this._log('debug', $.makeArray(arguments));
    },

    log: function() {
      this._log('log', $.makeArray(arguments));
    },

    info: function() {
      this._log('info', $.makeArray(arguments));
    },

    warn: function() {
      this._log('warn', $.makeArray(arguments));
    },

    error: function() {
      this._log('error', $.makeArray(arguments));
    }
  });

  var $class = wesabe.provide('util.Logger', function() {});
  var support = $class.support = {
    logging: console && $.isFunction(console.log),
    nativeConsole: false,
    firebugConsole: false,
    multiArgs: false,
    debug: false,
    info: false,
    warn: false,
    error: false
  };

  if (support.logging) {
    var logFuncString = $.isFunction(console.log.toString) ? console.log.toString() : '';
    support.nativeConsole = /\[native code\]/.test(logFuncString);
    support.firebugConsole = /firebug/i.test(logFuncString);
    support.multiArgs = support.firebugConsole || $.browser.safari;

    for (var i = LEVELS.length; i--;)
      support[LEVELS[i]] = $.isFunction(console[LEVELS[i]]);
  }

  $class.prototype = $.extend({
    _prefix: '',
    _level: LEVEL_MAP.debug,

    getLevel: function() {
      return this._level;
    },

    setLevel: function(level) {
      this._level = LEVEL_MAP[level] || '';
    },

    getPrefix: function() {
      return this._prefix;
    },

    setPrefix: function(prefix) {
      this._prefix = prefix;
    },

    /**
     * Set up a method to delegate to {#_sendToConsole} depending on the level
     * of support the browser has for logging.
     *
     * @private
     */
    _log: !support.logging ? function(){} :
        !support.multiArgs ? function(level, args){ this._sendToConsole(level, [this._prefix+args.join('')]) } :
                             function(level, args){ this._sendToConsole(level, [this._prefix].concat(args)) },

    /**
     * This is the function that actually calls console.log etc.
     *
     * @private
     */
    _sendToConsole: function(level, args) {
      if (LEVEL_MAP[level] < this._level)
        return;

      if (!support[level])
        level = 'log';
      console[level].apply(console, args);
    }
  }, wesabe.util.Loggable);

  /**
   * Add logging to the global wesabe object.
   */
  $.extend($.extend(wesabe, wesabe.util.Loggable), {
    _log: function(level, args) {
      if (!this._logger)
        this._logger = this.loggerFor('');
      this._logger[level].apply(this._logger, args);
    },

    loggerFor: function(prefix) {
      var logger = new wesabe.util.Logger();
      logger.setPrefix(prefix);
      return logger;
    }
  });
})();

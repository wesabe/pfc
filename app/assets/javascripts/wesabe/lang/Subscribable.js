wesabe.provide('lang.Subscribable', {
  /**
   * Subscribe to the 'change' event if {callback} is a function, or specify
   * multiple callbacks via an object with events as keys and functions as
   * values:
   *
   *    ds.subscribe({change: function(data){ ... }, error: function(){ ... });
   *
   * Works with a custom context as described in #bind.
   */
  subscribe: function(callbacks, context) {
    if ($.isFunction(callbacks)) {
      callbacks = {change: callbacks};
    } else if (!callbacks) {
      return;
    }

    context = context || this;
    for (var key in callbacks)
      if (callbacks.hasOwnProperty(key))
        this.bind(key, function(event) {
          var args = $.makeArray(arguments);
          args.shift();
          callbacks[event.type].apply(context, args);
        });
  },

  /**
   * Syntactic sugar for {jQuery#bind} with the addition of an optional context.
   *
   *    // bind click with simple handler
   *    widget.bind('click', function(){ alert('hi') });
   *
   *    // bind click with event data
   *    widget.bind('click', {msg: 'hi'}, function(event){ alert(event.data.msg) });
   *
   *    // bind click with a context
   *    widget.bind('click', function(){ alert(this.msg) }, widget);
   *
   *    // bind with everything
   *    widget.bind('click', {msg: 'hi'}, function(event){ alert(this.msg + ': ' + event.data.msg) }, widget);
   */
  bind: function(eventType, eventDataOrHandler, handlerOrContext, contextOrUndefined) {
    var eventData, handler, context;

    // figure out the method signature
    if (typeof contextOrUndefined != 'undefined') {
      // bind(eventType, eventData, handler, context)
      eventData = eventDataOrHandler;
      handler   = handlerOrContext;
      context   = contextOrUndefined;
    } else {
      if ($.isFunction(eventDataOrHandler)) {
        // bind(eventType, handler, context)
        handler = eventDataOrHandler;
        context = handlerOrContext;
      } else {
        // bind(eventType, eventData, handler)
        eventData = eventDataOrHandler;
        handler   = handlerOrContext;
      }
    }

    // use the context if we got one
    if (context) {
      var wrappedHandler = handler;
      handler = function(){ wrappedHandler.apply(context, arguments) };
    }

    $(this).bind(eventType, eventData, handler);
    return this;
  },

  /**
   * Syntactic sugar for {jQuery#unbind}.
   *
   * @param {!String} eventType
   * @param {?Function} eventHandler
   */
  unbind: function(eventType, eventHandler) {
    $(this).unbind(eventType, eventHandler);
  },

  /**
   * Syntactic sugar for {jQuery#trigger}.
   */
  trigger: function() {
    $(this).trigger.apply($(this), arguments);
    return this;
  }
});

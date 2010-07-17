/**
 * Provides a base class for anything wrapping a text input.
 */
wesabe.$class('wesabe.views.widgets.BaseField', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $class.DOM_EVENT_MAP = {
    keydown: 'onKeyDown', keypress: 'onKeyPress', keyup: 'onKeyUp',
    blur: 'onBlur', focus: 'onFocus',
    change: 'onChange', pollingchange: 'onPollingChange'};

  $.extend($class.prototype, {
    _value: null,
    _changeWatcher: null,

    init: function(element, delegate) {
      var me = this;

      $super.init.call(me, element);

      // bind the events that subclasses or delegates declare themselves interested in
      var delegates = [me];
      if (delegate) delegates.push(delegate);

      var domBindings = {};

      $.each($class.DOM_EVENT_MAP, function(key, method) {
        domBindings[method] = 0;
        $.each(delegates, function(i, d) {
          if (d[method]) {
            element.bind(key, function(event){ d[method].call(d, event, me) });
            domBindings[method]++;
          }
        });
      });

      if (domBindings.onPollingChange > 0)
        this._startWatchingForChanges();

      element.attr('autocomplete', 'off');
    },

    getValue: function() {
      return this.getElement().val();
    },

    setValue: function(value) {
      this.getElement().val(value);
    },

    clear: function() {
      this.getElement().val('');
    },

    focus: function() {
      var element = this.getElement();
      if (element.length) element[0].focus();
    },

    blur: function() {
      this.getElement().blur();
    },

    clearAndBlur: function() {
      this.clear();
      this.blur();
    },

    isEmpty: function() {
      return !this.getElement().val();
    },

    selectAllAndFocus: function() {
      var element = this.getElement();
      element.caret(0, element.val().length);
      this.focus();
    },

    _startWatchingForChanges: function(msToWait) {
      var me = this;
      me._value = me.getValue();
      (function() {
        if (me._value !== me.getValue()) {
          me._value = me.getValue();
          me.getElement().trigger('pollingchange');
        }
        this._changeWatcher = setTimeout(arguments.callee, msToWait || 50);
      })();
    },

    _stopWatchingForChanges: function() {
      clearTimeout(this._changeWatcher);
    },

    destroy: function() {
      this._stopWatchingForChanges();
      $super.destroy.apply(this, arguments);
    }
  });
});

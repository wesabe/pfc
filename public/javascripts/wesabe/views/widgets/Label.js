/**
 * Wraps an element containing optionally-formatted plain text.
 */
wesabe.$class('wesabe.views.widgets.Label', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _value: null,
    _formatter: null,

    init: function(element, formatter) {
      $super.init.call(this, element);
      this._value = element.text();
      this._formatter = formatter;
    },

    getValue: function() {
      return this._value;
    },

    setValue: function(value) {
      if (this._value === value)
        return;

      this._value = value;
      this._redraw();
    },

    getFormatter: function() {
      return this._formatter;
    },

    setFormatter: function(formatter) {
      this._formatter = formatter;
      this._redraw();
    },

    _redraw: function() {
      this.getElement().text(this._formatter ?
        this._formatter.format(this._value) : this._value);
    }
  });
});

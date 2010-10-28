/**
 * Wraps an element containing optionally-formatted plain text.
 */
wesabe.$class('wesabe.views.widgets.Label', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _value: null,
    _formatter: null,
    _textElement: null,

    init: function(element, formatter) {
      if (!wesabe.isJQuery(element))
        formatter = element, element = null;

      if (!element)
        element = $('<label></label>');

      $super.init.call(this, element);
      this._value = element.text();
      this._formatter = formatter;
      this._textElement = element.find('.text-content');
      if (!this._textElement.length) this._textElement = element;

      this.addClassName('field-title');
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

    associateWithField: function(field) {
      if (!field.getId())
        field.setId(wesabe.uniqueId());
      this.getElement().attr('for', field.getId());
    },

    _redraw: function() {
      var textValue = this._formatter ? this._formatter.format(this._value) : this._value,
          extraValue;

      if ($.isArray(textValue))
        extraValue = textValue[1], textValue = textValue[0];

      this._textElement.text(textValue);
      if (extraValue)
        this._textElement.append($('<span></span>').text(extraValue));
    }
  });
});

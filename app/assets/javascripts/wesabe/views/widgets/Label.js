/**
 * Wraps an element containing optionally-formatted plain text.
 */
wesabe.$class('wesabe.views.widgets.Label', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    value: null,

    _formatter: null,
    _textElement: null,

    init: function(element, formatter) {
      if (!wesabe.isJQuery(element))
        formatter = element, element = null;

      if (!element)
        element = $('<label></label>');

      $super.init.call(this, element);
      this.value = element.text();
      this._formatter = formatter;
      this._textElement = element.find('.text-content');
      if (!this._textElement.length) this._textElement = element;

      this.addClassName('field-title');
    },

    setValue: function(value) {
      if (this.value === value)
        return;

      this.value = value;
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
      if (!field.get('id'))
        field.set('id', wesabe.uniqueId());
      this.get('element').attr('for', field.get('id'));
    },

    _redraw: function() {
      var textValue = this._formatter ? this._formatter.format(this.value) : this.value,
          extraValue;

      if ($.isArray(textValue))
        extraValue = textValue[1], textValue = textValue[0];

      this._textElement.text(textValue);
      if (extraValue)
        this._textElement.append($('<span></span>').text(extraValue));
    }
  });
});

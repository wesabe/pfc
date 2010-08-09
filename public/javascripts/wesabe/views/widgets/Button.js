/**
 * Wraps a.button elements, providing a "click" event and other conveniences.
 */
wesabe.$class('wesabe.views.widgets.Button', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  /** @const */ $class.COLORS = ['red', 'green', 'orange', 'blue'];
  /** @const */ $class.DISABLED_COLOR = 'gry';
  /** @const */ $class.SELECTED_CLASS = 'on';

  $.extend($class.prototype, {
    _enabled: true,
    _color: null,
    _text: null,
    _textElement: null,
    _value: null,

    init: function(element, value) {
      var me = this;

      $super.init.call(me, element);

      // read the existing text
      me._textElement = element.children('span');
      me._text = me._textElement.text();

      // set the value
      me._value = value;

      // figure out what color it should be
      for (var i = $class.COLORS.length; i--;) {
        if (element.hasClass($class.COLORS[i])) {
          me._color = $class.COLORS[i];
          break;
        }
      }

      // watch for clicks
      element.click(function(event){ me.onClick(event) });
    },

    /**
     * Handles click DOM events on the wrapped button element.
     *
     * @param {!event} event
     * @private
     */
    onClick: function(event) {
      // prevent "#" from sneaking into the url
      event.preventDefault();

      // don't do anything if we're disabled
      if (!this.isEnabled())
        return;

      // notify listeners of the click
      this.trigger('click');
    },

    /**
     * Returns true if this button responds to clicks, false otherwise.
     *
     * @return {boolean}
     */
    isEnabled: function() {
      return this._enabled;
    },

    /**
     * Sets whether or not this button responds to clicks, greying it out if
     * it is disabled.
     *
     * @param {!boolean} enabled
     */
    setEnabled: function(enabled) {
      if (this._enabled === enabled)
        return;

      this._enabled = enabled;
      if (this._color) {
        this.getElement()
          .addClass(enabled ? this._color : $class.DISABLED_COLOR)
          .removeClass(enabled ? $class.DISABLED_COLOR : this._color);
      }
    },

    /**
     * Returns true if this button is selected.
     *
     * @return {boolean}
     */
    isSelected: function() {
      return this.getElement().hasClass($class.SELECTED_CLASS);
    },

    /**
     * Sets whether or not this button is selected.
     *
     * @param {!boolean} selected
     */
    setSelected: function(selected) {
      if (this.isSelected() !== selected)
        this.getElement().toggleClass($class.SELECTED_CLASS);
    },

    /**
     * Gets the text of this button.
     *
     * @return {string}
     */
    getText: function() {
      return this._text;
    },

    /**
     * Sets the text of this button.
     *
     * @param {!string} text
     */
    setText: function(text) {
      if (this._text === text)
        return;

      this._text = text;
      this._textElement.text(text);
    },

    /**
     * Gets the value of the button. Used with {ButtonGroup}s to allow
     * referring to specific buttons by value rather than by reference.
     */
    getValue: function() {
      return this._value;
    },

    /**
     * Sets the value of the button.
     */
    setValue: function(value) {
      this._value = value;
    }
  });
});

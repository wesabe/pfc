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
    /**
     * Value of the button. Used with {ButtonGroup}s to allow
     * referring to specific buttons by value rather than by reference.
     */
    value: null,

    /**
     * Text of the button.
     *
     * @type {string}
     */
    text: null,

    /**
     * true if this button responds to clicks, false otherwise.
     *
     * @type {boolean}
     */
    enabled: true,

    /**
     * The color of this button. It can be one of {wesabe.views.widgets.Button.COLORS}.
     *
     * @type {string}
     */
    color: null,

    _textElement: null,

    init: function(element, value) {
      var me = this;

      if (!wesabe.isJQuery(element))
        value = element, element = null;

      if (!element)
        element = $('<a class="button green"><span></span></a>');

      $super.init.call(me, element);

      // read the existing text
      me._textElement = element.children('span');
      me.text = me._textElement.text();

      // set the value
      me.value = value;

      // figure out what color it should be
      for (var i = $class.COLORS.length; i--;) {
        if (element.hasClass($class.COLORS[i])) {
          me.color = $class.COLORS[i];
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
      if (!this.get('enabled'))
        return;

      // notify listeners of the click
      this.trigger('click');
    },

    /**
     * Sets whether or not this button responds to clicks, greying it out if
     * it is disabled.
     *
     * @param {!boolean} enabled
     */
    setEnabled: function(enabled) {
      if (this.enabled === enabled)
        return;

      this.enabled = enabled;
      if (this.color) {
        this.get('element')
          .addClass(enabled ? this.color : $class.DISABLED_COLOR)
          .removeClass(enabled ? $class.DISABLED_COLOR : this.color);
      }
    },

    setColor: function(color) {
      if (this.color === color)
        return;

      this.get('element')
        .removeClass(this.color)
        .addClass(color);
      this.color = color;
    },

    /**
     * Returns true if this button is selected.
     *
     * @return {boolean}
     */
    selected: function() {
      return this.get('element').hasClass($class.SELECTED_CLASS);
    },

    /**
     * Sets whether or not this button is selected.
     *
     * @param {!boolean} selected
     */
    setSelected: function(selected) {
      if (this.get('selected') !== selected)
        this.get('element').toggleClass($class.SELECTED_CLASS);
    },

    /**
     * Sets the text of this button.
     *
     * @param {!string} text
     */
    setText: function(text) {
      if (this.text === text)
        return;

      this.text = text;
      this._textElement.text(text);
    }
  });

  $.extend($class, {
    withText: function(text) {
      var button = new this();
      button.set('text', text);
      return button;
    }
  });
});

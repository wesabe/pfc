/**
 * Wraps a drop-down <select> element.
 */
wesabe.$class('wesabe.views.widgets.DropDownField', wesabe.views.widgets.BaseField, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    /**
     * Text to use as a placeholder/call to action for the user.
     *
     * @type {string}
     */
    placeholderText: null,

    /**
     * @private
     */
    _placeholderOption: null,

    init: function(element, delegate) {
      var me = this;

      if (!delegate) {
        if (element && wesabe.isJQuery(element)) {
          // got an element, just pass it along
        } else {
          // got a delegate
          delegate = element;
          element = null;
        }
      }

      if (!element)
        element = $('<select></select>');

      $super.init.call(me, element, delegate);
    },

    addOption: function(key, value) {
      this.get('element').append(new Option(key, value));
    },

    clearOptions: function() {
      var options = this.get('element').children();

      if (this._placeholderOption)
        options = options.not(this._placeholderOption);

      options.empty();
    },

    setPlaceholderText: function(placeholderText) {
      if (placeholderText == this.placeholderText)
        return;

      this.placeholderText = placeholderText;

      if (this.placeholderText && !this._placeholderOption) {
        this._placeholderOption = $(new Option('', ''));
        this.get('element').prepend(this._placeholderOption);
      }

      if (!this.placeholderText && this._placeholderOption)
        this._placeholderOption.remove();
      else
        this._placeholderOption.text(this.placeholderText);
    }
  });
});

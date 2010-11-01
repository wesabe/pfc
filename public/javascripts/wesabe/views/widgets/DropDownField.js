/**
 * Wraps a drop-down <select> element.
 */
wesabe.$class('wesabe.views.widgets.DropDownField', wesabe.views.widgets.BaseField, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _placeholderText: null,
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
      this.getElement().append(new Option(key, value));
    },

    clearOptions: function() {
      var options = this.getElement().children();

      if (this._placeholderOption)
        options = options.not(this._placeholderOption);

      options.empty();
    },

    getPlaceholderText: function() {
      return this._placeholderText;
    },

    setPlaceholderText: function(placeholderText) {
      if (placeholderText == this._placeholderText)
        return;

      this._placeholderText = placeholderText;

      if (this._placeholderText && !this._placeholderOption) {
        this._placeholderOption = $(new Option('', ''));
        this.getElement().prepend(this._placeholderOption);
      }

      if (!this._placeholderText && this._placeholderOption)
        this._placeholderOption.remove();
      else
        this._placeholderOption.text(this._placeholderText);
    }
  });
});

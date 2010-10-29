wesabe.$class('views.widgets.StateDropDownField', wesabe.views.widgets.BaseField, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _placeholderText: null,
    _placeholderOption: null,

    init: function(element, delegate) {
      var me = this;

      if (!delegate) {
        if (element && element.nodeName) {
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

      element.empty();

      var options = [],
          states = wesabe.data.states.get(),
          length = states.length;

      for (var i = 0; i < length; i++) {
        var state = states[i];
        options.push(new Option(state[0], state[1]));
      }

      element.append(options);

      this.setPlaceholderText('-- select state --');
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

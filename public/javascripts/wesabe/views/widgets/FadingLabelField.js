/**
 * Provides behavior for an input/label pair where the label is positioned
 * behind an input element with a transparent background.
 */
wesabe.$class('wesabe.views.widgets.FadingLabelField', wesabe.views.widgets.BaseField, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _label: null,

    init: function(element, labelElement, delegate) {
      $super.init.call(this, element, delegate);
      this._label = new wesabe.views.widgets.Label(labelElement);
      labelElement.bind('mousedown', function(){ return false });
      this.registerChildWidget(this._label);

      if (!this.isEmpty())
        this._label.setOpacity(0, /* animate = */false);
    },

    onChange: function() {
      if (!this.isEmpty())
        this._label.setOpacity(0, /* animate = */false);
    },

    onPollingChange: function() {
      this.onChange();
    },

    onFocus: function() {
      if (!this.isEmpty())
        return;

      this._label.setOpacity(0.4, true);
    },

    onBlur: function() {
      if (!this.isEmpty())
        return;

      this._label.setOpacity(1, true);
    },

    onKeyDown: function(event) {
      if (event.which == 9 /* tab */)
        return;

      this._label.setOpacity(0, true);
    }
  });
});
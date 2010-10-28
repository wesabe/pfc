/**
 * Provides behavior for an input/label pair where the label is positioned
 * behind an input element with a transparent background.
 */
wesabe.$class('wesabe.views.widgets.FadingLabelField', wesabe.views.widgets.BaseField, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _label: null,

    init: function() {
      var inputElement,
          label,
          delegate;

      for (var i = 0, length = arguments.length; i < length; i++) {
        var arg = arguments[i];

        if (wesabe.isJQuery(arg)) {
          if (!inputElement)
            inputElement = arg;
          else if (!label)
            label = new $package.Label(arg);
        } else if (arg.isInstanceOf && arg.isInstanceOf($package.Label)) {
          label = arg;
        } else if (typeof arg == 'string') {
          label = new $package.Label(arg);
        } else if (typeof arg == 'object') {
          delegate = arg;
        }
      }

      if (!inputElement)
        inputElement = $('<input type="text">');

      if (!label)
        label = new $package.Label();

      $super.init.call(this, inputElement, delegate);

      if (this.isAttached() && !label.isAttached())
        label.insertBefore(this);

      this._label = label;
      this._label.associateWithField(this);
      this.registerChildWidget(this._label);

      // allow selection in the input field
      label.getElement().bind('mousedown', function(){ return false });

      if (!this.isEmpty())
        this._label.setOpacity(0, /* animate = */false);
    },

    setLabelValue: function(value) {
      this._label.setValue(value);
    },

    setLabelFormatter: function(formatter) {
      this._label.setFormatter(formatter);
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
    },

    /**
     * @private
     */
    _didMoveToParent: function() {
      this._label.insertBefore(this);
    }
  });
});

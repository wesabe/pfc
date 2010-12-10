/**
 * Manages a group of toggle buttons where only one can be selected at a time.
 */
wesabe.$class('wesabe.views.widgets.ButtonGroup', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _buttons: null,
    _selectedButton: null,
    _delegate: null,

    init: function(buttons, delegate) {
      var self = this;
      this._delegate = delegate;

      this._buttons = [];
      var elements = [];
      for (var i = 0; i < buttons.length; i++) {
        var button = buttons[i];
        elements.push(button.get('element'));
        button.bind('click', function(){ self.onButtonClick(this) });
        this.registerChildWidget(button);
        this._buttons.push(button);
        if (button.get('selected'))
          this._selectedButton = button;
      }

      $super.init.call(this, elements);
    },

    onButtonClick: function(button) {
      this.selectButton(button);

      if (this._delegate && this._delegate.onSelectionChange)
        this._delegate.onSelectionChange(this, button);
    },

    getButton: function(index) {
      return this._buttons[index];
    },

    selectButton: function(button) {
      if (button === this._selectedButton)
        return;

      this._selectedButton = button;
      for (var i = this._buttons.length; i--; ) {
        var b = this._buttons[i];
        b.set('selected', b === button);
      }
    },

    selectButtonByValue: function(value) {
      for (var i = this._buttons.length; i--; ) {
        if (this._buttons[i].get('value') === value) {
          this.selectButton(this._buttons[i]);
          break;
        }
      }
    }
  });
});

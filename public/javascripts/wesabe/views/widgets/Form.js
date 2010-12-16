wesabe.$class('views.widgets.Form', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _enabled: true,

    _fields: null,

    init: function(element) {
      var me = this;

      if (!element)
        element = $('<form><fieldset><div class="two-col-centered"></div></fieldset></form>');

      $super.init.call(me, element);
      me.set('contentElement', element.find('> fieldset > div'));
      me._fields = [];
      element.bind('submit', function(event){ me.onSubmit(event) });
    },

    isEnabled: function() {
      return this._enabled;
    },

    setEnabled: function(enabled) {
      enabled = !!enabled;

      if (this._enabled === enabled)
        return;

      this._enabled = enabled;
      for (var i = 0, length = this._fields.length; i < length; i++) {
        var field = this._fields[i];
        field.setEnabled(enabled);
      }
    },

    onSubmit: function(event) {
      event.preventDefault();
      if (this._enabled)
        this.trigger('submit');
    },

    addField: function(field) {
      var lastField = this._fields[this._fields.length-1];
      this._fields.push(field);

      field.setEnabled(this._enabled);

      var wrapper = $('<div class="field"></div>');

      if (lastField)
        wrapper.insertAfter(lastField.get('element').parent());
      else
        this.prependElement(wrapper);

      field.appendTo(wrapper);
      this.registerChildWidget(field);
    },

    removeField: function(field) {
      this._fields = wesabe.lang.array.minus(this._fields, [field]);
      field.remove();
      this.unregisterChildWidget(field);
    },

    clearFields: function() {
      for (var field; field = this._fields.shift();)
        field.remove(), this.unregisterChildWidget(field);
    },

    getFieldValues: function() {
      var result = {};

      for (var i = 0, length = this._fields.length; i < length; i++) {
        var field = this._fields[i];
        result[field.get('name')] = field.get('name');
      }

      return result;
    },

    focus: function() {
      var firstField = this._fields[0];
      if (firstField) firstField.focus();
    }
  });
});

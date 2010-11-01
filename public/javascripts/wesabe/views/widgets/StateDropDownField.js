/**
 * Wraps a state drop-down <select> element.
 */
wesabe.$class('views.widgets.StateDropDownField', wesabe.views.widgets.DropDownField, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    init: function(element, delegate) {
      var me = this;

      $super.init.call(me, element, delegate);

      var states = wesabe.data.states.get(),
          length = states.length;

      for (var i = 0; i < length; i++) {
        var state = states[i];
        this.addOption(state[0], state[1]);
      }

      this.setPlaceholderText('-- select state --');
    }
  });
});

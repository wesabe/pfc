/**
 * Manages a list of states.
 */
wesabe.$class('data.states.StateSet', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _states: null,

    get: function() {
      return this._states;
    },

    set: function(data) {
      this._states = data;
      this.trigger('change', [this._states]);
    }
  });

  $.extend($package, {
    sharedStateSet: new $class(),

    get: function() {
      return $package.sharedStateSet.get();
    },

    set: function(data) {
      $package.sharedStateSet.set(data);
    }
  });
});

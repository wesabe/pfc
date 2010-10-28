/**
 * Manages a list of states.
 */
wesabe.$class('data.states.StateSet', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  wesabe.extend($class.prototype, {
    _states: null,

    get: function() {
      return this._states;
    },

    set: function(data) {
      this._states = data;
      this.trigger('change', [this._states]);
    },

    asOptions: function() {
      var options = [],
          states = $package.get(),
          length = states.length;

      for (var i = 0; i < length; i++) {
        var state = states[i];
        options.push(new Option(state[0], state[1]));
      }

      return options;
    }
  });

  wesabe.extend($package, {
    sharedStateSet: new $class(),

    get: function() {
      return $package.sharedStateSet.get();
    },

    set: function(data) {
      $package.sharedStateSet.set(data);
    },

    asOptions: function() {
      return $package.sharedStateSet.asOptions();
    }
  });
});

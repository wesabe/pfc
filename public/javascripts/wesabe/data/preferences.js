wesabe.provide('data.preferences', {
  get: function(key) {
    var value = $(this).kvo(key);
    switch (value) {
      case 'true': return true;
      case 'false': return false;
      default: return value;
    }
  },

  set: function(key, value) {
    if (typeof key == 'string') {
      $(this).kvo(key, value);
    } else if (key) {
      var kvpairs = key;
      for (key in kvpairs)
        this.set(key, kvpairs[key]);
    }
  },

  update: function(key, value) {
    // skip it if the value wouldn't change
    if (this.get(key) === value) return;

    var prefs = {};
    prefs[key] = value;
    this.set(key, value);
    $.put('/preferences', prefs);
  },

  hasFeature: function(feature) {
    var features = this.get('features');
    return features && features[feature];
  },

  // Special Cases

  getDefaultCurrency: function() {
    var defaultCurrency = this.get('default_currency');
    return defaultCurrency ? defaultCurrency.name : 'USD';
  }
});

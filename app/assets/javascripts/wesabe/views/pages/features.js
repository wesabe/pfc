(function($) {
  wesabe.features = {
    FEATURES: {},

    each: function(callback) {
      $.each(wesabe.features.FEATURES, callback);
    },

    eachFeatureToggle: function(callback) {
      wesabe.features.each(function(feature, enabled) {
        var element = $('.feature-toggle.'+feature);
        callback.call(element, element, feature, enabled);
      });
    },

    isEnabled: function(feature) {
      return wesabe.features.FEATURES[feature] == true;
    },

    enable: function(feature) {
      if (!wesabe.features.isEnabled(feature))
        wesabe.features.toggle(feature);
    },

    disable: function(feature) {
      if (wesabe.features.isEnabled(feature))
        wesabe.features.toggle(feature);
    },

    toggle: function(feature) {
      wesabe.features.updateData(feature, !wesabe.features.isEnabled(feature));
      wesabe.features.updateDisplay();
    },

    updateData: function(feature, enabled) {
      wesabe.features.FEATURES[feature] = enabled;
      $.put('/labs/'+feature, { enabled: enabled });
    },

    updateDisplay: function() {
      wesabe.features.eachFeatureToggle(function(element, feature, enabled) {
        element
          .find("div."+(enabled?"cancel":"signup"))
            .show()
          .end()
          .find("div."+(enabled?"signup":"cancel"))
            .hide()
          .end()
          .show();
      });
    }
  };

  $(function() {
    wesabe.features.updateDisplay();
    wesabe.features.eachFeatureToggle(function(element, feature, enabled) {
      element
        .find('.signup a, .cancel a')
        .click(function() { wesabe.features.toggle(feature); return false; });
    });
    $("table tr:even").addClass("even");
  });
})(jQuery);

/**
 * CLASS DESCRIPTION
 */
wesabe.$class('<%= name %>', <%= "#{superclass_name}, " if superclass_name %>function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    // INSTANCE VARIABLES
    // data: null,

    init: function(element) {
      <%- if has_superclass? %>
      $super.init.call(this, element);

      <%- end %>
      // CLASS INSTANCE SETUP
    }

    // INSTANCE METHODS
    // value: function() {
    //   ...
    // }
  });
});

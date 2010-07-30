/**
 * CLASS DESCRIPTION
 */
wesabe.$class('<%= name %>', <%= superclass_name || 'null' %>, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    // INSTANCE VARIABLES
    // _data: null,

    init: function(element) {
      <%- if has_superclass? %>
      $super.init.call(this, element);

      <%- end %>
      // CLASS INSTANCE SETUP
    }

    // INSTANCE METHODS
    // getData: function() {
    //   return this._data;
    // },
    //
    // setData: function(data) {
    //   this._data = data;
    // }
  });
});

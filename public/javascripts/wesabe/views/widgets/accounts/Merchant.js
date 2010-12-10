/**
 * Provides selection support for merchants.
 */
wesabe.$class('wesabe.views.widgets.accounts.Merchant', function($class, $super, $package) {
  $.extend($class.prototype, {
    /**
     * The name of the merchant (e.g. "Starbucks").
     */
    name: null,

    init: function(name) {
      this.name = name;
    },

    /**
     * Gets the URI for this {Merchant} (e.g. "/merchants/Starbucks").
     *
     * See {wesabe.views.pages.accounts#storeState}.
     */
    uri: function() {
      return '/merchants/'+this.get('name');
    },

    /**
     * Gets the URL parameters for this {Merchant}.
     *
     * See {wesabe.views.pages.accounts#paramsForCurrentSelection}.
     */
    toParams: function() {
      return [{name: 'merchant', value: this.get('name')}];
    },

    /**
     * Returns true if {other} is a {Merchant} and has the same name.
     */
    isEqualTo: function(other) {
      return other && other.isInstanceOf($class) && (this.get('name') === other.get('name'));
    }
  });
});

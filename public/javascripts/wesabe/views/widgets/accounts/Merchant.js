/**
 * Provides selection support for merchants.
 */
wesabe.$class('wesabe.views.widgets.accounts.Merchant', null, function($class, $super, $package) {
  $.extend($class.prototype, {
    _name: null,

    init: function(name) {
      this._name = name;
    },

    /**
     * Gets the name of the merchant (e.g. "Starbucks").
     */
    getName: function() {
      return this._name;
    },

    /**
     * Gets the URI for this {Merchant} (e.g. "/merchants/Starbucks").
     *
     * See {wesabe.views.pages.accounts#storeState}.
     */
    getURI: function() {
      return '/merchants/'+this.getName();
    },

    /**
     * Gets the URL parameters for this {Merchant}.
     *
     * See {wesabe.views.pages.accounts#paramsForCurrentSelection}.
     */
    toParams: function() {
      return [{name: 'merchant', value: this.getName()}];
    },

    /**
     * Returns true if {other} is a {Merchant} and has the same name.
     */
    isEqualTo: function(other) {
      return other && other.isInstanceOf($class) && (this.getName() === other.getName());
    }
  });
});

/**
 * Represents a request for data of a particular type.
 */
wesabe.$class('wesabe.data.Query', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _type: null,
    _options: null,

    init: function(type, options) {
      this._type = type;
      this._options = options || {};
    },

    getType: function() {
      return this._type;
    },

    wantsSpecificRecords: function() {
      return this.getIds().length > 0;
    },

    getIds: function() {
      var ids = this._options.id;

      if (!ids)
        return [];

      if (!$.isArray(ids))
        return [ids];

      return ids;
    },

    shouldFetchAssociation: function(associationName) {
      var includedAssociations = this._options.include;

      if (!includedAssociations)
        return false;

      if (includedAssociations == '*')
        return true;

      if (!$.isArray(includedAssociations))
        return includedAssociations == associationName;

      return wesabe.lang.array(includedAssociations, associationName);
    }
  });
});

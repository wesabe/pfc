/**
 * Provides access to tag data over specific time ranges.
 */
wesabe.$class('wesabe.data.tags.TagDataSource',
  wesabe.data.BaseDataSource.dataSourceWithURI(function(){ return '/data/analytics/summaries/tags/all/' + wesabe.data.preferences.getDefaultCurrency(); }),
  function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _tagNames: null,

    /**
     * Called when the data changes.
     *
     * @private
     */
    onDataChanged: function() {
      $super.onDataChanged.call(this);
      this._tagNames = null;
    },

    /**
     * Returns a list of names of the tags in this data source.
     */
    getTagNames: function() {
      // if it's cached, return a copy of the cache
      if (this._tagNames)
        return this._tagNames.concat();

      if (!this.hasData())
        return [];

      var result = [],
          summaries = this.getData().summaries,
          length = summaries.length;

      while (length--)
        result[length] = summaries[length].tag.name;

      // cache a copy
      this._tagNames = result.concat();
      return result;
    }
  });
  $package.sharedDataSource = new $class();
});

/**
 * Wraps an input field and applies a YUI autocompleter to autocomplete tags.
 */
wesabe.$class('wesabe.views.widgets.tags.TagAutocompleterField', wesabe.views.widgets.AutocompleterField, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.number
  var number = wesabe.lang.number;

  $.extend($class.prototype, {
    _tagDataSource: null,

    /**
     * Gets the total amount avaialble to autocomplete with splits. If the
     * value is +null+, splits will not be autocompleted.
     *
     * @type {number}
     */
    splitAutocompletionTotal: null,

    init: function(element, tagDataSource) {
      $super.init.call(this, element);

      var me = this;
      me._tagDataSource = tagDataSource || wesabe.data.tags.sharedDataSource;
      me._tagDataSource.requestDataAndSubscribe({
        change: function() {
          me.onTagsChanged();
        }
      });
    },

    /**
     * Gets a wrapper element for the autocompleter.
     *
     * @return {jQuery}
     */
    wrapperElement: function() {
      return $super.wrapperElement.call(this)
        .addClass('tag-autocomplete');
    },

    /**
     * Called when the tag data has changed.
     */
    onTagsChanged: function() {
      this._refreshCompletions();
    },

    onKeyUp: function() {
      $super.onKeyUp.apply(this, arguments);

      // parse the tags entered already and remove them from the completions
      this._refreshCompletions();

      if (this._lastKeyPressKeyCode != 58 /* : (colon) */)
        return;

      var total = this.get('splitAutocompletionTotal');
      if (!total)
        return;

      total = Math.abs(total);
      var remainder = total,
          sel = this.get('element').caret(),
          value = this.get('value'),
          before = value.substring(0, sel.begin).replace(/\s*:$/, ':'), // remove any spaces between the colon and the amount
          after = value.substring(sel.end, value.length),
          taglist = wesabe.data.tags.parseTagString(this.get('value'));

      while (taglist.length) {
        var tag = taglist.shift();
        if (tag.amount) {
          // ensure percents are converted to absolute numbers before parsing the amount
          tag.amount = tag.amount.replace(/([\d\.]+%)/g, function(all, pct) {
            return number.parse(pct) * total;
          });
          remainder -= number.parse(tag.amount);
        }
      }

      remainder = Math.max(remainder, 0);
      remainder = Math.round(remainder * 100) / 100;
      remainder = (remainder == 0 || isNaN(remainder)) ? '' : remainder.toString();

      this.set('value', before+remainder+after);
      this.get('element').caret(before.length, before.length+remainder.length);
      this._lastKeyPressKeyCode = null;
    },

    /**
     * Refresh the list of available completions.
     *
     * @private
     */
    _refreshCompletions: function() {
      var allTagNames = this._tagDataSource.get('tagNames');
      var enteredTags = wesabe.data.tags.parseTagString(this.get('value'));
      var enteredTagNames = [];

      for (var i = enteredTags.length; i--; ) {
        enteredTagNames.push(enteredTags[i].name);
      }

      this.set('completions', wesabe.lang.array.minus(allTagNames, enteredTagNames));
    }
  });
});

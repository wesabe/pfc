/**
 * Wraps the filtered tag editor in the tags widget, and is a long-lived
 * singleton instance.
 */
wesabe.$class('wesabe.views.widgets.tags.FilteredTagsEditDialog', wesabe.views.widgets.Dialog, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _originalValue: null,
    _tagEditField: null,

    init: function(element, tagDataSource) {
      var me = this;

      $super.init.call(me, element);

      me._tagEditField = new wesabe.views.widgets.tags.TagAutocompleterField(
       element.find('input[name=filter-tags]'),
       tagDataSource
      );

      // read the original value from the input element
      me._originalValue = me.get('value');
    },

    /**
     * Shows this dialog and focuses the filtered tags field.
     */
    show: function() {
      var field = this._tagEditField;
      $super.show.call(this, function() {
        field.selectAllAndFocus();
      });
    },

    /**
     * Hides this dialog and resets the value of the filtered tags input.
     */
    hide: function() {
      var me = this;
      $super.hide.call(this, function(){ me.resetValue() });
    },

    /**
     * Gets the text value of the filtered tags field.
     *
     * @return {string}
     */
    value: function() {
      return this._tagEditField.get('value');
    },

    /**
     * Sets the text value of the filtered tags field.
     *
     * @param {!string}
     */
    setValue: function(value) {
      this._tagEditField.set('value', value);
    },

    /**
     * Resets the value of the filtered tags input element to what it was
     * before the user edited it.
     */
    resetValue: function() {
      this.set('value', this._originalValue);
    },

    onConfirm: function() {
      var me = this;

      $.ajax({
        url: '/user/edit_filter_tags',
        type: 'POST',
        data: {filter_tags: me.get('value')},
        dataType: 'json',
        success: function(data, textStatus) {
          me._originalValue = data.join(' ');
          me.hide();
        },
        error: function(XMLHttpRequest, textStatus, errorThrown) {
          alert("Sorry, there was an error changing your filtered tags.");
        }
      });
    }
  });
});

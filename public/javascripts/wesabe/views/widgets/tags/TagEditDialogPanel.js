/**
 * Wraps a panel in the {TagEditDialog}.
 */
wesabe.$class('wesabe.views.widgets.tags.TagEditDialogPanel', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  $.extend($class.prototype, {
    _tagEditDialog: null,
    _confirmButton: null,
    _cancelButton: null,
    _tagNameLabel: null,
    _newTagsLabel: null,
    _tags: null,
    _enabled: true,

    init: function(element, tagEditDialog) {
      $super.init.call(this, element);

      var me = this;

      me._tagEditDialog = tagEditDialog;

      me._confirmButton = new wesabe.views.widgets.Button(element.find('.confirm.button'));
      me._cancelButton = new wesabe.views.widgets.Button(element.find('.cancel.button'));

      me._tagNameLabel = element.find('.tag-name');
      me._newTagsLabel = element.find('.tag-name.new');
    },

    onBeginEdit: function(tagListItem) {
      this._tagNameLabel.text('“'+tagListItem.getName()+'”');
    },

    onEndEdit: function() {
      // nothing to do
    },

    isEnabled: function() {
      return this._enabled;
    },

    setEnabled: function(enabled) {
      if (this._enabled === enabled)
        return;

      this._enabled = enabled;
      this._confirmButton.setEnabled(enabled);
    },

    animateVisible: function(visible, callback) {
      var me = this;

      if (visible !== me.isVisible())
        me.getElement().slideToggle(function() {
          me.setVisible(visible)
          callback && callback();
        });
    },

    getTags: function() {
      return this._tags;
    },

    setTags: function(newTags) {
      this._tags = newTags;

      if (this._newTagsLabel.length) {
        var newTagsString = "",
            length = newTags.length;

        for (var i = 0; i < length; i++) {
          newTagsString += '“'+newTags[i].name+'”';
          if (i < (newTags.length-2)) {
            newTagsString += ', ';
          } else if (i == (newTags.length-2)) {
            newTagsString += ' and ';
          }
        }

        this._newTagsLabel.text(newTagsString);
      }
    },

    setConfirmButtonText: function(text) {
      this._confirmButton.setText(text);
    }
  });
});

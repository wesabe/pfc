/**
 * Wraps a panel in the {TagEditDialog}.
 */
wesabe.$class('wesabe.views.widgets.tags.TagEditDialogPanel', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  $.extend($class.prototype, {
    enabled: true,
    tags: null,

    _tagEditDialog: null,
    _confirmButton: null,
    _cancelButton: null,
    _tagNameLabel: null,
    _newTagsLabel: null,

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
      this._tagNameLabel.text('“'+tagListItem.get('name')+'”');
    },

    onEndEdit: function() {
      // nothing to do
    },

    setEnabled: function(enabled) {
      if (this.enabled === enabled)
        return;

      this.enabled = enabled;
      this._confirmButton.set('enabled', enabled);
    },

    animateVisible: function(visible, callback) {
      var me = this;

      if (visible !== me.get('visible'))
        me.get('element').slideToggle(function() {
          me.set('visible', visible);
          callback && callback();
        });
    },

    setTags: function(newTags) {
      this.tags = newTags;

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
      this._confirmButton.set('text', text);
    }
  });
});

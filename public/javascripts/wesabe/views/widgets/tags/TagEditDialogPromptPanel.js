/**
 * Panel that includes a text field to allow the user to rename/merge tags.
 */
wesabe.$class('wesabe.views.widgets.tags.TagEditDialogPromptPanel', wesabe.views.widgets.tags.TagEditDialogPanel, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.data.tags
  var tags = wesabe.data.tags;

  $.extend($class.prototype, {
    _deleteButton: null,
    _tagNameField: null,
    _tagDataSource: null,
    _originalTag: null,

    init: function(element, tagEditDialog, tagDataSource) {
      var me = this;

      $super.init.apply(me, arguments);
      me._tagEditDialog = tagEditDialog;
      me._tagDataSource = tagDataSource;

      // keep pressing enter from submitting the form that only exists to make the widget validate
      element.find('form').bind('submit', function(event){ event.preventDefault() });

      me._tagNameField = new $package.TagAutocompleterField(element.find('input[name=tag-name]'));
      me._deleteButton = element.find('.delete.button');
      me._deleteButton.click(function(){ me.onDelete() });
    },

    getTags: function() {
      return tags.parseTagString(this.getTagString());
    },

    setTags: function(list) {
      $super.setTags.apply(this, arguments);
      this._tagNameField.setValue(tags.joinTags(list));
    },

    getTagString: function() {
      return this._tagNameField.getValue();
    },

    onBeginEdit: function(tagListItem) {
      var me = this;

      // hang on to the original tag
      me._originalTag = {name: tagListItem.getName()};

      // Editing "foo"
      me._tagNameLabel.text('“' + me._originalTag.name + '”');

      // watch for tag changes
      me._tagNameField.getElement().bind('keyup.tedpp', function(event){ me.onKeyUp(event) });

      // set the prompt value
      me.setTags([me._originalTag]);
    },

    onEndEdit: function() {
      this._tagNameField.getElement().unbind('keyup.tedpp');
    },

    onKeyUp: function(event) {
      if (!tags.listsEqual(this._tags || [], this.getTags()))
        this._tagEditDialog.onTagsChanged(this);
    },

    setEnabled: function(enabled) {
      if (this.isEnabled() === enabled)
        return;

      $super.setEnabled.call(this, enabled);
      this._deleteButton.setEnabled(enabled);
    },

    onDelete: function() {
      if (!this.isEnabled())
        return;

      this._tagEditDialog.onDelete(this);
    },

    isDirty: function() {
      return !tags.listsEqual(this.getTags(), [this._originalTag]);
    },

    setVisible: function(visible) {
      var field = this._tagNameField;

      $super.setVisible.apply(this, arguments);
      setTimeout(function(){ visible ? field.focus() : field.blur() }, 50);
    },

    animateVisible: function(visible, callback) {
      var me = this;

      $super.animateVisible.call(me, visible, function() {
        me.setVisible(visible);
        callback && callback();
      });
    }
  });
});

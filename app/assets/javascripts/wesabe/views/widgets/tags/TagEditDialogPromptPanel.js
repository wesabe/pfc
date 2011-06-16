/**
 * Panel that includes a text field to allow the user to rename/merge tags.
 */
wesabe.$class('wesabe.views.widgets.tags.TagEditDialogPromptPanel', wesabe.views.widgets.tags.TagEditDialogPanel, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.data.tags
  var tags = wesabe.data.tags;

  $.extend($class.prototype, {
    /**
     * Stores the original (unedited) version of the tag.
     *
     * @private
     */
    _originalTag: null,

    _deleteButton: null,
    _tagNameField: null,
    _tagDataSource: null,

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

    tags: function() {
      return tags.parseTagString(this.get('tagString'));
    },

    setTags: function(list) {
      $super.setTags.apply(this, arguments);
      this._tagNameField.set('value', tags.joinTags(list));
    },

    tagString: function() {
      return this._tagNameField.get('value');
    },

    onBeginEdit: function(tagListItem) {
      var me = this;

      // hang on to the original tag
      me.set('originalTag', {name: tagListItem.get('name')});

      // Editing "foo"
      me._tagNameLabel.text('“' + me.get('originalTag').name + '”');

      // watch for tag changes
      me._tagNameField.get('element').bind('keyup.tedpp', function(event){ me.onKeyUp(event) });

      // set the prompt value
      me.set('tags', [me.get('originalTag')]);
    },

    onEndEdit: function() {
      this._tagNameField.get('element').unbind('keyup.tedpp');
    },

    onKeyUp: function(event) {
      if (!tags.listsEqual(this._tags || [], this.get('tags')))
        this._tagEditDialog.onTagsChanged(this);
    },

    setEnabled: function(enabled) {
      if (this.get('enabled') === enabled)
        return;

      $super.setEnabled.call(this, enabled);
      this._deleteButton.set('enabled', enabled);
    },

    onDelete: function() {
      if (!this.get('enabled'))
        return;

      this._tagEditDialog.onDelete(this);
    },

    isDirty: function() {
      return !tags.listsEqual(this.get('tags'), [this.get('originalTag')]);
    },

    setVisible: function(visible) {
      var field = this._tagNameField;

      $super.setVisible.apply(this, arguments);
      setTimeout(function(){ visible ? field.focus() : field.blur() }, 50);
    },

    animateVisible: function(visible, callback) {
      var me = this;

      $super.animateVisible.call(me, visible, function() {
        me.set('visible', visible);
        callback && callback();
      });
    }
  });
});

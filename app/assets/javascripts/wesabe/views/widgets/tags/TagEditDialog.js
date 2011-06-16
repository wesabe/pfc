wesabe.$class('wesabe.views.widgets.tags.TagEditDialog', wesabe.views.widgets.Dialog, function($class, $super, $package) {
  $.extend($class.prototype, {
    _editPanel: null,
    _renamePanel: null,
    _deletePanel: null,
    _mergePanel: null,
    _panels: null,
    _currentPanel: null,
    _tagDataSource: null,

    init: function(element, tagDataSource) {
      var me = this;

      $super.init.call(me, element);
      me._tagDataSource = tagDataSource;
      me._editPanel   = new $package.TagEditDialogPromptPanel(element.find('.edit-panel'), me, me._tagDataSource);
      me._renamePanel = new $package.TagEditDialogPanel(element.find('.rename-panel'), me);
      me._mergePanel  = new $package.TagEditDialogPanel(element.find('.merge-panel'), me);
      me._deletePanel = new $package.TagEditDialogPanel(element.find('.delete-panel'), me);
      me._panels = [me._editPanel, me._renamePanel, me._deletePanel, me._mergePanel];

      me.registerChildWidgets.apply(me, me._panels);
    },

    onTagsChanged: function(tagEditDialogPromptPanel) {
      if (!tagEditDialogPromptPanel.get('tags').length) {
        this.set('buttonsDisabled', true);
      } else {
        this.set('buttonsDisabled', false);

        tagEditDialogPromptPanel.set('confirmButtonText',
          !tagEditDialogPromptPanel.isDirty() ? 'Save' :
                               this.isMerge() ? 'Merge…' :
                                                'Rename…');
      }
    },

    onBeginEdit: function(tagListItem) {
      var me = this;

      me._tagListItem = tagListItem;

      // set the initial visibility
      me._showPanel(me._editPanel);

      // Move to line up witht he tag's edit button
      me.get('element').css('top', tagListItem.get('element').offset().top-140)
      // show the edit dialog
      me.show(function() {
        // Focus on the input after fading in
        me._editPanel.set('visible', true);
      });

      var panels = me._panels,
          length = panels.length;

      while (length--)
        panels[length].onBeginEdit(tagListItem);
    },

    onEndEdit: function() {
      delete this._tagListItem;

      var panels = this._panels,
          length = panels.length;

      while (length--)
        panels[length].onEndEdit();
    },

    onDelete: function(senderPanel) {
      if (senderPanel === this._editPanel)
        this._animatePanel(this._deletePanel);
    },

    _showPanel: function(panel, animate) {
      if (panel === this._currentPanel)
        return;

      var panels = this._panels,
          length = panels.length;

      while (length--) {
        var p = panels[length];
        if (panel !== p) {
          animate ? p.animateVisible(false) : p.set('visible', false);
        } else {
          p.set('tags', this.get('tags'));
          this.set('buttonsDisabled', false);
          animate ? p.animateVisible(true) : p.set('visible', true);
        }
      }

      this._currentPanel = panel;
    },

    _animatePanel: function(panel) {
      this._showPanel(panel, true);
    },

    saveTag: function() {
      var me = this;

      $.ajax({
        type: 'PUT',
        url: me._tagListItem.get('uri'),
        data: { replacement_tags: me.get('tagString') },
        beforeSend: function () {
          me.set('buttonsDisabled', true);
        },
        success: function() {
          me._tagDataSource.requestData();
        },
        error: function(XMLHttpRequest, textStatus, errorThrown) {
          alert("Tag could not be saved: " + XMLHttpRequest.responseText);
        },
        complete: function() { me.hide(); }
      });
    },

    destroyTag: function() {
      var me = this;

      $.ajax({
        type: 'DELETE',
        url: me._tagListItem.get('uri'),
        data: '_=', // NOTE: fixes a possible Rails bug (nil.attributes when doing DELETE)
        beforeSend: function () {
          me.set('buttonsDisabled', true);
        },
        success: function() {
          me._tagDataSource.requestData();
        },
        error: function(XMLHttpRequest, textStatus, errorThrown) {
          alert("Tag could not be deleted: " + XMLHttpRequest.responseText);
        },
        complete: function() { me.hide(); }
      });
    },

    hide: function() {
      this.onEndEdit();
      $super.hide.apply(this, arguments);
    },

    /**
     * Called on enter by {Dialog} when this dialog is the first responder.
     */
    onConfirm: function() {
      var currentPanel = this._currentPanel;

      if (currentPanel === this._deletePanel) {
        this.destroyTag();
      } else if (currentPanel === this._editPanel) {
        if (!currentPanel.isDirty()) {
          this.hide();
        } else if (this.isMerge()) {
          this._animatePanel(this._mergePanel);
        } else {
          this._animatePanel(this._renamePanel);
        }
      } else {
        this.saveTag();
      }
    },

    /**
     * Called on escape by {Dialog} when this dialog is the first responder.
     */
    onCancel: function() {
      if (this._currentPanel !== this._editPanel) {
        this._animatePanel(this._editPanel);
      } else {
        this.hide();
      }
    },

    // Tag edit box helper functions

    isMerge: function() {
      if (!this.isDirty())
        return false;

      var newTags = this.get('tags'),
          newTagsLength = newTags.length,
          summaries = this._tagDataSource.get('data').summaries,
          summariesLength = summaries.length;

      // it's not a merge if there are no new tags
      if (!newTags.length) return false;

      // it's a merge if all new tags are in the old set
      for (var i = newTagsLength; i--; ) {
        var found = false;

        for (var j = summariesLength; j--; ) {
          if (summaries[j].tag.name == newTags[i].name) {
            found = true;
            break;
          }
        }

        if (!found) return false;
      }

      return true;
    },

    isDirty: function() {
      return this._editPanel.isDirty();
    },

    tags: function() {
      return this._editPanel.get('tags');
    },

    tagString: function() {
      return this._editPanel.get('tagString');
    }
  });
});

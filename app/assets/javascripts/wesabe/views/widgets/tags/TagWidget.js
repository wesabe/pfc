/**
 * Wraps the <div id="tags"> element containing the list of tags on the page.
 * Manages a {TagList} and handles toggling edit mode. Tag selection is
 * handled by the {TagList}.
 *
 * NOTE: This is intended to be a long-lived singleton and therefore does not
 * have any sort of cleanup function.
 */
wesabe.$class('wesabe.views.widgets.tags.TagWidget', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.data.preferences as prefs
  var prefs = wesabe.data.preferences
  // import wesabe.lang.array
  var array = wesabe.lang.array
  // import wesabe.lang.number
  var number = wesabe.lang.number

  $.extend($class.prototype, {
    /**
     * The current style (i.e. either "cloud" or "list").
     */
    style: null,

    /**
     * The child {TagList} of this widget.
     */
    tagList: null,

    _noTagsLabel: null,
    _tagDataSource: null,
    _styleButtons: null,
    _editButton: null,
    _doneButton: null,
    _hasDoneInitialLoad: false,

    init: function(element, tagDataSource) {
      var me = this;

      $super.init.call(me, element);
      me._tagDataSource = tagDataSource;

      me._styleButtons = element.find('.module-header .cloud.toggle, .module-header .list.toggle');
      me._styleButtons.click(function(event){ me.onStyleButtonClick(event) });

      var filteredTagsEditDialog = new wesabe.views.widgets.tags.FilteredTagsEditDialog($('#filter-tags-edit .hover-box'), wesabe.data.tags.sharedDataSource);
      me._filteredTagsButton = element.find("#filtered-tags-button").click(function(){filteredTagsEditDialog.toggle();});

      me._editButton = element.find(".module-header .edit-tags");
      me._editButton.click(function(){ me.set('editModeEnabled', true) });

      me._doneButton = element.find(".module-header .done-tags");
      me._doneButton.click(function(){ me.set('editModeEnabled', false) });

      me.set('tagList', new $package.TagList(element.find('.content ul.tags'), new wesabe.util.Selection(), me.get('editDialog')));
      me.registerChildWidget(me.get('tagList'));

      me._noTagsLabel = new wesabe.views.widgets.Label(element.find('.no-tags-label'));
      me.registerChildWidget(me._noTagsLabel);

      me._tagDataSource.requestDataAndSubscribe({
        change: function(tags) {
          me.onTagsChanged(tags);
        },

        error: function() {
          me.onTagsError();
        }
      });

      me._restoreStyleFromPrefs();
    },

    /**
     * Returns a boolean indicating whether this widget has done at least
     * one painting of the tags.
     */
    hasDoneInitialLoad: function() {
      return this._hasDoneInitialLoad;
    },

    /**
     * Returns the {wesabe.util.Selection} associated with this {TagWidget}.
     */
    selection: function() {
      return this.getPath('tagList.selection');
    },

    /**
     * Sets the {wesabe.util.Selection} associated with this {TagWidget}.
     */
    setSelection: function(selection) {
      this.setPath('tagList.selection', selection);
    },

    /**
     * NOTE: This does not update the user's preferences.
     */
    setStyle: function(newStyle) {
      var oldStyle = this.style;
      if (newStyle === oldStyle)
        return;

      this.style = newStyle;
      this.onStyleChanged(newStyle, oldStyle);
    },

    /**
     * The objects that may be selected in this {TagWidget}.
     *
     * See {wesabe.views.pages.accounts#reloadState}.
     */
    selectableObjects: function() {
      return this.getPath('tagList.items');
    },

    /**
     * Handles clicks on the "cloud" and "list" style buttons.
     *
     * Since this is a direct result of user action, this function does
     * update the user's preferences.
     */
    onStyleButtonClick: function(event) {
      var style = $(event.target).is('.list') ? 'list' : 'cloud';
      prefs.update('tag_cloud', (style == 'cloud'));
      this.set('style', style);
    },

    /**
     * Restores the current style to whatever the user's preferences indicate.
     *
     * @private
     */
    _restoreStyleFromPrefs: function () {
      this.set('style', prefs.get('tag_cloud') ? 'cloud' : 'list');
    },

    /**
     * Handles changes to the current style of this {TagWidget}.
     */
    onStyleChanged: function(newStyle, oldStyle) {
      this._styleButtons.filter('.'+newStyle).addClass('on');
      this._styleButtons.filter(':not(.'+newStyle+')').removeClass('on');
      this.setPath('tagList.style', newStyle);
    },

    /**
     * Ensures that the tag data is loaded from the server.
     */
    loadData: function() {
      this._tagDataSource.requestDataUnlessHasData();
    },

    /**
     * Handles changes to the underlying tag data.
     */
    onTagsChanged: function(data) {
      this.update(data);
      this.onStyleChanged(this.get('style'));
      this._hasDoneInitialLoad = true;
      this.trigger('loaded');
    },

    /**
     * Handles errors while loading the tag data.
     */
    onTagsError: function() {
      wesabe.error("Something went wrong loading your tags. Sorry.");
    },

    /**
     * Updates the DOM using the new tag data.
     */
    update: function(data) {
      this._noTagsLabel.set('visible', data.summaries.length == 0);

      // do some preprocessing to sort the data and generate useful stats
      data.summaries = array.caseInsensitiveSort(data.summaries,
        function(summary){ return summary.tag.name });

      var maxSpent = 0, maxEarned = 0;
      var maxSpentCount = 0, maxEarnedCount = 0;

      $.each(data.summaries, function(i, s) {
        s.spending.value = number.parse(s.spending.value);
        s.earnings.value = number.parse(s.earnings.value);
        s.net.value      = number.parse(s.net.value);

        if (s.spending.value > maxSpent) maxSpent = s.spending.value;
        if (s.earnings.value > maxEarned) maxEarned = s.earnings.value;
        if (s.spending.count > maxSpentCount) maxSpentCount = s.spending.count;
        if (s.earnings.count > maxEarnedCount) maxEarnedCount = s.earnings.count;
      });

      $.each(data.summaries, function(i, s) {
        if (s.net.value > 0) {
          s.percent = 0.75 * (s.net.value / maxEarned + s.net.count / maxEarnedCount) / 2;
        } else {
          s.percent = (-s.net.value / maxSpent + s.net.count / maxSpentCount) / 2;
        }
      });

      this.get('tagList').update(data.summaries);
    },

    /**
     * Lazy-load the {TagEditDialog} for this tag list since editing is so rare.
     */
    editDialog: function() {
      if (!this._editDialog)
        this._editDialog = new $package.TagEditDialog(this.get('element').children('.edit-dialog'), this._tagDataSource);

      return this._editDialog;
    },

    selectTag: function(tagURI) {
      // REVIEW: totally unsure if this should be in tagList or not
      var tagListItems = this.getPath('tagList.items'),
          length = tagListItems.length;

      while (length--) {
        if (tagListItems[length].get('uri') == tagURI) {
          tagListItems[length].select();
          break;
        }
      }
    },

    /**
     * Enables or disables edit mode.
     */
    setEditModeEnabled: function(enabled) {
      if (enabled) {
        this.set('style', 'list');
        this.get('element').addClass("editing");
      } else {
        this.get('editDialog').hide();
        this._restoreStyleFromPrefs();
        this.get('element').removeClass("editing");
      }
    }
  });
});

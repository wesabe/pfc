/**
 * Wraps the <ul> of tags, manages {TagListItem} instances, and handles most
 * DOM events for them (google "event delegation").
 *
 * NOTE: This is intended to be a long-lived singleton and therefore does not
 * have any sort of cleanup function.
 */
wesabe.$class('wesabe.views.widgets.tags.TagList', wesabe.views.widgets.BaseListWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.array
  var array = wesabe.lang.array;

  $.extend($class.prototype, {
    _selection: null,
    _editDialog: null,
    _template: null,
    _style: null,

    init: function(element, selection, editDialog) {
      $super.init.call(this, element);

      var me = this;

      me._selection = selection;
      me._editDialog = editDialog;
      // extract the template element
      var template = element.children('li.template');
      me._template = template.clone().removeClass('template');
      template.remove();

      // register a delegating click handler
      element.click(function(event){ me.onClick(event) });

      // use zebra striping
      me.setStripingEnabled(true);
    },

    /**
     * Gets the current style (i.e. either "cloud" or "list").
     */
    getStyle: function() {
      return this._style;
    },

    /**
     * Sets the current style to either "cloud" or "list".
     *
     * NOTE: This does not update the user's preferences.
     */
    setStyle: function(newStyle) {
      var oldStyle = this._style;
      if (newStyle !== oldStyle) {
        this._style = newStyle;
        this.onStyleChanged(newStyle, oldStyle);
      }
    },

    /**
     * Handles changes to the current style of this {TagList}.
     */
    onStyleChanged: function(newStyle, oldStyle) {
      this.getElement().addClass(newStyle)
      if (oldStyle) this.getElement().removeClass(oldStyle);

      if (newStyle === 'list') {
        this.getElement().add(this.getElement().parent())
          .removeClass('one-col-list-off')
          .addClass('one-col-list');
      } else {
        this.getElement().add(this.getElement().parent())
          .removeClass('one-col-list')
          .addClass('one-col-list-off');
      }

      var items = this.getItems(),
          length = items.length;

      while (length--)
        items[length].onStyleChanged(newStyle, oldStyle);
    },

    /**
     * Handles click events for both the {TagList} and its {TagListItem} children.
     * This is the event delegation pattern [1] and is a performance optimization
     * intended to reduce the number of click handlers from one per tag to one total.
     *
     * [1] http://www.sitepoint.com/blogs/2008/07/23/javascript-event-delegation-is-easier-than-you-think/
     */
    onClick: function(event) {
      // get the {TagListItem} that is really the target of this click event
      var tagListItem = this._getTagListItemForElement(event.target);

      // bail if somehow we couldn't find a {TagListItem} for the target
      if (!tagListItem)
        return;

      tagListItem.onClick(event);
    },

    /**
     * Called when the user chooses to edit a specific tag.
     */
    onBeginEdit: function(tagListItem) {
      this._editDialog.onBeginEdit(tagListItem);
    },

    /**
     * Gets the {TagListItem} that contains the given element, returning null
     * if no such {TagListItem} can be found.
     */
    _getTagListItemForElement: function(element) {
      var items = this.getItems(),
          length = items.length;

      element = $(element);
      while (!element.is('.tag'))
        element = element.parent();

      while (length--)
        if ($.same(items[length].getElement(), element))
          return items[length];

      return null;
    },

    /**
     * Returns the {wesabe.util.Selection} associated with this {TagList}.
     */
    getSelection: function() {
      return this._selection;
    },

    /**
     * Sets the {wesabe.util.Selection} associated with this {TagList}.
     */
    setSelection: function(selection) {
      this._selection = selection;
    },

    /**
     * Toggles selected status for the given {TagListItem}.
     */
    toggleListItemSelection: function(tagListItem) {
      this._selection.toggle(tagListItem);
    },

    /**
     * Selects the given {TagListItem}.
     */
    selectListItem: function(tagListItem) {
      this._selection.set(tagListItem);
    },

    /**
     * Updates the DOM to reflect the given tag data.
     */
    update: function(summaries) {
      var length = summaries.length,
          items = [];

      while (length--) {
        var summary = summaries[length],
            item = this.getItemByName(summary.tag.name);

        if (!item)
          item = new $package.TagListItem(this._template.clone(), this);

        items[length] = item;
        item.update(summary);
      }

      this.setItems(items);
    },

    /**
     * Gets the {TagListItem} associated with the given name, returning null
     * if no such {TagListItem} is found.
     */
    getItemByName: function(name) {
      var items = this.getItems(),
          length = items.length;

      while (length--)
        if (items[length].getName() === name) return items[length];

      return null;
    }
  });
});

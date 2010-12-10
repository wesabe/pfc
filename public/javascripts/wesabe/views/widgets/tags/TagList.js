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
    /**
     * The selection used by this tag list.
     *
     * @type {wesabe.util.Selection}
     */
    selection: null,

    /**
     * The current style (i.e. either "cloud" or "list").
     *
     * @type {String}
     */
    style: null,

    _editDialog: null,
    _template: null,

    init: function(element, selection, editDialog) {
      $super.init.call(this, element);

      var me = this;

      me.selection = selection;
      me._editDialog = editDialog;
      // extract the template element
      var template = me.get('element').children('li.template');
      me._template = template.clone().removeClass('template');
      template.remove();

      // register a delegating click handler
      me.get('element').click(function(event){ me.onClick(event) });

      // use zebra striping
      me.set('stripingEnabled', true);
    },

    /**
     * NOTE: This does not update the user's preferences.
     */
    setStyle: function(newStyle) {
      if (this.style === newStyle)
        return;

      var oldStyle = this.style;
      this.style = newStyle;
      this.onStyleChanged(newStyle, oldStyle);
    },

    /**
     * Handles changes to the current style of this {TagList}.
     */
    onStyleChanged: function(newStyle, oldStyle) {
      this.get('element').addClass(newStyle)
      if (oldStyle) this.get('element').removeClass(oldStyle);

      if (newStyle === 'list') {
        this.get('element').add(this.get('element').parent())
          .removeClass('one-col-list-off')
          .addClass('one-col-list');
      } else {
        this.get('element').add(this.get('element').parent())
          .removeClass('one-col-list')
          .addClass('one-col-list-off');
      }

      var items = this.get('items'),
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
      var items = this.get('items'),
          length = items.length;

      element = $(element);
      while (!element.is('.tag'))
        element = element.parent();

      while (length--)
        if ($.same(items[length].get('element'), element))
          return items[length];

      return null;
    },

    /**
     * Toggles selected status for the given {TagListItem}.
     */
    toggleListItemSelection: function(tagListItem) {
      this.get('selection').toggle(tagListItem);
    },

    /**
     * Selects the given {TagListItem}.
     */
    selectListItem: function(tagListItem) {
      this.get('selection').set(tagListItem);
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

      this.set('items', items);
    },

    /**
     * Gets the {TagListItem} associated with the given name, returning null
     * if no such {TagListItem} is found.
     */
    getItemByName: function(name) {
      var items = this.get('items'),
          length = items.length;

      while (length--)
        if (items[length].get('name') === name) return items[length];

      return null;
    }
  });
});

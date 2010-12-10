/**
 * Wraps a <li class="tag"> representing a tag in the tag widget. Instances
 * are managed by a {TagList} to which they delegate both selection and DOM
 * event handling.
 */
wesabe.$class('wesabe.views.widgets.tags.TagListItem', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  $.extend($class.prototype, {
    /**
     * Name of the tag (e.g. "food").
     */
    name: null,

    /**
     * URI for the tag (e.g. "/tags/food").
     *
     * See {wesabe.views.pages.accounts#storeState}.
     */
    uri: null,

    _tagList: null,
    _summary: null,
    _percent: null,
    _count: null,
    _nameElement: null,
    _countElement: null,

    init: function(element, tagList) {
      $super.init.call(this, element);
      this._tagList = tagList;
      this._nameElement = element.children('a.text-content');
      this._countElement = element.children('.count');
      // NOTE: Looking for a click handler binding?
      // See #onClick and TagList#onClick for an explanation of why it's not here.
    },

    /**
     * Handles changes to the current style of this {TagListItem}.
     */
    onStyleChanged: function(newStyle, oldStyle) {
      var size, display;

      if (newStyle == 'cloud') {
        size = ((95 + 120 * this._percent) + '%');
        display = 'inline';
      } else {
        size = '';
        display = 'block';
      }

      this.get('element').css('display', display);
      this._nameElement.css('font-size', size);
    },

    /**
     * Handles clicks for this {TagListItem}'s element, but is called
     * by the parent {TagList} since using event delegation means it
     * has the DOM event handler instead.
     *
     * See {TagList#onClick}.
     */
    onClick: function(event) {
      event.preventDefault();

      if ($(event.target).is('.edit-button')) {
        // clicked an edit pencil, start editing the tag
        this._tagList.onBeginEdit(this);
      } else if (event.metaKey || event.ctrlKey) {
        // cmd/ctrl+click to toggle the selection of the tag
        this._tagList.toggleListItemSelection(this);
      } else {
        // just clicked on the tag, so select it
        this.select();
      }
    },

    /**
     * Called by {wesabe.util.Selection} instances when this object
     * becomes part of the current selection.
     */
    onSelect: function() {
      if (this.get('element'))
        this.get('element').addClass('on');
    },

    /**
     * Called by {wesabe.util.Selection} instances when this object
     * ceases to be part of the current selection.
     */
    onDeselect: function() {
      if (this.get('element'))
        this.get('element').removeClass('on');
    },

    /**
     * Update the display for this {TagListItem} based on new data.
     */
    update: function(summary) {
      this.set('name', summary.tag.name);
      this.set('percent', summary.percent);
      this.set('count', summary.net.count);
    },

    /**
     * Sets the name of the tag and updates the label.
     */
    setName: function(name) {
      if (this.name === name)
        return;

      this.name = name;
      this.set('uri', '/tags/'+name);
      this._nameElement.text(name)
        .attr('href', '#'+this.uri);
    },

    /**
     * Sets the percent (size) of this tag list item.
     *
     * @private
     */
    _setPercent: function(percent) {
      if (this._percent === percent)
        return;

      this._percent = percent;
      this.onStyleChanged(this._tagList.get('style'));
    },

    /**
     * Sets the transaction count for this tag list item.
     *
     * @private
     */
    _setCount: function(count) {
      if (this._count === count)
        return;

      this._count = count;
      this._countElement.text(count);
    },

    /**
     * Gets the URL parameters for this {TagListItem}.
     *
     * See {wesabe.views.pages.accounts#paramsForCurrentSelection}.
     */
    toParams: function() {
      return [{name: 'tag', value: this.get('uri')}];
    },

    /**
     * Selects this {TagListItem}.
     */
    select: function() {
      this._tagList.selectListItem(this);
    }
  });
});

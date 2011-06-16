/**
 * Manages a list of tags attached to a transaction.
 */
wesabe.$class('wesabe.views.widgets.transactions.TagLinkList', wesabe.views.widgets.BaseListWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _template: null,

    init: function(element) {
      $super.init.call(this, element);

      var template = element.children('.template');
      this._template = template.clone().removeClass('template');
      template.remove();
    },

    /**
     * Redraws the tag links based on the tag name/split data in {tags}.
     *
     * @param {Array.<object>} tags A list of objects with "name" and "amount".
     */
    setTags: function(tags) {
      var items = [];

      for (var i = tags.length; i--;) {
        var tag = tags[i], item = this.getItemByName(tag.name);

        if (!item)
          item = new $package.TagLink(this._template.clone());

        item.set('name', tag.name);
        item.set('splitAmount', tag.amount);
        items.unshift(item);
      }

      this.set('items', items);
    },

    /**
     * Gets a child tag link in the list by name.
     *
     * @param {!string} name The name of the tag whose link to get.
     * @return {TagLink}
     */
    getItemByName: function(name) {
      var items = this.get('items');

      for (var i = items.length; i--;)
        if (items[i].get('name') === name)
          return items[i];

      return null;
    }
  });
});

/**
 * Manages a tag link with optional split.
 */
wesabe.$class('wesabe.views.widgets.transactions.TagLink', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.number
  var number = wesabe.lang.number;

  $.extend($class.prototype, {
    /**
     * The name of the tag being displayed.
     *
     * @type {string}
     */
    name: null,

    /**
     * The amount of the transaction that should count toward this tag.
     *
     * @type {object}
     */
    splitAmount: null,

    _nameLink: null,
    _splitElement: null,

    init: function(element) {
      $super.init.call(this, element);

      this._nameLink = new wesabe.views.widgets.HistoryLink(element.children('.tag-name'));
      this.registerChildWidget(this._nameLink);
      this._splitElement = element.children('.split-amount');
    },

    /**
     * Sets the name of the tag being displayed and redraws.
     *
     * @param {!string} name The name of the tag being displayed.
     */
    setName: function(name) {
      if (name === this.name)
        return;

      this.name = name;
      this._nameLink.setText(name);
      this._nameLink.set('uri', this.get('uri'));
    },

    /**
     * Gets the URI of the tag being displayed.
     *
     * @return {string}
     */
    uri: function() {
      return "/tags/" + encodeURIComponent(this.get('name'));
    },

    /**
     * Sets the split amount and redraws.
     */
    setSplitAmount: function(splitAmount) {
      if (splitAmount === this.splitAmount)
        return;

      this.splitAmount = splitAmount;

      var display = '';
      if (splitAmount && splitAmount.value)
        splitAmount = splitAmount.value;
      if (splitAmount)
        display = ':'+Math.abs(number.parse(splitAmount));
      this._splitElement.text(display);
    }
  });
});

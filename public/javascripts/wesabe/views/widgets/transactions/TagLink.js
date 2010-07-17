/**
 * Manages a tag link with optional split.
 */
wesabe.$class('wesabe.views.widgets.transactions.TagLink', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.number
  var number = wesabe.lang.number;

  $.extend($class.prototype, {
    _name: null,
    _nameLink: null,
    _splitAmount: null,
    _splitElement: null,

    init: function(element) {
      $super.init.call(this, element);

      this._nameLink = new wesabe.views.widgets.HistoryLink(element.children('.tag-name'));
      this.registerChildWidget(this._nameLink);
      this._splitElement = element.children('.split-amount');
    },

    /**
     * Gets the name of the tag being displayed.
     *
     * @return {string}
     */
    getName: function() {
      return this._name;
    },

    /**
     * Sets the name of the tag being displayed and redraws.
     *
     * @param {!string} name The name of the tag being displayed.
     */
    setName: function(name) {
      if (name === this._name)
        return;

      this._name = name;
      this._nameLink.setText(name);
      this._nameLink.setURI(this.getURI());
    },

    /**
     * Gets the URI of the tag being displayed.
     *
     * @return {string}
     */
    getURI: function() {
      return "/tags/" + this.getName();
    },

    /**
     * Sets the split amount and redraws.
     *
     * @param {number|Money} splitAmount The amount this tag is split by.
     */
    setSplitAmount: function(splitAmount) {
      if (splitAmount === this._splitAmount)
        return;

      this._splitAmount = splitAmount;

      var display = '';
      if (splitAmount && splitAmount.value)
        splitAmount = splitAmount.value;
      if (splitAmount)
        display = ':'+Math.abs(number.parse(splitAmount));
      this._splitElement.text(display);
    }
  });
});

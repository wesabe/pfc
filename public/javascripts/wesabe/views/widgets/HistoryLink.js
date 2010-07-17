/**
 * Wraps an anchor to add a history entry using the jQuery history plugin.
 */
wesabe.$class('wesabe.views.widgets.HistoryLink', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _uri: null,
    _text: null,

    init: function(element, uri) {
      $super.init.call(this, element);

      var me = this;

      element.click(function(event){ me.onClick(event) });
      if (uri) me.setURI(uri);
    },

    /**
     * Handles clicks on this link by adding an entry to the history.
     */
    onClick: function(event) {
      this.trigger('click', [event, this]);
      if (event.isPropagationStopped())
        return;

      // don't let clicks do anything when there's no URI
      if (!this.getURI()) {
        event.preventDefault();
        return;
      }

      // if the ctrl or cmd key is down, just let the browser do its thing
      if (event.ctrlKey || event.metaKey)
        return;

      $.historyLoad(this.getURI());
    },

    /**
     * Gets the uri of this link (e.g. "/tags/food").
     *
     * @return {string}
     */
    getURI: function() {
      return this._uri;
    },

    /**
     * Sets the uri for the link.
     *
     * @param {string} uri The anchor.
     */
    setURI: function(uri) {
      if (this._uri === uri)
        return;

      this._uri = uri;
      this.getElement().attr('href', uri ? '#'+uri : '');
    },

    /**
     * Gets the text content of this link.
     *
     * @return {string}
     */
    getText: function() {
      return this._text;
    },

    /**
     * Sets the text content of this link. To use something other than text
     * you can access the element directly with {#getElement}.
     *
     * @param {!string} text The text string for this link.
     */
    setText: function(text) {
      if (this._text === text)
        return;

      this._text = text;
      this.getElement().text(text);
    }
  });
});

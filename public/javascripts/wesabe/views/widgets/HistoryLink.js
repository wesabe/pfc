/**
 * Wraps an anchor to add a history entry using the jQuery history plugin.
 */
wesabe.$class('wesabe.views.widgets.HistoryLink', wesabe.views.widgets.Label, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _uri: null,
    _text: null,

    init: function(element, uri, formatter) {
      $super.init.call(this, element, formatter);

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

      $.address.value(this.getURI());
      event.preventDefault();
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
     * Alias for {#getValue}
     *
     * @return {object}
     */
    getText: function() {
      return this.getValue();
    },

    /**
     * Alias for {#setValue}.
     *
     * @param {!object} text
     */
    setText: function(text) {
      this.setValue(text);
    }
  });
});

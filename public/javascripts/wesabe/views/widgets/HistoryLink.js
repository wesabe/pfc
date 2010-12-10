/**
 * Wraps an anchor to add a history entry using the jQuery history plugin.
 */
wesabe.$class('wesabe.views.widgets.HistoryLink', wesabe.views.widgets.Label, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    uri: null,
    text: null,

    init: function(element, uri, formatter) {
      $super.init.call(this, element, formatter);

      var me = this;

      element.click(function(event){ me.onClick(event) });
      if (uri) me.set('uri', uri);
      else me.uri = element.attr('href');
    },

    /**
     * Handles clicks on this link by adding an entry to the history.
     */
    onClick: function(event) {
      this.trigger('click', [event, this]);
      if (event.isPropagationStopped())
        return;

      // don't let clicks do anything when there's no URI
      if (!this.get('uri')) {
        event.preventDefault();
        return;
      }

      // if the ctrl or cmd key is down, just let the browser do its thing
      if (event.ctrlKey || event.metaKey)
        return;

      $.address.value(this.get('uri'));
      event.preventDefault();
    },

    /**
     * Sets the uri for the link.
     *
     * @param {string} uri The anchor.
     */
    setURI: function(uri) {
      if (this.uri === uri)
        return;

      this.uri = uri;
      this.get('element').attr('href', uri || '');
    },

    /**
     * Alias for {#value}
     *
     * @return {object}
     */
    text: function() {
      return this.get('value');
    },

    /**
     * Alias for {#setValue}.
     *
     * @param {!object} text
     */
    setText: function(text) {
      this.set('value', text);
    }
  });
});

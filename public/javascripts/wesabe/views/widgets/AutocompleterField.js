/**
 * Provides autocompleting functionality to fields via YUI's Autocompleter.
 */
wesabe.$class('wesabe.views.widgets.AutocompleterField', wesabe.views.widgets.BaseField, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.number
  var number = wesabe.lang.number;
  // import wesabe.lang.string
  var string = wesabe.lang.string;

  $.extend($class.prototype, {
    _wasContainerOpen: false,
    _lastKeyPressKeyCode: null,
    _autocompleter: null,
    _dataSource: null,
    _matchMultiple: true,

    init: function(element, completions, delegate) {
      var me = this;

      $super.init.call(me, element, delegate);

      // YUI wants a container for the autocomplete, so create one
      var container = $("<div></div>"),
          width = element.css('width');
      // explicitly set the container width to that of the element
      // assumes width and padding are in px
      if (width) {
        width = getPixels(width);
        if (width > 0) {
          width += getPixels(element.css('padding-left')) + getPixels(element.css('padding-right'));
          container.css("width", width + "px");
        }
      }

      element.wrap(me.getWrapperElement());
      element.after(container);

      me._dataSource = new YAHOO.util.LocalDataSource([]);
      var autocompleter = me._autocompleter = new YAHOO.widget.AutoComplete(element[0], container[0], me._dataSource, {
        queryDelay: 0,
        maxResultsDisplayed: 10,
        queryMatchContains: false,
        delimChar: me._getDelimChar(),
        doubleQuoteOverrides: true,
        doubleQuoteResultsWithSpaces: true,
        useIFrame: $.browser.msie && $.browser.version == "6.0"
      });

      autocompleter.containerExpandEvent.subscribe(me.onShowAutocompleter, me, true);
      autocompleter.containerCollapseEvent.subscribe(me.onHideAutocompleter, me, true);
      if (completions)
        me.setCompletions(completions);
      me.registerChildWidget(autocompleter);

      function getPixels(str) {
        return number.parse(str.replace('px',''));
      }
      // get references to whatever descendents of element you need
    },

    /**
     * Gets the YUI autocompleter instance.
     *
     * @private
     */
    getAutocompleter: function() {
      return this._autocompleter;
    },

    /**
     * Gets a wrapper element for the autocompleter.
     *
     * @return {jQuery}
     */
    getWrapperElement: function() {
      return $('<div></div>');
    },

    /**
     * Returns the array of completions available to this autocompleter.
     *
     * @return {Array.<string>}
     */
    getCompletions: function() {
      return this._dataSource && this._dataSource.liveData;
    },

    /**
     * Sets the completions to use in the autocompleter.
     *
     * @param {!Array.<string>} completions
     */
    setCompletions: function(completions) {
      if (this._dataSource)
        this._dataSource.liveData = completions;
    },

    /**
     * Returns true if this autocompleter will autocomplete more than one item,
     * false otherwise.
     *
     * @return {boolean}
     */
    doesMatchMultiple: function() {
      return this._matchMultiple;
    },

    /**
     * Sets whether or not to allow multiple matches.
     *
     * @param {!boolean} matchMultiple
     */
    setMatchMultiple: function(matchMultiple) {
      this._matchMultiple = matchMultiple;
      if (this._autocompleter)
        this._autocompleter.delimChar = this._getDelimChar();
    },

    /**
     * Gets the character(s) to use as delimiters, if any.
     *
     * @return {string|Array.<string>}
     * @private
     */
    _getDelimChar: function() {
      return this._matchMultiple ? [' ', ','] : null;
    },

    /**
     * Called when a keydown event is fired in the autocompleter textbox.
     *
     * @param {event} event
     * @protected
     */
    onKeyDown: function(event) {
      this._wasContainerOpen = this._autocompleter.isContainerOpen();
      if (!this._wasContainerOpen)
        wesabe.views.widgets.Dialog.setKeystrokesEnabled(true);
    },

    /**
     * Called when a keypress event is fired in the autocompleter textbox.
     *
     * @param {event} event
     * @protected
     */
    onKeyPress: function(event) {
      this._lastKeyPressKeyCode = event.which;
    },

    /**
     * Called when a keyup event is fired in the autocompleter textbox.
     *
     * @param {event} event
     * @protected
     */
    onKeyUp: function() {
      // if the autocompleter was hidden as part of the keypress event cycle
      // then call the onHideAutocompleter callback which was put off before
      if (this._wasContainerOpen && !this._autocompleter.isContainerOpen()) {
        this._wasContainerOpen = false;
        this.onHideAutocompleter();
      }
    },

    onBlur: function() {
      // if the user tabbed out of the field then the onKeyUp above won't be
      // called, so here we make sure that the onHideAutocompleter is called
      this._wasContainerOpen = false;
      this.onHideAutocompleter();
    },

    /**
     * Sets the footer to be a tip for the user. This will be a div with class
     * yui-ac-tip contained within yui-ac-ft.
     *
     * @param {!string} text
     */
    setTip: function(text) {
      this.setFooter(
        '<div class="yui-ac-tip">'+
          '<strong>Tip:</strong> '+
          string.escapeHTML(text)+
        '</div>');
    },

    /**
     * Sets the footer on the wrapped autocompleter to the given {html}.
     *
     * @param {?string} html
     */
    setFooter: function(html) {
      this._autocompleter.setFooter(html);
    },

    /**
     * Called when the autocompleter is shown.
     */
    onShowAutocompleter: function() {
      wesabe.views.widgets.Dialog.setKeystrokesEnabled(false);
    },

    /**
     * Called when the autocompleter is hidden, which in the case of pressing
     * ESC is during a keydown event. Our {#onKeyDown} callback should
     * happen first, so we record whether we were autocompleting by setting
     * {_wasContainerOpen}.
     */
    onHideAutocompleter: function() {
      // delay enabling keystrokes if the autocompleter was hidden as a result
      // of a keystroke (i.e. ESC) until keyup or blur
      if (this._wasContainerOpen)
        return;

      wesabe.views.widgets.Dialog.setKeystrokesEnabled(true);
    },

    /**
     * Gets the value of the wrapped input.
     *
     * @return {string}
     */
    getValue: function() {
      return this.getElement().val();
    },

    /**
     * Sets the value of the wrapped input.
     *
     * @param {!string} value
     */
    setValue: function(value) {
      this.getElement().val(value);
    }
  });
});

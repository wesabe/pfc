/**
 * Wraps a dialog and provides functionality common to all dialogs.
 */
wesabe.$class('wesabe.views.widgets.Dialog', wesabe.views.widgets.Container, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.array
  var array = wesabe.lang.array;

  $.extend($class, {
    _dialogStack: [],
    _keystrokesEnabled: true,
    _mouseDownFirstResponder: null,

    /**
     * Sets {dialog} as the one receiving global keyboard events.
     */
    makeFirstResponder: function(dialog) {
      $class._dialogStack = [dialog].concat(array.minus($class._dialogStack, [dialog]));
    },

    /**
     * Removes {dialog} from the list of possible responders.
     */
    removeFromResponders: function(dialog) {
      $class._dialogStack = array.minus($class._dialogStack, [dialog]);
    },

    /**
     * Gets the {Dialog} that should be receiving all global keyboard events.
     */
    getFirstReponder: function() {
      return $class._dialogStack[0];
    },

    /**
     * Hides all visible dialogs except {dialogToRemainVisible}.
     */
    hideExcept: function(dialogToRemainVisible) {
      var items = $class._dialogStack;

      for (var i = items.length; i--;)
        if (items[i] !== dialogToRemainVisible)
          items[i].hide();

      $class._dialogStack = [dialogToRemainVisible];
    },

    /**
     * Returns true if all dialogs should ignore keystrokes, false otherwise.
     *
     * @return {boolean}
     */
    getKeystrokesEnabled: function() {
      return this._keystrokesEnabled;
    },

    /**
     * Sets whether or not to watch keystrokes to trigger events. This is
     * useful for widgets which may want to consume all the keystrokes, such as
     * an autocompleter.
     *
     * @param {!boolean} keystrokesEnabled
     */
    setKeystrokesEnabled: function(keystrokesEnabled) {
      this._keystrokesEnabled = keystrokesEnabled;
    },

    /**
     * Handlers to delegate events as higher-level events to the first responder.
     */

    onKeyDown: function(event) {
      var me = $class,
          firstResponder = me.getFirstReponder();

      if (!me._keystrokesEnabled || !firstResponder)
        return;

      // call the first responder's keydown handler if it has one
      if ($.isFunction(firstResponder.onKeyDown)) {
        firstResponder.onKeyDown(event);
        if (event.isPropagationStopped())
          return;
      }

      switch (event.which) {
        case 27 /*esc*/:
          firstResponder.onCancel();
          event.preventDefault();
          event.stopPropagation();
          break;
        case 13 /*enter*/:
          firstResponder.onConfirmCheckingForDisabled();
          event.preventDefault();
          event.stopPropagation();
          break;
      }
    },

    onMouseDown: function(event) {
      $class._mouseDownFirstResponder = $class.getFirstReponder();
    },

    onMouseUp: function(event) {
      var me = $class, firstResponder = me._mouseDownFirstResponder;

      if (!firstResponder)
        return;

      me._mouseDownFirstResponder = null;
      var el = firstResponder.getElement()[0], target = event.target;

      while (target)
        if (target === el) return;
        else target = target.parentNode;

      firstResponder.onBlur(event);
    }
  });

  $.extend($class.prototype, {
    _modal: false,
    _confirmButton: null,
    _cancelButton: null,

    init: function(element) {
      $super.init.call(this, element);

      var me = this;

      element = this.getElement();
      me._confirmButton = new $package.Button(element.find('.button.confirm'));
      me._confirmButton.bind('click', function(event){ me.onConfirmCheckingForDisabled(event) });
      me._cancelButton = new $package.Button(element.find('.button.cancel'));
      me._cancelButton.bind('click', function(event){ me.onCancel(event) });

      element.click(function(event){ me.onClick(event) });
    },

    isModal: function() {
      return this._modal;
    },

    areButtonsDisabled: function() {
      return !this._confirmButton.isEnabled();
    },

    setButtonsDisabled: function(buttonsDisabled) {
      if (this.areButtonsDisabled() === buttonsDisabled)
        return;

      this._confirmButton.setEnabled(!buttonsDisabled);
      this._cancelButton.setEnabled(!buttonsDisabled);
    },

    onClick: function(event) {
      this.makeFirstResponder();
      event.stopPropagation();
    },

    onWillShow: function(callback) {
      // does nothing by default -- change this behavior in subclasses
    },

    onDidShow: function(callback) {
      if (callback)
        callback(this);
    },

    onBlur: function(event) {
      // does nothing by default -- change this behavior in subclasses
    },

    onCancel: function(event) {
      if (this.isModal())
        this.hideModal();
      else
        this.hide();
    },

    onConfirm: function(event) {
      // TODO: implement in subclasses
    },

    onConfirmCheckingForDisabled: function(event) {
      if (this.areButtonsDisabled())
        return;
      this.onConfirm(event);
    },

    makeFirstResponder: function() {
      $class.makeFirstResponder(this);
    },

    showWithOthers: function() {
      this._modal = false;
      this.getElement().fadeIn();
      this.makeFirstResponder();
    },

    show: function(callback) {
      var me = this;

      me._modal = false;
      $class.hideExcept(me);
      me.makeFirstResponder();
      me.onWillShow(callback);
      me.getElement().fadeIn('normal', function(){ me.onDidShow(callback) })
        .addClass('visible');
    },

    showModal: function(callback) {
      var me = this;

      me._modal = true;
      $class.hideExcept(me);
      me.makeFirstResponder();

      this.onWillShow(callback);
      if ($.support.goodStackingModel()) {
        var mask = $("<div id='modal-mask'></div>")
          .appendTo('body');

        mask
          .css("height", $(document).height()+'px')
          .css("width", $(document).width()+'px')
          .show()
          .fadeTo("fast", 0.4);

        // Clicking on the mask removes it and hides the element
        mask.one("click", function(){ me.hideModal(); });
      }

       // Index the element on top of the mask and fade in
       me.getElement()
        .css("z-index", "1001")
        .fadeIn('normal', function(){ me.onDidShow(callback) })
        .addClass('visible');
    },

    hide: function(callback) {
      $class.removeFromResponders(this);
      if (this.isVisible())
        this.getElement().fadeOut(function(){ $(this).removeClass('visible'); if (callback) callback() });
      else if (callback)
        callback();
    },

    hideModal: function(callback) {
      $class.removeFromResponders(this);

      $('#modal-mask').fadeOut("fast", function() {
        $(this).remove();
      });
      if (this.isVisible())
        this.getElement().fadeOut(function(){ $(this).removeClass('visible'); if (callback) callback() });
      else if (callback)
        callback();
    },

    toggle: function() {
      if (this.isVisible())
        this.hide();
      else
        this.show();
    },

    remove: function() {
      var me = this, args = arguments;

      me.hide(function() {
        $super.remove.apply(me, args);
      });
    }
  });

  $(document)
    .bind('keydown',   $class.onKeyDown)
    .bind('mousedown', $class.onMouseDown)
    .bind('mouseup',   $class.onMouseUp);
});

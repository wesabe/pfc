/**
 * Provides a base class for all widgets on the page.
 */
wesabe.$class('wesabe.views.widgets.BaseWidget', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _element: null,
    _childWidgets: null,

    init: function(element) {
      this._element = element;
    },

    getElement: function() {
      return this._element;
    },

    getId: function() {
      return this.getElement().attr('id');
    },

    setId: function(id) {
      this.getElement().attr('id', id);
    },

    isVisible: function() {
      return this.getElement().is(':visible');
    },

    setVisible: function(visible) {
      visible ? this.getElement().show() : this.getElement().hide();
    },

    setOpacity: function(opacity, animate) {
      var css = {opacity: opacity}, element = this.getElement().stop(true);
      animate ? element.animate(css) : element.css(css);
    },

    getPosition: function() {
      return this.getElement().position();
    },

    /**
     * Aligns this widget with the given element or widget, with optional offset.
     *
     * @param {!Element|BaseWidget} elementOrWidget
     * @param {?number} leftDelta
     * @param {?number} topDelta
     */
    alignWith: function(elementOrWidget, leftDelta, topDelta) {
      var position = elementOrWidget.getPosition ? elementOrWidget.getPosition() :
                                                   $(elementOrWidget).position();
      if (leftDelta) position.left += leftDelta;
      if (topDelta) position.top += topDelta;
      this.getElement().css(position);
    },

    /**
     * Registers a child widget that needs to be cleaned up when this widget
     * instance is removed.
     *
     * @param {!BaseWidget} child
     */
    registerChildWidget: function(child) {
      if (!this._childWidgets) this._childWidgets = [];
      this._childWidgets.push(child);
    },

    /**
     * Registers all children passed along for cleanup when this widget
     * instance is removed.
     *
     * @param {...BaseWidget} var_args
     */
    registerChildWidgets: function() {
      if (!this._childWidgets) this._childWidgets = [];
      this._childWidgets = this._childWidgets.concat($.makeArray(arguments));
    },

    /**
     * Removes this widget and its children from the DOM.
     */
    remove: function() {
      if (this._element)
        this._element.remove();
      this.destroy();
    },

    /**
     * Destroys this widget by removing all ivars and cleaning up all children
     * registered using registerChildWidget(s).
     *
     * NOTE: When overriding this method be sure to call super _after_ you do
     * your own cleanup, otherwise your ivars will be gone.
     */
    destroy: function() {
      if (this._childWidgets) {
        for (var i = this._childWidgets.length; i--;)
          if ($.isFunction(this._childWidgets[i].destroy))
            this._childWidgets[i].destroy();
      }

      // remove all ivars
      for (var key in this) {
        var isOwnProperty = this.hasOwnProperty(key),
            isPrivate = key.substring(0,1) === '_',
            isIvar = isPrivate && !$.isFunction(this[key]);

        if (isOwnProperty && isIvar)
          this[key] = null;
      }
    },

    /**
     * Appends the widget to the given jQuery +element+.
     *
     * @param {!jQuery} element
     */
    appendTo: function(element) {
      if (element.getElement)
        element = element.getElement();
      this._willMoveToParent(element);
      this._element.appendTo(element);
      this._didMoveToParent();
    },

    /**
     * Prepends the widget to the given jQuery +element+.
     *
     * @param {!jQuery} element
     */
    prependTo: function(element) {
      if (element.getElement)
        element = element.getElement();
      this._willMoveToParent(element);
      this._element.prependTo(element);
      this._didMoveToParent();
    },

    /**
     * Inserts this widget before the given jQuery +element+.
     *
     * @param {!jQuery} element
     */
    insertAfter: function(element) {
      if (element.getElement)
        element = element.getElement();
      this._willMoveToParent(element.parent());
      this._element.insertAfter(element);
      this._didMoveToParent();
    },

    /**
     * Inserts this widget before the given jQuery +element+.
     *
     * @param {!jQuery} element
     */
    insertBefore: function(element) {
      if (element.getElement)
        element = element.getElement();
      this._willMoveToParent(element.parent());
      this._element.insertBefore(element);
      this._didMoveToParent();
    },

    /**
     * @private
     */
    _willMoveToParent: function(element) {
    },

    /**
     * @private
     */
    _didMoveToParent: function() {
    },

    /**
     * Determines whether this widget is attached to an HTML document.
     */
    isAttached: function() {
      return this._element &&
             this._element.length &&
             this._element.parent('html').length;
    },

    /**
     * Adds +className+ to this widget's element.
     */
    addClassName: function(className) {
      this._element.addClass(className);
    },

    /**
     * Removes +className+ from this widget's element.
     */
    removeClassName: function(className) {
      this._element.removeClass(className);
    }
  });
});

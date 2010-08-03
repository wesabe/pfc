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
    }
  });
});

/**
 * Provides a base class for all widgets on the page.
 */
wesabe.$class('wesabe.views.widgets.BaseWidget', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.number
  var number = wesabe.lang.number;

  $.extend($class.prototype, {
    element: null,
    _childWidgets: null,

    width: null,
    height: null,
    padding: null,

    needsRedraw: false,
    _redrawTimeout: null,

    init: function(element) {
      this.set('element', element);
      element = this.get('element');

      this.width = element.width();
      this.height = element.height();
      this.padding = {
        top: number.parse(element.css('padding-top')) || 0,
        right: number.parse(element.css('padding-right')) || 0,
        bottom: number.parse(element.css('padding-bottom')) || 0,
        left: number.parse(element.css('padding-left')) || 0
      };
    },

    /**
     * Returns the element to which content will be added.
     *
     * @returns {Element}
     */
    contentElement: function() {
      return this._contentElement || this.get('element');
    },

    /**
     * @private
     */
    _setContentElement: function(element) {
      this._contentElement = element;
    },

    id: function() {
      return this.get('element').attr('id');
    },

    setId: function(id) {
      this.get('element').attr('id', id);
    },

    visible: function() {
      return this.get('element').is(':visible');
    },

    setVisible: function(visible) {
      visible ? this.get('element').show() : this.get('element').hide();
    },

    setOpacity: function(opacity, animate) {
      var css = {opacity: opacity}, element = this.get('element').stop(true);
      animate ? element.animate(css) : element.css(css);
    },

    position: function() {
      return this.get('element').position();
    },

    /**
     * Aligns this widget with the given element or widget, with optional offset.
     *
     * @param {!Element|BaseWidget} elementOrWidget
     * @param {?number} leftDelta
     * @param {?number} topDelta
     */
    alignWith: function(elementOrWidget, leftDelta, topDelta) {
      var position = (elementOrWidget && elementOrWidget.getClass) ? elementOrWidget.get('position') :
                                                                     $(elementOrWidget).position();
      if (leftDelta) position.left += leftDelta;
      if (topDelta) position.top += topDelta;
      this.get('element').css(position);
    },

    /**
     * Redraws the widget. Override in subclasses to do something useful.
     */
    redraw: function() {
      this.get('element').css({
        width: this.get('contentWidth'),
        height: this.get('contentHeight'),
        'padding-top': this.padding.top+'px',
        'padding-right': this.padding.right+'px',
        'padding-bottom': this.padding.bottom+'px',
        'padding-left': this.padding.left+'px'
      });
    },

    /**
     * Notifies the widget that it needs to redraw itself, but it waits
     * for the currently executing javascript to return control first.
     *
     * @param {boolean} needsRedraw
     */
    setNeedsRedraw: function(needsRedraw) {
      if (this._redrawTimeout)
        clearTimeout(this._redrawTimeout);

      if (needsRedraw) {
        var self = this;
        this._redrawTimeout = setTimeout(function(){ self.redraw(); }, 0);
      }
    },

    /**
     * Left offset of the content rect.
     *
     * @return {number}
     */
    contentLeft: function() {
      return this.padding.left;
    },

    /**
     * Top of the content rect.
     *
     * @return {number}
     */
    contentTop: function() {
      return this.padding.top;
    },

    /**
     * Width of the content rect.
     *
     * @return {number}
     */
    contentWidth: function() {
      return this.width - this.padding.left - this.padding.right;
    },

    /**
     * Height of the content rect.
     *
     * @return {number}
     */
    contentHeight: function() {
      return this.height - this.padding.top - this.padding.bottom;
    },

    /**
     * Sets this widget's width.
     *
     * @param {number} width
     */
    setWidth: function(width) {
      this.width = width;
      this.setNeedsRedraw(true);
    },

    /**
     * Sets this widget's height.
     *
     * @param {number} height
     */
    setHeight: function(height) {
      this.height = height;
      this.setNeedsRedraw(true);
    },

    /**
     * Sets this widget's padding.
     *
     * @param {number} padding
     */
    setPadding: function(padding) {
      this.padding = padding;
      this.setNeedsRedraw(true);
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
     * Unregisters a child widget that was previously registered.
     *
     * @param {!BaseWidget} child
     */
    unregisterChildWidget: function(child) {
      this._childWidgets = wesabe.lang.array.minus(this._childWidgets, [child]);
    },

    /**
     * Unregisters child widgets that were previously registered.
     *
     * @param {...BaseWidget} var_args
     */
    unregisterChildWidgets: function() {
      this._childWidgets = wesabe.lang.array.minus(this._childWidgets, arguments);
    },

    /**
     * Removes this widget and its children from the DOM.
     */
    remove: function() {
      if (this.element)
        this.element.remove();
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
      if (element.get('element'))
        element = element.get('element');
      this._willMoveToParent(element);
      this.element.appendTo(element);
      this._didMoveToParent();
    },

    /**
     * Prepends the widget to the given jQuery +element+.
     *
     * @param {!jQuery} element
     */
    prependTo: function(element) {
      if (element.get('element'))
        element = element.get('element');
      this._willMoveToParent(element);
      this.element.prependTo(element);
      this._didMoveToParent();
    },

    /**
     * Inserts this widget before the given jQuery +element+.
     *
     * @param {!jQuery} element
     */
    insertAfter: function(element) {
      if (element.get('element'))
        element = element.get('element');
      this._willMoveToParent(element.parent());
      this.element.insertAfter(element);
      this._didMoveToParent();
    },

    /**
     * Inserts this widget before the given jQuery +element+.
     *
     * @param {!jQuery} element
     */
    insertBefore: function(element) {
      if (element.get('element'))
        element = element.get('element');
      this._willMoveToParent(element.parent());
      this.element.insertBefore(element);
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
     * Adds +widget+ to the end of this widget's content.
     *
     * @param {!BaseWidget} widget
     */
    appendChildWidget: function(widget) {
      widget.appendTo(this.get('contentElement'));
      this.registerChildWidget(widget);
    },

    /**
     * Adds +widget+ to the beginning of this widget's content.
     *
     * @param {!BaseWidget} widget
     */
    prependChildWidget: function(widget) {
      widget.prependTo(this.get('contentElement'));
      this.registerChildWidget(widget);
    },

    /**
     * Adds +element+ to the end of this widget's content.
     *
     * @param {!Element} element
     */
    appendElement: function(element) {
      this.get('contentElement').append(element);
    },

    /**
     * Adds +element+ to the beginning of this widget's content.
     *
     * @param {!Element} element
     */
    prependElement: function(element) {
      this.get('contentElement').prepend(element);
    },

    /**
     * Determines whether this widget is attached to an HTML document.
     */
    isAttached: function() {
      return this.element &&
             this.element.length &&
             this.element.parent('html').length;
    },

    /**
     * Adds +className+ to this widget's element.
     */
    addClassName: function(className) {
      this.element.addClass(className);
    },

    /**
     * Removes +className+ from this widget's element.
     */
    removeClassName: function(className) {
      this.element.removeClass(className);
    }
  });
});

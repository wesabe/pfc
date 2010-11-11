wesabe.$class('views.widgets.Module', wesabe.views.widgets.Container, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _headerElement: null,
    _headerTitleLabel: null,
    _movableElements: null,

    _movable: false,

    init: function(elementOrStyle) {
      var element, style;

      if (typeof elementOrStyle == 'string')
        style = elementOrStyle;
      else
        element = elementOrStyle;

      var topContent, middleContent, bottomContent;

      if (!element) {
        topContent = $('<div class="grip"></div>');
        middleContent = $('<div class="content"><div class="module-header"><h4></h4></div></div>');
        bottomContent = null;
      }

      $super.init.call(this, element);

      if (topContent)
        topContent.appendTo(this.getTopElement());
      if (middleContent)
        middleContent.appendTo(this.getMiddleElement());
      if (bottomContent)
        bottomContent.appendTo(this.getBottomElement());

      this.setContentElement(element.find('.content'));
      this._headerElement = element.find('.module-header');
      this._headerTitleLabel = new wesabe.views.widgets.Label(this._headerElement.find(':header'));
      this.registerChildWidget(this._headerTitleLabel);

      this._movableElements = element.find('> .top > .right > .grip, > .top > .right');
      this._movable = this._movableElements.hasClass('movable');

      if (style)
        this.addClassName(style);
    },

    /**
     * Gets the title text for this module.
     *
     * @return {String}
     */
    getTitle: function() {
      return this._headerTitleLabel.getValue();
    },

    /**
     * Sets the title text for this module.
     *
     * @param {String} title
     */
    setTitle: function(title) {
      this._headerTitleLabel.setValue(title);
    },

    getHeaderElement: function() {
      return this._headerElement;
    },

    isMovable: function() {
      return this._movable;
    },

    setMovable: function(movable) {
      movable = !!movable;
      if (movable === this._movable)
        return;

      this._movable = movable;
      if (movable) this._movableElements.addClass('movable');
      else         this._movableElements.removeClass('movable');
    }
  });
});

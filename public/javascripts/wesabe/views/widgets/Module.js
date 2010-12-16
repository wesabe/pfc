wesabe.$class('views.widgets.Module', wesabe.views.widgets.Container, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    movable: false,

    _headerElement: null,
    _headerTitleLabel: null,
    _movableElements: null,

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
      element = this.get('element');

      if (topContent)
        topContent.appendTo(this.get('topElement'));
      if (middleContent)
        middleContent.appendTo(this.get('middleElement'));
      if (bottomContent)
        bottomContent.appendTo(this.get('bottomElement'));

      this.set('contentElement', element.find('.content'));
      this._headerElement = element.find('.module-header');
      this._headerTitleLabel = new wesabe.views.widgets.Label(this._headerElement.find(':header'));
      this.registerChildWidget(this._headerTitleLabel);

      this._movableElements = element.find('> .top > .right > .grip, > .top > .right');
      this.movable = this._movableElements.hasClass('movable');

      if (style)
        this.addClassName(style);
    },

    /**
     * Gets the title text for this module.
     *
     * @return {String}
     */
    title: function() {
      return this._headerTitleLabel.get('value');
    },

    /**
     * Sets the title text for this module.
     *
     * @param {String} title
     */
    setTitle: function(title) {
      this._headerTitleLabel.set('value', title);
    },

    setMovable: function(movable) {
      movable = !!movable;
      if (movable === this.movable)
        return;

      this.movable = movable;
      if (movable) this._movableElements.addClass('movable');
      else         this._movableElements.removeClass('movable');
    }
  });
});

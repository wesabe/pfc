wesabe.$class('views.widgets.Container', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _topElement: null,
    _bottomElement: null,

    init: function(elementOrStyle) {
      var element, style;

      if (typeof elementOrStyle == 'string')
        style = elementOrStyle;
      else
        element = elementOrStyle;

      if (!element)
        element = $('<div>'+
                      '<div class="top"><div class="right"></div></div>'+
                      '<div class="middle"><div class="right"></div></div>'+
                      '<div class="bottom"><div class="right"></div></div>'+
                    '</div>');

      $super.init.call(this, element);

      this._topElement = element.find('> .top > .right');
      this.setContentElement(element.find('> .middle > .right'));
      this._bottomElement = element.find('> .bottom > .right');

      if (style)
        this.addClassName(style);
    },

    getTopElement: function() {
      return this._topElement;
    },

    getMiddleElement: function() {
      return this.getContentElement();
    },

    getBottomElement: function() {
      return this._bottomElement;
    }
  });
});

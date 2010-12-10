wesabe.$class('views.widgets.Container', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    topElement: null,
    bottomElement: null,

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

      this.topElement = element.find('> .top > .right');
      this.set('contentElement', element.find('> .middle > .right'));
      this.bottomElement = element.find('> .bottom > .right');

      if (style)
        this.addClassName(style);
    },

    middleElement: function() {
      return this.get('contentElement');
    }
  });
});

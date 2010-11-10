wesabe.$class('views.widgets.Module', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _contentElement: null,
    _headerTitleLabel: null,

    init: function(elementOrStyle) {
      var element, style;

      if (typeof elementOrStyle == 'string')
        style = elementOrStyle;
      else
        element = elementOrStyle;

      if (!element) {
        element = $('<div>'+
                      '<div class="top"><div class="right"><div class="grip"></div></div></div>'+
                      '<div class="middle"><div class="right">'+
                      '<div class="content">'+
                        '<div class="module-header">'+
                          '<h4></h4>'+
                        '</div>'+
                        // content goes here
                      '</div>'+
                      '</div></div>'+
                      '<div class="bottom"><div class="right"></div></div>'+
                    '</div>');
      }

      $super.init.call(this, element);
      this._contentElement = element.find('.content');
      this._headerTitleLabel = new wesabe.views.widgets.Label(element.find('.module-header :header'));
      this.registerChildWidget(this._headerTitleLabel);

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

    getContentElement: function() {
      return this._contentElement;
    },
  });
});

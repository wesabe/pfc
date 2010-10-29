/**
 * Manages a notification bubble.
 */
wesabe.$class('wesabe.views.widgets.Notification', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $class.STYLES = ['error', 'success', 'maintenance'];

  $.each($class.STYLES, function(i, style) {
    $class['with'+style.substring(0,1).toUpperCase()+style.substring(1)+'Style'] = function() {
      var notification = new this();
      notification.setStyle(style);
      return notification;
    };
  });

  $.extend($class.prototype, {
    _titleElement: null,
    _titleText: null,
    _messageElement: null,
    _messageText: null,
    _style: null,

    init: function(element) {
      if (!element) {
        element = $('<div class="notification">'+
                      '<div class="top">'+
                        '<div class="right">'+
                          '<p class="title"></p>'+
                          '<p class="message small"></p>'+
                        '</div>'+
                      '</div>'+
                      '<div class="bottom"><div class="right"></div></div>'+
                    '</div>');
      }

      $super.init.call(this, element);

      this._titleElement = element.find('.title');
      this._titleText = this._titleElement.text();
      this._messageElement = element.find('.message');
      this._messageText = this._messageElement.text();

      for (var i = 0, length = $class.STYLES.length; i < length; i++) {
        if (element.hasClass($class.STYLES[i])) {
          this._style = $class.STYLES[i];
          break;
        }
      }
    },

    getTitleText: function() {
      return this._titleText;
    },

    setTitleText: function(text) {
      if (text === this._titleText)
        return;

      this._titleElement.text(text);
   },

    getMessageText: function() {
      return this._messageText;
    },

    setMessageText: function(text) {
      if (text === this._messageText)
        return;

      this._messageElement.text(text);
    },

    getStyle: function() {
      return this._style;
    },

    setStyle: function(style) {
      if (this._style === style)
        return;

      for (var i = 0, length = $class.STYLES; i < length; i++)
        this.removeClassName(i);

      this._style = style;
      this.addClassName(style);
    },

    showWithTitleAndMessage: function(title, message) {
      this.setTitleText(title);
      this.setMessageText(message);
      this.setVisible(true);
    }
  });
});

wesabe.$class('views.pages.credentials.NewPage', function($class, $super, $package) {

  // import jQuery as $
  var $ = jQuery;

  $package.__id = 0;

  $.extend($class.prototype, {
    _fieldset: null,
    _fields: null,

    init: function() {
      this._fieldset = $('.content form fieldset > div');
      this._fields = [];

      var connectButton = wesabe.views.widgets.Button.withText('Connect');
      connectButton.appendTo(this._fieldset);
    },

    setFinancialInstitution: function(data) {
      for (var i = 0, length = this._fields.length; i < length; i++)
        this._fields[i].remove();

      var fi = data.financial_inst,
          fields = fi.login_fields,
          length = fields.length;

      this._fieldset.find('.field').remove();

      for (var i = length; i--; ) {
        var data = fields[i],
            field;

        switch (data.type) {
          case 'state':
            field = this._createStateField(fi, data);
            break;
          default:
            field = this._createInputField(fi, data);
            break;
        }

        this._fields.push(field);
        this._fieldset.prepend(field);
      }
    },

    _createInputField: function(fi, data) {
      var field = $('<div class="field"></div>'),
          input = $('<input type="'+data.type+'">'),
          extra = $('<span></span>');

      input.attr({name: data.key});

      var fadingLabelField = new wesabe.views.widgets.FadingLabelField(input);

      fadingLabelField.setLabelFormatter({
        format: function(value) {
          var url = value && (value.login_url || fi.homepage_url);
          if (url) {
            var match = url.match(/\/\/(?:www\d*\.)?([^\/]+)/);
            if (match)
              return [value.label, match[1]];
          }

          return value && value.label;
        }
      });

      fadingLabelField.setLabelValue(data);

      fadingLabelField.appendTo(field);

      return field;
    },

    _createStateField: function(fi, data) {
      var field = $('<div class="field"></div>');
      new wesabe.views.widgets.StateDropDownField().appendTo(field);
      return field;
    },

    _generateUniqueId: function() {
      return $package.__name__+($package.__id++);
    }
  });
});

window.page = new wesabe.views.pages.credentials.NewPage();

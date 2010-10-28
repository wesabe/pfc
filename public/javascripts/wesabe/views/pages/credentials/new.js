wesabe.$class('views.pages.credentials.NewPage', function($class, $super, $package) {

  // import jQuery as $
  var $ = jQuery;

  $package.__id = 0;

  $.extend($class.prototype, {
    _fieldset: null,

    init: function() {
      this._fieldset = $('.content form fieldset > div');
    },

    setFinancialInstitution: function(data) {
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

        this._fieldset.prepend(field);
      }
    },

    _createInputField: function(fi, data) {
      var field = $('<div class="field"></div>'),
          input = $('<input type="'+data.type+'">'),
          label = $('<label class="field-title"></label>'),
          extra = $('<span></span>');

      var id = this._generateUniqueId();
      input.attr({name: data.key, id: id});
      label.attr('for', id).text(data.label);

      var url = fi.login_url || fi.homepage_url;
      if (url) {
        console.log(url);
        extra.text('for '+url.match(/\/\/(?:www\d*\.)?([^\/]+)/)[1]);
        label.append(extra);
      }

      new wesabe.views.widgets.FadingLabelField(input, label);
      field.append(label, input);

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

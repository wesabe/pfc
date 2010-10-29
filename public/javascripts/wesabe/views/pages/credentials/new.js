wesabe.$class('views.pages.credentials.NewPage', function($class, $super, $package) {

  // import jQuery as $
  var $ = jQuery;

  $package.__id = 0;

  $.extend($class.prototype, {
    _headerLabel: null,
    _fieldset: null,
    _fields: null,
    _notification: null,

    _fiData: null,

    init: function() {
      this._headerLabel = new wesabe.views.widgets.Label($('.content .module-header :header'));
      this._fieldset = $('.content form fieldset > div');
      this._notification = wesabe.views.widgets.Notification.withErrorStyle();
      this._notification.setVisible(false);
      this._notification.insertAfter($('.content .module-header'));
      this._fields = [];

      var connectButton = wesabe.views.widgets.Button.withText('Connect');
      connectButton.appendTo(this._fieldset);
      connectButton.bind('click', this._connectButtonWasClicked, this);
    },

    setFinancialInstitution: function(data) {
      for (var i = 0, length = this._fields.length; i < length; i++)
        this._fields[i].remove();

      var fi = data.financial_inst,
          fields = fi.login_fields,
          length = fields.length;

      this._fiData = fi;

      this._fieldset.find('.field').remove();

      this._headerLabel.setValue(fi.name);

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

        var wrapper = $('<div class="field"></div>');
        field.appendTo(wrapper);

        this._fields.unshift(field);
        this._fieldset.prepend(wrapper);
      }

      this._fields[0].focus();
    },

    _createInputField: function(fi, data) {
      var input = $('<input type="'+data.type+'">');

      input.attr({name: data.key});

      var field = new wesabe.views.widgets.FadingLabelField(input);

      field.setLabelFormatter({
        format: function(value) {
          var url = value && (value.login_url || fi.homepage_url);
          if (url) {
            var match = url.match(/\/\/(?:www\d*\.)?([^\/]+)/);
            if (match)
              return [value.label, 'for '+match[1]];
          }

          return value && value.label;
        }
      });

      field.setLabelValue(data);

      return field;
    },

    _createStateField: function(fi, data) {
      var field = new wesabe.views.widgets.StateDropDownField();
      field.getElement().attr('name', data.key);
      return field;
    },

    _connectButtonWasClicked: function() {
      var me = this,
          notification = me._notification,
          params = {};

      notification.setVisible(false);

      for (var i = 0, length = me._fields.length; i < length; i++) {
        var field = me._fields[i],
            value = field.getValue();

        if (!value) {
          notification.showWithTitleAndMessage(
            "Please fill out all fields",
            "All the fields below are required. "+
            "Please fill them out and try submitting the form again.");
          return;
        }

        params[field.getElement().attr('name')] = value;
      }

      $.ajax({
        type: 'POST',
        url: '/credentials',
        data: {creds: $.toJSON(params), fi: me._fiData.wesabe_id},
        success: function(data, textStatus, xhr) {
          me._credentialCreated(xhr.getResponseHeader('Location'));
        },
        error: function(xhr, textStatus, error) {
          notification.showWithTitleAndMessage(
            "Unable to connect",
            "We couldn't save the credentials you entered. "+
            "Please check your internet connection.");
        }
      });
    },

    _credentialCreated: function(url) {
      var me = this;

      $.ajax({
        type: 'POST',
        url: url+'/jobs',
        success: function(data, textStatus, xhr) {
          me._jobCreated(xhr.getResponseHeader('Location'));
        },
        error: function(xhr, textStatus, error) {
        }
      });
    },

    _jobCreated: function(url) {
      var me = this,
          errorsLeft = 5;

      function pollStatus() {
        $.ajax({
          type: 'GET',
          url: url,
          success: function(data, textStatus, xhr) {
            switch (data.status) {
              case 'success':
                window.location = '/';
                break;
              case 'pending':
                setTimeout(pollStatus, 2000);
                break;
              case 'error':
                me._showUnableToConnectNotification();
                break;
            }
          },
          error: function() {
            if (errorsLeft-- > 0)
              setTimeout(pollStatus, 5000);
            else
              me._showUnableToConnectNotification();
          }
        });
      }

      pollStatus();
    },

    _showUnableToConnectNotification: function() {
      this._notification.showWithTitleAndMessage(
        "Unable to connect",
        "We saved the credentials, but we couldn't connect to "+
        this._fiData.name+". Please check your internet connection.");
    }
  });
});

window.page = new wesabe.views.pages.credentials.NewPage();

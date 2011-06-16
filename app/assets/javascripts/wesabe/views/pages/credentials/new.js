wesabe.$class('views.pages.credentials.NewPage', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _module: null,
    _form: null,
    _notification: null,

    _fiData: null,
    _credentialURL: null,
    _jobURL: null,
    _lastVersion: -1,

    init: function(module) {
      var me = this;

      me._module = module;

      me._notification = new wesabe.views.widgets.Notification();
      me._notification.set('visible', false);
      module.appendChildWidget(me._notification);

      me._form = new wesabe.views.widgets.Form();
      me._form.bind('submit', me._connectButtonWasClicked, me);
      module.appendChildWidget(me._form);

      var connectButton = wesabe.views.widgets.Button.withText('Connect');
      connectButton.bind('click', me._connectButtonWasClicked, me);
      me._form.appendChildWidget(connectButton);
    },

    setFinancialInstitution: function(fi) {
      this._fiData = fi;
      this._module.set('title', fi.name)
      this._form.set('enabled', true);
      this._setFields(fi.login_fields, fi);
    },

    askSecurityQuestions: function(questions) {
      this._form.set('enabled', true);
      this._setFields(questions, null);
    },

    _setFields: function(fields, fi) {
      var form = this._form;

      form.clearFields();

      for (var i = 0, length = fields.length; i < length; i++) {
        var data = fields[i];

        switch (data.type) {
          case 'state':
            form.addField(this._createStateField(data, fi));
            break;
          case 'choice':
            form.addField(this._createChoiceField(data, fi));
            break;
          default:
            form.addField(this._createInputField(data, fi));
            break;
        }
      }

      form.focus();
    },

    _createInputField: function(data, fi) {
      var input = $('<input type="'+data.type+'">');

      var field = new wesabe.views.widgets.FadingLabelField(input);
      field.set('name', data.key);

      field.set('labelFormatter', {
        format: function(value) {
          var url = value && fi && (fi.login_url || fi.homepage_url);
          if (url) {
            var match = url.match(/\/\/(?:www\d*\.)?([^\/]+)/);
            if (match)
              return [value.label, 'for '+match[1]];
          }

          return value && value.label;
        }
      });

      field.set('labelValue', data);

      return field;
    },

    _createChoiceField: function(data, fi) {
      var field = new wesabe.views.widgets.DropDownField();
      field.set('name', data.key);

      var choices = data.choices;
      for (var i = 0, length = choices.length; i < length; i++) {
        var choice = choices[i];
        field.addOption(choice.label, choice.value);
      }

      return field;
    },

    _createStateField: function(data, fi) {
      var field = new wesabe.views.widgets.StateDropDownField();
      field.set('name', data.key);
      return field;
    },

    _connectButtonWasClicked: function() {
      var me = this,
          params = me._form.get('fieldValues');

      me._notification.set('visible', false);

      for (var k in params) {
        if (params.hasOwnProperty(k)) {
          if (!params[k]) {
            me._showNotification('error',
              "Please fill out all fields",
              "All the fields below are required. "+
              "Please fill them out and try submitting the form again.");
            return;
          }
        }
      }

      me._form.set('enabled', false);

      $.ajax({
        type: me._credentialURL ? 'PUT' : 'POST',
        url: me._credentialURL || '/credentials',
        data: {creds: $.toJSON(params), fi: me._fiData.wesabe_id},
        success: function(data, textStatus, xhr) {
          if (me._credentialURL) {
            me._watchJob(me._jobURL);
          } else {
            me._credentialURL = xhr.getResponseHeader('Location');
            me._credentialCreated(me._credentialURL);
          }
        },
        error: function(xhr, textStatus, error) {
          me._reset();
          me._showNotification('error',
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
          me._showNotification('info',
            "Starting connection to "+me._fiData.name+"!",
            "We'll login and download your statements now. If we need any more information, we'll ask you momentarily.");
          me._jobURL = xhr.getResponseHeader('Location');
          me._watchJob(me._jobURL);
        },
        error: function(xhr, textStatus, error) {
          me._reset();
          me._showNotification('error',
            "Unable to start job",
            "We saved your credentials but we couldn't retrieve "+
            "your statements from "+me._fiData.name+".");
        }
      });
    },

    _watchJob: function(url) {
      var me = this,
          errorsLeft = 5;

      function pollStatus() {
        $.ajax({
          type: 'GET',
          url: url,
          success: function(data, textStatus, xhr) {
            // ignore ones we've already seen or are stale
            if (data.version <= me._lastVersion) {
              me._jobTimeout = setTimeout(pollStatus, 2000);
              console.log('skipping version', data.version, ' (we already have', me._lastVersion, ')');
              return;
            }

            console.log('updating from version', me._lastVersion, 'to', data.version);
            me._lastVersion = data.version;
            switch (data.status) {
              case 'successful':
                me._showNotification('success',
                  "Successfully retrieved statements from "+me._fiData.name+"!",
                  "We'll return you to My Accounts now so you can review.");
                setTimeout(function(){ window.location = '/accounts'; }, 1000);
                break;
              case 'pending':
                if (/^suspended\./.test(data.result)) {
                  me.askSecurityQuestions(data.data[data.result].questions);
                  me._showNotification('maintenance',
                    me._fiData.name+" needs more information from you",
                    "Please fill out all the fields below.");
                } else {
                  me._jobTimeout = setTimeout(pollStatus, 2000);
                }
                break;
              case 'failed':
                me._reset();
                me._showUnableToConnectNotification();
                break;
            }
          },
          error: function() {
            if (errorsLeft-- > 0)
              me._jobTimeout = setTimeout(pollStatus, 5000);
            else {
              me._reset();
              me._showUnableToConnectNotification();
            }
          }
        });
      }

      pollStatus();
    },

    _stopWatchingJob: function() {
      cancelTimeout(this._jobTimeout);
    },

    _reset: function() {
      this._form.set('enabled', true);
      this._credentialURL = null;
      this._jobURL = null;
      this._lastVersion = -1;
    },

    _showUnableToConnectNotification: function() {
      this._showNotification('error',
        "Unable to connect",
        "We saved the credentials, but we couldn't connect to "+
        this._fiData.name+". Please try again.");
    },

    _showNotification: function(style, title, message) {
      this._notification.set('style', style);
      this._notification.showWithTitleAndMessage(title, message);
    }
  });
});

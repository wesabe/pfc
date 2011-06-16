/**
 * Handles prompting the user for new target information.
 */
wesabe.$class('wesabe.views.widgets.targets.AddTargetDialog', wesabe.views.widgets.Dialog, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.number
  var number = wesabe.lang.number;

  $.extend($class.prototype, {
    _delegate: null,
    _tagAutocompleterField: null,
    _amountField: null,

    init: function(element, delegate) {
      $super.init.call(this, element);
      this._delegate = delegate;
      this._tagAutocompleterField = new wesabe.views.widgets.tags.TagAutocompleterField(
        element.find("input[name=tag]"),
        wesabe.data.tags.sharedDataSource,
        this
      );
      this._tagAutocompleterField.set('matchMultiple', false);
      this._amountField = new wesabe.views.widgets.BaseField(element.find('input[name=amount]'), this);
    },

    tag: function() {
      return this._tagAutocompleterField.get('value').replace(/['"](.*?)['"]/, '$1');
    },

    amount: function() {
      return number.parse(this._amountField.get('value'));
    },

    onWillShow: function(callback) {
      $super.onWillShow.call(this, callback);
      this._tagAutocompleterField.clear();
      this._amountField.clear();
    },

    onDidShow: function(callback) {
      this._tagAutocompleterField.focus();
      $super.onDidShow.call(this, callback);
    },

    onConfirm: function() {
      if (this._delegate && this._delegate.onConfirm)
        this._delegate.onConfirm(this);
    }
  });
});

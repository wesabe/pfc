/**
 * Handles prompting the user for target details.
 */
wesabe.$class('wesabe.views.widgets.targets.EditTargetDialog', wesabe.views.widgets.Dialog, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.number
  var number = wesabe.lang.number;

  $.extend($class.prototype, {
    amount: null,
    tagName: null,

    _delegate: null,
    _tagLabel: null,
    _amountField: null,

    init: function(element, delegate) {
      $super.init.call(this, element);
      this._delegate = delegate;
      this._tagLabel = element.find('.edit-target-tag');
      this._amountField = new wesabe.views.widgets.BaseField(element.find('input[name=amount]'));
      this.registerChildWidget(this._amountField);
    },

    setAmount: function(amount) {
      this.amount = amount;
      this._redraw();
    },

    alignWithTarget: function(targetElement) {
      this.alignWith(targetElement, 16, -12);
    },

    setTagName: function(tagName) {
      this.tagName = tagName;
      this._redraw();
    },

    onWillShow: function(callback) {
      $super.onWillShow.call(this, callback);
      this._redraw();
    },

    onDidShow: function(callback) {
      this._amountField.selectAllAndFocus()
      $super.onDidShow.call(this, callback);
    },

    _redraw: function() {
      this._amountField.setValue(this.amount);
      this._tagLabel.text(this.tagName);
    },

    onConfirm: function() {
      this.setAmount(number.parse(this._amountField.getValue()));
      if (this._delegate && this._delegate.onConfirm)
        this._delegate.onConfirm(this);
    }
  });
});

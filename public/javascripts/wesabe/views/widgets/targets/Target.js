/**
 * Wraps a target list item on the dashboard.
 */
wesabe.$class('wesabe.views.widgets.targets.Target', wesabe.views.widgets.BaseWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.money
  var money = wesabe.lang.money;
  // import wesabe.lang.string
  var string = wesabe.lang.string;
  // import wesabe.views.shared
  var shared = wesabe.views.shared;
  // import wesabe.views.widgets.Label
  var Label = wesabe.views.widgets.Label;

  $.extend($class.prototype, {
    _targetList: null,
    _tagName: null,
    _monthlyLimit: null,
    _amountSpent: null,

    _tagNameElement: null,
    _barSpentElement: null,
    _amountSpentLabel: null,
    _amountRemainingLabel: null,
    _targetAmountLabel: null,
    _removeButton: null,
    _editButton: null,

    init: function(element, targetList) {
      var me = this;

      $super.init.call(this, element);

      this._targetList = targetList;

      this._tagNameElement = element.find('.target-name');
      this._barSpentElement = element.find('.target-bar-spent');
      this._barSpentElement.css('background-position', '-410px 4px');

      this._amountSpentLabel = new Label(element.find('.amount-spent'));
      this._amountRemainingLabel = new Label(element.find('.amount-remaining'));
      this._targetAmountLabel = new Label(element.find('.target-amount'));

      this._removeButton = new wesabe.views.widgets.Button(element.find('.remove'));
      this._removeButton.bind('click', this.onRemove, this);
      this._editButton = new wesabe.views.widgets.Button(element.find('.edit'));
      this._editButton.bind('click', this.onEdit, this);

      this._tagNameElement.add(this._barSpentElement).add(this._targetAmountLabelElement).bind('click', function() {
        shared.navigateTo('/accounts#/tags/'+string.uriEscape(me.getTagName()));
      });

      this.registerChildWidgets(this._removeButton, this._editButton, this._amountSpentLabel, this._amountRemainingLabel, this._targetAmountLabel);
    },

    getTagName: function() {
      return this._tagName;
    },

    setTagName: function(tagName) {
      if (this._tagName === tagName)
        return;

      this._tagName = tagName;
      this._tagNameElement.text(tagName);
    },

    getMonthlyLimit: function() {
      return this._monthlyLimit;
    },

    setMonthlyLimit: function(monthlyLimit) {
      this._monthlyLimit = monthlyLimit;
      this.redraw();
    },

    getAmountSpent: function() {
      return this._amountSpent;
    },

    setAmountSpent: function(amountSpent) {
      this._amountSpent = amountSpent;
      this.redraw();
    },

    getPercentFull: function() {
      var limit = money.amount(this._monthlyLimit);
      var amountSpent = money.amount(this._amountSpent);
      if (limit == 0)
        return amountSpent == 0 ? 0 : 1;

      return amountSpent / limit;
    },

    getAmountRemaining: function() {
      return money.toMoney(
          money.amount(this._monthlyLimit) - money.amount(this._amountSpent),
          this._monthlyLimit.currency);
    },

    /**
     * Handles clicking the remove button on a target.
     */
    onRemove: function() {
      var me = this;
      this._targetList.removeTarget(this.getTagName());
      this.getElement().fadeOut(function(){ me.remove() });
    },

    /**
     * Handles clicking the edit button on a target.
     */
    onEdit: function() {
      var me = this;

      this._targetList.asyncGetEditTargetDialog(function(dialog) {
        dialog.setTagName(me.getTagName());
        dialog.setAmount(money.amount(me.getMonthlyLimit()));
        dialog.alignWithTarget(me);
        dialog.showModal();
      });
    },

    redraw: function() {
      if (this._amountSpent === null || this._monthlyLimit === null)
        return;

      var me              = this,
          percentFull     = this.getPercentFull(),
          amountRemaining = this.getAmountRemaining(),
          hasLeftBuffer   = percentFull >= 0.1,
          hasRightBuffer  = percentFull <= 0.9;

      this.animateSpent(percentFull, function() {
        var remainingText = "";
        if (hasRightBuffer) {
          remainingText += me._format(me.getAmountRemaining());
          if (!hasLeftBuffer) remainingText += ' left';
        }
        me._amountRemainingLabel.setValue(remainingText);

        var spentText = "";
        if (hasLeftBuffer) {
          spentText += me._format(me.getAmountSpent());
        }
        me._amountSpentLabel.setValue(spentText);

        me._amountSpentLabel.setVisible(hasLeftBuffer);
        me._amountRemainingLabel.setVisible(hasRightBuffer);

        if (money.amount(amountRemaining) < 0) {
          me._targetAmountLabel.setValue(me._format(money.abs(amountRemaining))+' over');
          me._targetAmountLabel.getElement().addClass('over');
        } else {
          me._targetAmountLabel.setValue(me._format(me.getMonthlyLimit()))
          me._targetAmountLabel.getElement().removeClass('over');
        }
      });
    },

    animateSpent: function(percentFull, callback) {
      var origin = -10,
          x = Math.min(0, 400 * percentFull - 410);

      this._barSpentElement
        //.css('background-position', origin+'px 4px')
        .animate({ 'background-position': x+'px 4px' }, callback);

      this._amountRemainingLabel.getElement()
        //.css('left', origin+415)
        .animate({'left': x+415});
    },

    _format: function(amount) {
      return (money.amount(amount) < 1) ? money.format(amount) : money.format(amount, {precision: 0});
    }
  });
});

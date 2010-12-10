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
    /**
     * The name of the tag this target is set for.
     *
     * @type {string}
     */
    tagName: null,

    /**
     * The monthly spending limit this target is set to.
     *
     * @type {number}
     */
    monthlyLimit: null,

    /**
     * The amount the user has spent on this target's tag so far this month.
     *
     * @type {number}
     */
    amountSpent: null,

    /**
     * true if this target has been destroyed, false otherwise
     *
     * @type {boolean}
     */
    destroyed: false,

    _targetList: null,
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
        shared.navigateTo('/accounts#/tags/'+string.uriEscape(me.get('tagName')));
      });

      this.registerChildWidgets(this._removeButton, this._editButton, this._amountSpentLabel, this._amountRemainingLabel, this._targetAmountLabel);
    },

    setTagName: function(tagName) {
      if (this.tagName === tagName)
        return;

      this.tagName = tagName;
      this._tagNameElement.text(tagName);
    },

    setMonthlyLimit: function(monthlyLimit) {
      this.monthlyLimit = monthlyLimit;
      this.redraw();
    },

    setAmountSpent: function(amountSpent) {
      this.amountSpent = amountSpent;
      this.redraw();
    },

    percentFull: function() {
      var limit = money.amount(this.get('monthlyLimit'));
      var amountSpent = money.amount(this.get('amountSpent'));
      if (limit == 0)
        return amountSpent == 0 ? 0 : 1;

      return amountSpent / limit;
    },

    amountRemaining: function() {
      return money.toMoney(
          money.amount(this.get('monthlyLimit')) - money.amount(this.get('amountSpent')),
          this.get('monthlyLimit').currency);
    },

    /**
     * Handles clicking the remove button on a target.
     */
    onRemove: function() {
      var me = this;
      this._targetList.removeTarget(this.get('tagName'));
      this.set('destroyed', true);
      this.get('element').fadeOut(function(){ me.remove() });
    },

    /**
     * Handles clicking the edit button on a target.
     */
    onEdit: function() {
      var me = this;

      this._targetList.asyncGetEditTargetDialog(function(dialog) {
        dialog.set('tagName', me.get('tagName'));
        dialog.set('amount', money.amount(me.get('monthlyLimit')));
        dialog.alignWithTarget(me);
        dialog.showModal();
      });
    },

    redraw: function() {
      if (this.get('amountSpent') === null || this.get('monthlyLimit') === null)
        return;

      var me              = this,
          percentFull     = this.get('percentFull'),
          amountRemaining = this.get('amountRemaining'),
          hasLeftBuffer   = percentFull >= 0.1,
          hasRightBuffer  = percentFull <= 0.9;

      this.animateSpent(percentFull, function() {
        var remainingText = "";
        if (hasRightBuffer) {
          remainingText += me._format(me.get('amountRemaining'));
          if (!hasLeftBuffer) remainingText += ' left';
        }
        me._amountRemainingLabel.set('value', remainingText);

        var spentText = "";
        if (hasLeftBuffer) {
          spentText += me._format(me.get('amountRemaining'));
        }
        me._amountSpentLabel.set('value', spentText);

        me._amountSpentLabel.set('visible', hasLeftBuffer);
        me._amountRemainingLabel.set('visible', hasRightBuffer);

        if (money.amount(amountRemaining) < 0) {
          me._targetAmountLabel.set('value', me._format(money.abs(amountRemaining))+' over');
          me._targetAmountLabel.get('element').addClass('over');
        } else {
          me._targetAmountLabel.set('value', me._format(me.get('monthlyLimit')))
          me._targetAmountLabel.get('element').removeClass('over');
        }
      });
    },

    animateSpent: function(percentFull, callback) {
      var origin = -10,
          x = Math.min(0, 400 * percentFull - 410);

      this._barSpentElement
        //.css('background-position', origin+'px 4px')
        .animate({ 'background-position': x+'px 4px' }, callback);

      this._amountRemainingLabel.get('element')
        //.css('left', origin+415)
        .animate({'left': x+415});
    },

    _format: function(amount) {
      return (money.amount(amount) < 1) ? money.format(amount) : money.format(amount, {precision: 0});
    }
  });
});

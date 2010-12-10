/**
 * Manages the list of targets on the dashboard.
 */
wesabe.$class('wesabe.views.widgets.targets.TargetList', wesabe.views.widgets.BaseListWidget, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _template: null,
    _targetWidget: null,
    _dataSource: null,
    _noTargetsElement: null,
    _dateRangeNavElement: null,
    _targetEditDialog: null,
    _targetEditDialogElement: null,

    init: function(element, targetWidget, dataSource) {
      $super.init.call(this, element);

      this._targetWidget = targetWidget;
      this._dataSource = dataSource;
      this._dataSource.subscribe(this.update, this);

      var template = element.children('.template');
      this._template = template.clone().removeClass('template');
      template.remove();

      this._noTargetsElement = $('#no-targets');
      this._dateRangeNavElement = $('#date-range-nav');
      this._targetEditDialogElement = $('#edit-dialog');
    },

    update: function(targetListData) {
      if (targetListData.length) {
        this._noTargetsElement.hide();
        this._dateRangeNavElement.show();
      } else {
        this._noTargetsElement.show();
        this._dateRangeNavElement.hide();
      }

      var items = [];

      for (var i = targetListData.length; i--; ) {
        var targetDatum = targetListData[i],
            target = this.getItemByTagName(targetDatum.tag.name);

        if (!target) {
          target = new $package.Target(this._template.clone(), this);
        }

        target.set('tagName', targetDatum.tag.name);
        target.set('monthlyLimit', targetDatum.monthly_limit);
        target.set('amountSpent', targetDatum.amount_spent);

        items[i] = target;
      }

      this.set('items', items);
    },

    getItemByTagName: function(tagName) {
      for (var i = this.get('items').length; i--; ) {
        var item = this.getItem(i);
        if (item.get('tagName') === tagName)
          return item;
      }
    },

    onConfirm: function(dialog) {
      this._dataSource.update(dialog.get('tagName'), dialog.get('amount'), this.refresh, this);
      dialog.hideModal()
    },

    /**
     * Refreshes the data in the data source and, as a result, redraws the list.
     */
    refresh: function() {
      for (var i = this.get('items').length; i--; )
        if (this.getItem(i).get('destroyed'))
          this.removeItemAtIndex(i);

      this._dataSource.clearCache();
      this._dataSource.requestData();
    },

    /**
     * Load the EditTargetDialog class and call back with an instance.
     *
     * @param {?function(EditTargetDialog)} callback
     * @private
     */
    asyncGetEditTargetDialog: function(callback) {
      if (this._targetEditDialog) {
        if (callback) callback(this._targetEditDialog);
        return;
      }

      var me = this;
      wesabe.load($package, 'EditTargetDialog', function(klass) {
        me._targetEditDialog = new klass(me._targetEditDialogElement, me);
        if (callback) callback(me._targetEditDialog);
      });
    },

    /**
     * Updates the amount for the target with the given tag.
     *
     * @param {!string} tag
     * @param {!number} amount
     */
    removeTarget: function(tag) {
      this._dataSource.remove(tag, this.refresh, this);
    }
  });
});

/**
 * Wraps the targets widget on the dashboard.
 */
wesabe.$class('wesabe.views.widgets.targets.TargetWidget', wesabe.views.widgets.Module, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.date
  var date = wesabe.lang.date;
  // import wesabe.views.widgets.Button
  var Button = wesabe.views.widgets.Button;
  // import wesabe.views.widgets.Label
  var Label = wesabe.views.widgets.Label;

  $.extend($class.prototype, {
    _dataSource: null,
    _targetList: null,
    _addTargetDialog: null,
    _addTargetDialogElement: null,
    _previousMonthButton: null,
    _nextMonthButton: null,
    _previousMonthLabel: null,
    _nextMonthLabel: null,
    _currentMonthLabel: null,
    _headerMonthLabel: null,

    init: function(element, dataSource) {
      $super.init.call(this, element);

      this._dataSource = dataSource;

      // create the list of targets
      this._targetList = new $package.TargetList($("#targets-list"), this, this._dataSource);

      // bind click on Add Target to show the add target dialog
      var addTargetButton = Button.withText('Add Spending Target');
      addTargetButton.bind('click', this.onAddTarget, this);
      addTargetButton.prependTo(this.get('headerElement'));
      this._addTargetDialogElement = element.find('#add-target .dialog');

      // set up the month navigation buttons
      var dateRangeNavElement = element.find('#date-range-nav');
      this._previousMonthButton = new Button(dateRangeNavElement.find('.left-arrow,.previous-month'));
      this._previousMonthButton.bind('click', this.selectPreviousMonth, this);
      this._nextMonthButton = new Button(dateRangeNavElement.find('.right-arrow,.next-month'));
      this._nextMonthButton.bind('click', this.selectNextMonth, this);

      // set up the month labels
      var monthFormatter = {format: function(value){ return date.format(value, 'MMM yyyy') }};
      this._previousMonthLabel = new Label(dateRangeNavElement.find('.previous-month span'), monthFormatter);
      this._nextMonthLabel = new Label(dateRangeNavElement.find('.next-month span'), monthFormatter);
      this._currentMonthLabel = new Label(dateRangeNavElement.find('.current-date-range'), {
        format: function(value) {
          var now = new Date(),
              endOfMonth = date.endOfMonth(now);
          if (date.equals(endOfMonth, date.endOfMonth(value))) {
            var days = Math.ceil((endOfMonth - now)/date.DAY) + 1;
            return (days == 1 ? "Last day of " : days + " days left in ") + date.format(value, "MMM");
          } else {
            return monthFormatter.format(value);
          }
        }
      });
      this._headerMonthLabel = new Label(element.find('.module-header .month'), {
          format: function(value){ return date.format(value, 'MMM') }
      });

      // make sure we GC the target list and add target button when we're cleaning up
      this.registerChildWidgets(
        this._targetList, addTargetButton,
        this._previousMonthButton, this._nextMonthButton
      );

      // set things in motion by displaying the current month
      this.set('currentMonth', new Date());
    },

    /**
     * Selects the month before the currently-selected month, updating the UI.
     */
    selectPreviousMonth: function() {
      this.set('currentMonth', this.getMonthWithOffsetInMonths(-1));
    },

    /**
     * Selects the month before the currently-selected month, updating the UI.
     */
    selectNextMonth: function() {
      this.set('currentMonth', this.getMonthWithOffsetInMonths(1));
    },

    /**
     * Returns a date in the month offset from the current month by +offset+ months.
     *
     * @param {!number} offset
     * @private
     */
    getMonthWithOffsetInMonths: function(offset) {
      return date.addMonths(this.get('currentMonth'), offset);
    },

    /**
     * Returns a Date in the currently-selected month.
     *
     * @return {Date}
     */
    currentMonth: function() {
      return this._dataSource.get('startDate');
    },

    /**
     * Returns true if the currently-selected month is this month, false otherwise.
     *
     * @return {boolean}
     */
    isThisMonth: function() {
      return date.equals(date.startOfMonth(this.get('currentMonth')), date.startOfMonth(new Date()));
    },

    /**
     * Sets the displayed month to the month that includes +currentMonth+.
     *
     * @param {!date} currentMonth
     */
    setCurrentMonth: function(currentMonth) {
      this._dataSource.selectMonth(currentMonth);
      this._dataSource.requestData();

      this._nextMonthButton.set('visible', !this.isThisMonth());
      this._previousMonthLabel.set('value', this.getMonthWithOffsetInMonths(-1));
      this._nextMonthLabel.set('value', this.getMonthWithOffsetInMonths(1));
      this._currentMonthLabel.set('value', currentMonth);
      this._headerMonthLabel.set('value', currentMonth);
    },

    /**
     * Handles the user clicking the Add Target button.
     *
     * @private
     */
    onAddTarget: function() {
      this.asyncGetAddTargetDialog(function(dialog) {
        dialog.showModal();
      });
    },

    /**
     * Load the AddTargetDialog class and call back with an instance.
     *
     * @param {?function(AddTargetDialog)} callback
     * @private
     */
    asyncGetAddTargetDialog: function(callback) {
      if (this._addTargetDialog) {
        if (callback) callback(this._addTargetDialog);
        return;
      }

      var me = this;
      wesabe.load($package, 'AddTargetDialog', function(klass) {
        me._addTargetDialog = new klass(me._addTargetDialogElement, me);
        if (callback) callback(me._addTargetDialog);
      });
    },

    /**
     * Delegate method for the AddTargetDialog instance.
     *
     * @private
     */
    onConfirm: function(dialog) {
      this._dataSource.create(dialog.get('tag'), dialog.get('amount'), function(){ this._targetList.refresh() }, this);
      dialog.hideModal();
    }
  });
});

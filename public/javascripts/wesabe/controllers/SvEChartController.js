/**
 * Manages a view and data source to show a Spending vs. Earnings chart.
 */
wesabe.$class('wesabe.controllers.SvEChartController', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.date
  var date = wesabe.lang.date;
  // import wesabe.lang.number
  var number = wesabe.lang.number;
  // import wesabe.lang.money
  var money = wesabe.lang.money;
  // import wesabe.data.preferences
  var preferences = wesabe.data.preferences;

  var DAY = "Day";
  var FIRST_DAY_OF_WEEK = 1; // NOTE: BRCM uses Monday as the first day of the week, so we follow suit.
  var MONTH = "Month";
  var WEEK = "Week";

  $class.INTERVALS = [
    //{key: "0", shortLabel: '1m', label: 'past month', timeUnitsAgo: 31, unit: DAY, summaryType: 'daily'},
    {key: "1", shortLabel: 'weekly', label: 'past 3 months', timeUnitsAgo: 12, unit: WEEK, summaryType: 'weekly'},
    //{key: "2", shortLabel: '6m', label: 'past 6 months', timeUnitsAgo: 6, unit: MONTH, summaryType: 'monthly'},
    {key: "3", shortLabel: 'monthly', label: 'past 12 months', timeUnitsAgo: 12, unit: MONTH, summaryType: 'monthly'}
  ];

  $class.DEFAULT_INTERVAL = $class.INTERVALS[1];

  $.extend($class.prototype, {
    chart: null,
    dataSource: null,

    _dataSourceChangeHandler: null,

    init: function(chart, dataSource) {
      if (chart)
        this.set('chart', chart);
      if (dataSource)
        this.set('dataSource', dataSource);

      var self = this;
      this._dataSourceChangeHandler = function() { self._dataDidChange(); };
    },

    setChart: function(chart) {
      var self = this;

      this.chart = chart;

      chart.set('chartInset', {top: 0, bottom: 35, left: 60, right: 60});
      chart.set('xValueFormatter', {
        format: function(value, index, count) {
          return self._formatDate(value, index, count);
        }
      });
      chart.set('yValueFormatter', money.formatterWithOptions({precision: 0}));
    },

    intervalButtons: function() {
      var buttons = [],
          buttonGroup;

      for (var i = 0; i < $class.INTERVALS.length; i++) {
        var interval = $class.INTERVALS[i],
            button = new wesabe.views.widgets.Button($('<a class="toggle-button"><span></span></a>'));

        button.set('text', interval.shortLabel);
        button.set('value', interval);
        buttons.push(button);
      }

      buttonGroup = new wesabe.views.widgets.ButtonGroup(buttons, this);
      buttonGroup.selectButtonByValue(this.get('selectedInterval'));

      return this.intervalButtons = buttonGroup;
    },

    onSelectionChange: function(sender, selection) {
      this.set('selectedInterval', selection.get('value'));
    },

    _formatDate: function(value, index, count) {
      var interval = this.get('selectedInterval'),
          edge = (index == 0 || index == count - 1),
          format = null;

      value = date.parse(value);

      switch (interval.unit) {
        case DAY:
          format = (edge || value.getDate() == 1) ? 'd\nNNN' : 'd';
          break;

        case WEEK:
          format = edge ? 'NNN d\nyyyy' : 'NNN d';
          break;

        case MONTH:
          format = edge ? 'NNN\nyyyy' : 'NNN';
          break;
      }

      return date.format(value, format);
    },

    setDataSource: function(dataSource) {
      if (this.dataSource)
        this.dataSource.unbind('change', this._dataSourceChangeHandler)

      if (dataSource)
        dataSource.bind('change', this._dataSourceChangeHandler);

      this.dataSource = dataSource;
    },

    reload: function() {
      if (!this.dataSource)
        return;

      var interval = this.get('selectedInterval'),
          dateRange = this._dateRange(interval);

      this.dataSource.set('startDate', dateRange.start);
      this.dataSource.set('endDate', dateRange.end);
      this.dataSource.set('type', interval.summaryType);
      this.dataSource.requestData();
    },

    _dateRange: function(interval) {
      var end = new Date(),
          start = date.doWithUnit('add', interval.unit, end, -interval.timeUnitsAgo);

      return {start: start, end: end};
    },

    _selectedInterval: function() {
      var range = preferences.getInt('charts.line.range');

      for (var i = 0; i < $class.INTERVALS.length; i++) {
        var interval = $class.INTERVALS[i];
        if (interval.key == range)
          return interval;
      }

      return $class.DEFAULT_INTERVAL;
    },

    _setSelectedInterval: function(interval) {
      preferences.set('charts.line.range', interval.key);
      this.reload();
    },

    _dataDidChange: function() {
      var summaries = this.dataSource.get('data').summaries,
          spendingData = [],
          earningsData = [];

      for (var i = 0; i < summaries.length; i++) {
        var summary = summaries[i],
            x = date.parse(summary.interval.start);

        spendingData[i] = {
          x: x,
          y: number.parse(summary.spending.value)
        };

        earningsData[i] = {
          x: x,
          y: number.parse(summary.earnings.value)
        };
      }

      this.chart.clearSeries();

      this.chart.addSeries({
        color: 'rgba(24,164,213,0.5)',
        data: spendingData
      });

      this.chart.addSeries({
        color: 'rgba(119,204,153,0.5)',
        data: earningsData
      });
    }
  });
});

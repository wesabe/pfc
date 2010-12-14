wesabe.$class('views.pages.DashboardPage', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.date
  var date = wesabe.lang.date;
  // import wesabe.lang.number
  var number = wesabe.lang.number;

  $.extend($class.prototype, {
    init: function() {
      wesabe.views.shared
        .setCurrentTab("dashboard")
        .setPageTitle("Dashboard")
        .enableDefaultAccountsSearch()
        .enableDefaultAccountSidebarBehavior();

      var targetDataSource = new wesabe.data.TargetDataSource();
      targetDataSource.set('cachingEnabled', true);
      this._targets = new wesabe.views.widgets.targets.TargetWidget($("#spending-targets"), targetDataSource);

      var width = 630,
          height = 185;

      var sveContainer = $('<div></div>').width(width).height(height).css('background-color', 'white');
      sveContainer.css({top: 0, left: 0, position: 'absolute', zIndex: 1000});
      var sve = new wesabe.views.widgets.SeriesChart(sveContainer);
      sve.set('width', width);
      sve.set('height', height);
      sve.set('chartInset', {top: 0, bottom: 35, left: 60, right: 60});
      sve.set('xValueFormatter', {
        format: function(date, index, count) {
          date = wesabe.lang.date.parse(date);

          return wesabe.lang.date.format(date,
            (index == 0 || index == count - 1) ? 'NNN\nyyyy' :
                                                 'NNN');
        }
      });
      sve.set('yValueFormatter', wesabe.lang.money.formatterWithOptions({precision: 0}));
      sveContainer.appendTo(document.body);

      var dataSource = new wesabe.data.TransactionSummaryDataSource();
      dataSource.set('startDate', wesabe.lang.date.addMonths(new Date(), -12));
      dataSource.set('endDate', new Date());
      dataSource.set('type', 'monthly');
      dataSource.requestDataAndSubscribe(function() {
        sve.clearSeries();

        var summaries = dataSource.get('data').summaries,
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

        sve.addSeries({
          color: 'rgba(24,164,213,0.5)',
          data: spendingData
        });

        sve.addSeries({
          color: 'rgba(119,204,153,0.5)',
          data: earningsData
        });
      });
    }
  });
});

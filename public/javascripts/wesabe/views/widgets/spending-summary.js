jQuery(function($) {
  var date = wesabe.lang.date;
  var money = wesabe.lang.money;
  var string = wesabe.lang.string;
  var math = wesabe.lang.math;
  var array = wesabe.lang.array;
  var shared = wesabe.views.shared;
  var prefs = wesabe.data.preferences;
  var root = $('#spending-summary');

  var defaultCurrency = prefs.defaultCurrency();

  var ZERO_SUMMARY = { count: 0, value: 0, display: money.format(0, {currency: defaultCurrency}) };

  var behaviors = wesabe.provide('views.spendingSummaryWidget', {
    root: {
      init: function() {
        var self = $(this);

        self.fn("controlPanel")
          .include(behaviors.controlPanel)
          .bind("updated", function() { self.fn("update"); })
          .fn("init");

        self.fn('dateRangeNav')
          .include(behaviors.dateRangeNav)
          .bind("currentDateRangeChanged", function(e) { self.fn("update", e.callback); })
          .fn("init");

        self.fn('tagsList')
          .include(behaviors.tagsList)
          .fn("init");

        self.fn("spendingOrEarnings", "spending"); // default

        self.kvobserve('spending-earnings', function() {
          self.fn("title").text(string.ucfirst(self.fn('spendingOrEarnings')));
          self.fn("update");
        });

        $.address.change(function() {
          self.fn('_restoreState');
        });

        if ($.address.path() == "/trends") $.address.value("/trends/spending");
        else self.fn('_restoreState');

        $('#trends-summary li a').each(function() {
          new wesabe.views.widgets.HistoryLink($(this));
        });

        return self;
      },

      _restoreState: function() {
        var match = $.address.path().match(/^\/trends\/(spending|earnings)$/),
            mode = match && match[1];

        if (mode) {
          $(this).fn("spendingOrEarnings", mode);

          $('#trends-summary li').each(function() {
            var li = $(this);
            if (li.hasClass(mode)) li.addClass('on');
            else li.removeClass('on');
          });

          var viewportMinY = document.body.scrollTop,
              viewportMaxY = viewportMinY + window.innerHeight,
              destination = $('#spending-summary').offset().top;

          if (destination < viewportMinY || destination > viewportMaxY)
            $("body:not(:animated)").animate({ scrollTop: destination-20}, 500 );
        }
      },

      title: function() {
        return $(".spending-earnings", this);
      },

      spendingOrEarnings: $.getsetdata('spending-earnings'),

      btaTags: function(dateRange) {
        return $(this).fn("getCache", "bta-" + $(this).fn("spendingOrEarnings"), dateRange);
      },

      useBta: function() {
        return $(this).fn("controlPanel").fn("state", "tagScope") == "tag-scope-top-button";
      },

      loading: function(key, flag) {
        if (!flag) {
          return $(this).data("loading-" + key);
        }
        else {
          $(this).data("loading-" + key, flag);
        }
      },

      update: function(callback) {
        $(this).fn("loadData", callback);
      },

      loadData: function(callback) {
        var self = $(this);

        var bta = self.fn("useBta");

        var currentDateRange = self.fn("dateRangeNav").fn("currentDateRange");
        var comparisonDateRange;
        if (self.fn("controlPanel").fn("state", "compare") != 'compare-none-button') {
          comparisonDateRange = self.fn("dateRangeNav").fn("previousDateRange");
        }

        self.fn("loadTags", currentDateRange);

        if (comparisonDateRange)
          self.fn("loadTags", comparisonDateRange);

        if (bta)
          self.fn("loadBtaTags", currentDateRange);

        var pollInterval = 25; // ms
        var ttl = 10 * date.SECONDS / pollInterval;

        function poll() {
          var currentData = self.fn('getCache', 'se', currentDateRange);
          var comparisonData;
          var btaTags;
          if (comparisonDateRange)
            comparisonData = self.fn('getCache', 'se', comparisonDateRange);
          if (bta)
            btaTags = self.fn("btaTags", currentDateRange);

          if (currentData &&
              (comparisonData || !comparisonDateRange) &&
              (btaTags || !bta))
          {
            self.fn("_onDataLoaded", self.fn('mergeData', currentData, comparisonData, btaTags), callback);
          } else if (ttl-- > 0) {
            setTimeout(poll, 25);
          } else {
            // show an error that we timed out?
          }
        }

        poll();
      },

      _onDataLoaded: function(data, callback) {
        // filter out zero spending/earnings
        data = $.grep(data, function(row) {
          return row["current"]["value"] != 0 || (row["comparison"] && row["comparison"]["value"] != 0);
        });
        return $(this).fn('tagsList').fn('update', data, callback);
      },

      mergeData: function(currentData, comparisonData, btaTags) {
        var dataHash = {};
        var btaTagHash = {};

        var se = root.fn("spendingOrEarnings");

        // create bta tag lookup hash
        if (btaTags) {
          for (var i = 0; i < btaTags.length; i++) {
            btaTagHash[btaTags[i]] = 1;
          }
        }

        $.each(currentData, function(_, row) {
            var name = row["tag"]["name"];
            if (btaTags && !btaTagHash[name]) return; // ignore any non-bta tags if we're using bta
            dataHash[name] = dataHash[name] || {};
            dataHash[name]["current"] = row[se];
            if (comparisonData)
              dataHash[name]["comparison"] = ZERO_SUMMARY;
          });

        if (comparisonData) {
          $.each(comparisonData, function(_, row) {
              var name = row["tag"]["name"];
              if (btaTags && !btaTagHash[name]) return; // ignore any non-bta tags if we're using bta
              dataHash[name] = dataHash[name] || {};
              dataHash[name]["comparison"] = row[se];
              dataHash[name]["current"] = dataHash[name]["current"] || ZERO_SUMMARY;
            });
        }

        var data = [];
        for (tag in dataHash) {
          var row = { name: tag,
                      current: dataHash[tag]["current"] };

          if (comparisonData)
            row.comparison = dataHash[tag]["comparison"];

          data.push(row);
        }

        return data;
      },

      loadBtaTags: function(dateRange) {
        var self = $(this);

        if (!self.fn("btaTags", dateRange)) {
          var se = self.fn("spendingOrEarnings");
          if (!self.fn("loading", "bta-" + se + dateRange)) {
            self.fn("loading", "bta-" + se + dateRange, true);
            $.ajax({
              url: '/transactions/rational.xml',
              data: { start_date: date.toParam(dateRange[0]),
                      end_date: date.toParam(dateRange[1]),
                      filter_transfers: true,
                      compact: true,
                      currency: defaultCurrency,
                      type: se },
              dataType: 'xml',
              cache: false,
              success: function(data){
                self.fn("loading", "bta-" + se + dateRange, false);
                self.fn("_onBtaTagsLoaded", dateRange, data);
              },
              error: function(){ self.fn("_onTagsError"); }
            });
          }
        }
      },

      _onBtaTagsLoaded: function(dateRange, data) {
        var self = $(this);

        var tags = array.uniq(
          $.map($(data).find("tag > name"), function(el) {
            return $(el).text().split(/:/)[0]; // remove splits
          })
        );
        self.fn("setCache", "bta-" + self.fn("spendingOrEarnings"), dateRange, tags);
      },

      loadTags: function(dateRange) {
        var self = $(this);

        if (!self.fn("getCache", "se", dateRange)) {
          $.ajax({
            url: ['/data/analytics/summaries/tags',
                   date.toParam(dateRange[0]),
                   date.toParam(date.addDays(dateRange[1], 1)),
                   defaultCurrency].join('/'),
            dataType: 'json',
            cache: false,
            success: function(data){ self.fn("_onTagsLoaded", dateRange, data); },
            error: function(){ self.fn("_onTagsError"); }
          });
        }
        return self;
      },

      _onTagsLoaded: function(dateRange, data) {
        // FIXME: massage the data so that the value of each tag is a number rather than a string
        // I'm told that a currently unreleased version of BRCM corrects this for us, so remove this code when that's in place
        data = data["summaries"];
        for (var i = 0; i < data.length; i++) {
          data[i]["spending"]["value"] = parseFloat(data[i]["spending"]["value"]);
          data[i]["earnings"]["value"] = parseFloat(data[i]["earnings"]["value"]);
        }
        $(this).fn("setCache", 'se', dateRange, data);
      },

      _onTagsError: function() {
        /* do something? */
        return $(this);
      },

      controlPanel: function() { return $("#control-panel", this); },

      dateRangeNav: function() { return $("#date-range-nav", this); },

      tagsList: function() { return $("#tags-list", this); },

      cacheKey: function(name, dateRange) {
        return [name, dateRange[0].valueOf(), dateRange[1].valueOf()].join('-');
      },

      getCache: function(name, dateRange) {
        var cacheKey = $(this).fn("cacheKey", name, dateRange);
        return $(this).data("tagsCache-"+cacheKey);
      },

      setCache: function(name, dateRange, data) {
        var cacheKey = $(this).fn("cacheKey", name, dateRange);
        $(this).data("tagsCache-"+cacheKey,  data);
      }
    },

    // FIXME: extract this functionality to a generic ControlPanel class that can be reused elsewhere
    controlPanel: (function() {
      var buttonGroups = {
        tagScope:  ["tag-scope-all-button","tag-scope-top-button"],
        compare:   ["compare-none-button","compare-previous-button","compare-average-button"],
        dateRange: ["date-range-month-button","date-range-quarter-button","date-range-year-button","date-range-custom-button"]
      };

      return {
        init: function() {
          var self = $(this);

          // set up click handler so that clicking one button in a group will turn the others off
          for (var key in buttonGroups) {
            var buttonIds = buttonGroups[key],
                buttons = [],
                buttonGroup;

            for (var i = 0; i < buttonIds.length; i++)
              buttons.push(new wesabe.views.widgets.Button($('#'+buttonIds[i])));

            buttonGroup = new wesabe.views.widgets.ButtonGroup(buttons, {
              onSelectionChange: function(sender, button) {
                self.fn("fireUpdatedEvent", sender.key, button);
              }
            });

            buttonGroup.key = key;
            buttonGroup.selectButton(buttons[0]);
          }

          $("#custom-edit", self).dateRangePicker({
            onShow: function() {
              var dateRange = prefs.get("trends.summary.custom-date-range");
              if (dateRange) {
                dateRange = dateRange.split(":");
                this.startDate(dateRange[0]);
                this.endDate(dateRange[1]);
              }
            },

            onSave: function() {
              var startDate = this.startDateInput().val();
              var endDate = this.endDateInput().val();
              prefs.update("trends.summary.custom-date-range", startDate + ':' + endDate);
              root.fn("controlPanel").fn("fireUpdatedEvent", "dateRange", "date-range-custom-button");
            }
          });

          // special case for the custom date range button
          $("#date-range-custom-button", this).click(function() {
            if (!prefs.get("trends.summary.custom-date-range"))
              $("#custom-edit", self).fn("dateRangePicker").show();
          });
        },

        // return jQuery object for the given button
        button: function(id) { return $("#" + id, this); },

        // return current state of one or all all buttonGroups
        state: function(group) {
          var self = $(this);
          if (group) {
            for (var i in buttonGroups[group]) {
              var button = buttonGroups[group][i];
              if (self.fn("button", button).hasClass("on")) return button;
            }
          } else {
            var state = {};
            for (group in buttonGroups) {
              state[group] = self.fn("state", group);
            }
            return state;
          }
        },

        fireUpdatedEvent: function(group, button) {
          return $(this)
            .trigger("updated")
            .trigger(group + "Updated", button);
        },

        customDateRange: function() {
          var dateRange = prefs.get("trends.summary.custom-date-range");
          if (dateRange) {
            dateRange = dateRange.split(":");
            var startDate = date.parse(dateRange[0]);
            var endDate = date.parse(dateRange[1]);
            if (startDate && endDate)
              return [startDate, endDate];
          }
        }

      };
    })(),

    dateRangeNav: {
      init: function() {
        var self = $(this);

        // catch dateRangeUpdated event from the control panel so we can update ourselves
        root.fn("controlPanel")
          .bind("dateRangeUpdated", function(_, button) {
            self.fn("selectedDateRangeChanged", button);
          });

        // update ourselves whenever the currentDateRange changes
        self.kvobserve("currentDateRange", function(_, value) { self.fn("update", value); });

        // initialize current date range to today
        self.fn("currentDateRange", self.fn("calculateDateRange", new Date()));

        $(".left-arrow,.previous-date-range", this).click(function() {
          root.fn("tagsList").hide("slide", {direction:"right", useVisibility:true}, 500);
          self.fn("currentDateRange", self.fn("previousDateRange"),
            function() { root.fn("tagsList").show("slide", {direction:"left"}, 500);});
        });

        $(".right-arrow,.next-date-range", this).click(function() {
          root.fn("tagsList").hide("slide", {direction:"left", useVisibility:true}, 500);
          self.fn("currentDateRange", self.fn("nextDateRange"),
            function() {root.fn("tagsList").show("slide", {direction:"right"}, 500);});
        });

        return self;
      },

      calculateDateRange: function(d) {
        switch($(this).fn("selectedDateRange")) {
          case 1:
            return [date.startOfMonth(d), date.endOfMonth(d)];
          case 3:
            return [date.startOfQuarter(d), date.endOfQuarter(d)];
          case 12:
            return [date.startOfYear(d), date.endOfYear(d)];
          case "custom":
            return root.fn("controlPanel").fn("customDateRange") || $(this).fn("currentDateRange");
        }
      },

      selectedDateRange: function() {
        switch(root.fn("controlPanel").fn("state", "dateRange")) {
          case "date-range-month-button": return 1;
          case "date-range-quarter-button": return 3;
          case "date-range-year-button": return 12;
          case "date-range-custom-button": return "custom";
        }
      },

      currentDateRange: function(dateRange, callback) {
        var currentDateRange = $(this).kvo("currentDateRange");
        if (dateRange && dateRange != currentDateRange) {
          $(this).kvo("currentDateRange", dateRange);
          var evt = {type:"currentDateRangeChanged"};
          if (callback) evt.callback = callback;
          $(this).trigger(evt);
        } else {
          return currentDateRange;
        }
      },

      selectedDateRangeChanged: function(button) {
        root.fn("tagsList").fadeTo("fast", 0.3);
        $(this).fn("currentDateRange",
          $(this).fn("calculateDateRange", $(this).fn("currentDateRange")[0]),
          function() { root.fn("tagsList").fadeTo("fast", 1); });
      },

      previousDateRange: function() {
        var selectedDateRange = $(this).fn("selectedDateRange");
        var currentDateRange = $(this).fn("currentDateRange");

        if (selectedDateRange == "custom") {
          var timeSpan = currentDateRange[0].getTime() - currentDateRange[1].getTime();
          return [date.add(currentDateRange[0], timeSpan), date.add(currentDateRange[1], timeSpan)];
        } else {
          return $(this).fn("calculateDateRange",
            date.addMonths(currentDateRange[0], -selectedDateRange));
        }
      },

      nextDateRange: function() {
        var selectedDateRange = $(this).fn("selectedDateRange");
        var currentDateRange = $(this).fn("currentDateRange");

        if (selectedDateRange == "custom") {
          var timeSpan = currentDateRange[1].getTime() - currentDateRange[0].getTime();
          return [date.add(currentDateRange[0], timeSpan), date.add(currentDateRange[1], timeSpan)];
        } else {
          return $(this).fn("calculateDateRange",
            date.addMonths(currentDateRange[0], selectedDateRange));
        }
      },

      update: function(currentDateRange) {
        var self = $(this);
        var dateRangeText;
        switch(self.fn("selectedDateRange")) {
          case 1:
            dateRangeText = date.format(currentDateRange[0], "MMM yyyy"); break;
          case 3:
          case "custom":
            dateRangeText = date.shortFriendlyFormat(currentDateRange[0]) + ' - ' + date.shortFriendlyFormat(currentDateRange[1]); break;
          case 12:
            dateRangeText = currentDateRange[0].getFullYear();
        }
        $(".current-date-range", self).text(dateRangeText);

        if (!date.before(date.startOfDay(currentDateRange[1]), date.startOfDay(new Date()))) {
          $(".next-date-range,.right-arrow", self).hide();
        } else {
          $(".next-date-range,.right-arrow", self).show();
        }
      }
    },

    tagsList: {
      init: function() {
        return $(this);
      },

      maxAmount: $.getsetdata('maxAmount'),

      tags: function() {
        return $(this).find("li:not(.template)");
      },

      clear: function() {
        return $(this).fn('tags').remove();
      },

      update: function(data, callback) {
        var self = $(this);

        self.removeClass("spending").removeClass("earnings").addClass(root.fn("spendingOrEarnings"));
        self.fn('clear');
        if (data.length == 0) {
          $("#no-tags .type").text(root.fn("spendingOrEarnings"));
          $("#no-tags").show();
          self.hide();
        } else {
          $("#no-tags").hide();

          if (data[0]["comparison"]) {
            self.addClass("comparison");
          } else {
            self.removeClass("comparison");
          }
          // sort the array from high to low current value and get max amount
          data.sort(function(a,b) { return b["current"]["value"] - a["current"]["value"]; });
          var currentValues = [];
          var comparisonValues = [];
          $.each(data, function(_, row) {
            currentValues.push(row["current"]["value"]);
            if (row["comparison"])
              comparisonValues.push(row["comparison"]["value"]);
          });
          var maxCurrent = math.max(currentValues);
          var maxComparison = math.max(comparisonValues) || 0;
          if (maxCurrent >= maxComparison) {
            self.fn("maxAmount", maxCurrent);
          } else {
            self.fn("maxAmount", maxComparison);
          }

          $.each(data, function(_, item) { self.fn('add', item); });
          root.fn("dateRangeNav").show();

          self.css("visibility","visible").show();

          if (callback) callback();
          // ensure that we aren't left in a faded state
          self.fadeTo("fast", 1);
        }
      },

      add: function(data) {
        return $(".template", this).clone().removeClass("template")
          .include(behaviors.tag)
          .fn("init")
          .fn("update", data)
          .appendTo(this);
      }
    },

    tag: (function() {
      var maxAmount;

      return {
        init: function() {
          var self = $(this);

           maxAmount = root.fn("tagsList").fn("maxAmount");

          // <HACK>
          // Works around what may be a jQuery/Chrome compatibility issue
          // that happens when doing $('.tag-name, .tag-amount, .tag-bar-spent', self).
          var clickables = $([])
            .add($('.tag-name', self))
            .add($('.tag-amount', self))
            .add($('.tag-bar-spent', self));

          clickables.click(function() {
            shared.navigateTo('/tags/'+encodeURIComponent(self.fn("data")["name"].replace(/\s/g, '%20')));
          });
          // </HACK>

          return self;
        },

        data: $.getsetdata("data"),

        update: function(data) {
          $(this).fn('data', data)
            .fn('redraw');
          return $(this);
        },

        // position the bar
        redraw: function() {
          var self = $(this);
          var data = self.fn('data');

          $(".tag-name", this).text(data["name"]);
          $(".current > .tag-amount", this).text(data["current"]["display"]);
          if (data["comparison"]) {
            $(".comparison > .tag-amount", this).text(data["comparison"]["display"]);
          } else {
            $(".tag-bar-amount.comparison", this).hide();
          }

          var bars = ["current"];
          if (data["comparison"])
            bars.push("comparison");

          for (var i = 0; i < bars.length; i++) {
            var bar = bars[i];
            var percentFull = self.fn("percentFull", data[bar]["value"]);
            var barPos = 400 * percentFull - 400;
            if (barPos > 0) barPos = 0;
            $(".tag-bar-amount." + bar, this).css('background-position', barPos + 'px 4px');

            var tagAmount = $("." + bar + " > .tag-amount", this);
            var textLen = tagAmount.text().length;
            if (barPos + 405 < textLen * 8) {
              tagAmount.addClass("outside").css({"margin-left": barPos + 395});
            }
          }

          return self;
        },

        percentFull: function(amount) {
          if (maxAmount == 0) return 0;
          return amount / maxAmount;
        }
      };
    })()
  });

  root.include(behaviors.root).fn('init');
});

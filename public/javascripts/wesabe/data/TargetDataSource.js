wesabe.$class('wesabe.data.TargetDataSource', wesabe.data.BaseDataSource, function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.date
  var date = wesabe.lang.date;

  $.extend($class.prototype, {
    /**
     * The start date to get target data for.
     *
     * @type {date}
     */
    startDate: null,

    /**
     * The end date to get target data for.
     *
     * @type {date}
     */
    endDate: null,

    /**
     * Selects the current month as the date range for this data source.
     */
    selectCurrentMonth: function() {
      this.selectMonth(new Date());
    },

    /**
     * Sets the start and end dates to the start and end of the month containing {dateInMonth}.
     *
     * @param {!date} dateInMonth
     */
    selectMonth: function(dateInMonth) {
      this.startDate = date.startOfMonth(dateInMonth);
      this.endDate = date.endOfMonth(dateInMonth);
    },

    /**
     * Gets the default set of options to pass to {jQuery.ajax}.
     */
    requestOptions: function() {
      return $.extend($super.requestOptions.apply(this, arguments), {
        url: '/targets',
        data: {
          start_date: date.toParam(this.get('startDate')),
          end_date: date.toParam(this.get('endDate'))
        }
      });
    },

    /**
     * Updates the target with the given tag to the given amount.
     *
     * @param {!string} tag
     * @param {!number} amount
     * @param {?function(object, string)} callback Handler for the XHR response.
     * @param {?object} context `this' inside callback
     */
    update: function(tag, amount, callback, context) {
      $.put("/targets/" + tag, { amount: amount },
        callback && function(){ callback.apply(context || this, arguments) },
        "json");
    },

    /**
     * Updates the target with the given tag to the given amount.
     *
     * @param {!string} tag
     * @param {!number} amount
     * @param {?function(object, string)} callback Handler for the XHR response.
     * @param {?object} context `this' inside callback
     */
    create: function(tag, amount, callback, context) {
      $.post("/targets", { tag: tag, amount: amount },
        callback && function(){ callback.apply(context || this, arguments) },
        "json");
    },

    /**
     * Updates the target with the given tag to the given amount.
     *
     * @param {!string} tag
     * @param {!number} amount
     * @param {?function(object, string)} callback Handler for the XHR response.
     * @param {?object} context `this' inside callback
     */
    remove: function(tag, amount, callback, context) {
      // this is not using DELETE /targets/:tag because it seems just about impossible to get escaped
      // data in urls through both Apache and Mongrel, so we just send it as part of the POST body.
      $.post("/targets/delete", { tag: tag },
        callback && function(){ callback.apply(context || this, arguments) },
        "json");
    }
  });
  $class.sharedDataSource = new $class();
});

(function($) {
  var string = wesabe.lang.string;
  var date = wesabe.lang.date;

  function DateRangePicker(trigger, options) {
    this.options = {
      dialog: "#date-range-dialog", // dialog element
      startDateInput: "input[name='start-date']",
      endDateInput: "input[name='end-date']",
      saveButton: ".save",
      cancelButton: ".cancel",
      startDateError: ".start-date-error",
      endDateError: ".end-date-error",
      error: {
        noStartDate: "Please enter a starting date",
        noEndDate: "Please enter an ending date",
        invalidStartDate: "The starting date is not in a valid format",
        invalidEndDate: "The ending date is not in a valid format"
      },
      onInit: function() {},
      onShow: function() {},
      onSave: function() {},
      onCancel: function() { $("form", this.dialog).reset();},
      onError: function() {},
      changeMonth: true,
      changeYear: true,
      validateDates: true,
      allowBlankDates: false
    };
    $.extend(this.options, options || {});

    this.onInit = this.options.onInit;
    this.onShow = this.options.onShow;
    this.onSave = this.options.onSave;
    this.onCancel = this.options.onCancel;
    this.onError = this.options.onError;

    this.trigger = trigger;
    return this.init();
  }

  $.extend(DateRangePicker.prototype, {
    init: function() {
      var self = this;

      self.dialog = $(self.options.dialog);

      // bind the date pickers
      self.startDateInput().datepicker(self.options)
        .siblings('.ui-datepicker-trigger')
          .addClass('calendar');

      self.endDateInput().datepicker(self.options)
          .siblings('.ui-datepicker-trigger')
            .addClass('calendar');

      $(self.options.saveButton, self.dialog).click(function() { self.save(); });
      $(self.options.cancelButton, self.dialog).click(function() { self.cancel(); });

      self.trigger.click(function() {
        self.toggle();
      });

      self.onInit();

      return self;
    },

    startDateInput: function() {
      return $(this.options.startDateInput, this.dialog);
    },

    endDateInput: function() {
      return $(this.options.endDateInput, this.dialog);
    },

    startDateError: function(msg) {
      if (msg === undefined)
        return $(this.options.startDateError, this.dialog);
      else
        $(this.options.startDateError, this.dialog).text(msg);
    },

    endDateError: function(msg) {
      if (msg === undefined)
        return $(this.options.endDateError, this.dialog);
      else
        $(this.options.endDateError, this.dialog).text(msg);
    },

    startDate: function(value) {
      return this.getSetDate(this.startDateInput(), value);
    },

    endDate: function(value) {
      return this.getSetDate(this.endDateInput(), value);
    },

    clearDates: function() {
      this.startDate('');
      this.endDate('');
    },

    isStartDateBlank: function() {
      return string.blank(this.startDateInput().val());
    },

    isEndDateBlank: function() {
      return string.blank(this.endDateInput().val());
    },

    getSetDate: function(input, value) {
      if (value === undefined) {
        if (string.blank(input.val()))
          return null;
        else
          return date.parse(input.val());
      } else {
        var d = typeof value == "string" ? value : $.datepicker.formatDate($.datepicker._defaults.dateFormat, value);
        return input.val(d);
      }
    },

    save: function() {
      var errors = {};
      var startDate = this.startDate();
      var endDate = this.endDate();
      if (this.options.validateDates) {
        if (!this.options.allowBlankDates) {
          if (this.isStartDateBlank())
            errors.startDate = this.options.error.noStartDate;
          if (this.isEndDateBlank())
            errors.endDate = this.options.error.noEndDate;
        }

        if (!errors.startDate && !this.isStartDateBlank() && !startDate)
          errors.startDate = this.options.error.invalidStartDate;
        if (!errors.endDate && !this.isEndDateBlank() && !endDate)
          errors.endDate = this.options.error.invalidEndDate;

        this.startDateError().hide();
        this.endDateError().hide();
        if (errors.startDate) {
          this.startDateError(errors.startDate);
          this.startDateError().show();
        }
        if (errors.endDate) {
          this.endDateError(errors.endDate);
          this.endDateError().show();
        }
        if (errors.startDate || errors.endDate) {
          this.onError();
          return;
        }
      }
      // silently reverse the dates if they're in the wrong order
      if (startDate && endDate && startDate.getTime() > endDate.getTime()) {
        this.startDate(endDate);
        this.endDate(startDate);
      }
      this.onSave();
      return this.hide();
    },

    cancel: function() {
      this.onCancel();
      return this.hide();
    },

    show: function() {
      this.onShow();
      return this.dialog.show();
    },

    hide: function() {
      this.startDateError().hide();
      this.endDateError().hide();
      this.startDateInput().datepicker("hide", "fast");
      this.endDateInput().datepicker("hide", "fast");
      return this.dialog.hide();
    },

    toggle: function() {
      return this.dialog.is(":visible") ? this.hide() : this.show();
    }
  });

  $.fn.dateRangePicker = function(options) {
    return this.each(function() {
      var dateRangePicker = new DateRangePicker($(this), options);
      $(this).fn({ dateRangePicker: function() { return dateRangePicker; } });
    });
  };

})(jQuery);
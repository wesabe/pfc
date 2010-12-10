jQuery(function($) {
  function resetExportVisibility() {
    if (page.search) $('#export').hide();
    else $('#export').show();
    // CSV/XLS aren't supported yet for investment accounts
    var account = page.selection.getByClass(wesabe.views.widgets.accounts.Account)[0];
    if (account && account.isInvestment()) {
      $("#export-format option[value=csv],option[value=xls]").hide();
      $("#export-format option[value=json]").attr('selected', true);
    } else {
      $("#export-format option[value=csv],option[value=xls]").show();
      $("#export-format option[value=csv]").attr('selected', true);
    }
  }

  resetExportVisibility();
  $(page).bind("state-changed", resetExportVisibility);

  $("#export-link").dateRangePicker({
    dialog: '#export-dialog',
    allowBlankDates: true,
    onInit: function() {
      var picker = this;
      $("#date-range-select").change(function() {
        var year = new Date().getFullYear();
        $("#custom-date-range").slideUp('fast');
        switch($(this).val()) {
          case 'all':
            picker.clearDates();
            break;
          case 'tax':
            picker.startDate(new Date(year-1,0,1));
            picker.endDate(new Date(year-1,11,31));
            break;
          case 'ytd':
            picker.startDate(new Date(year,0,1));
            picker.endDate(new Date());
            break;
          case 'custom':
            picker.clearDates();
            $("#custom-date-range").slideDown('fast');
        }
      });
    },

    onShow: function() {
      $("#custom-date-range .notification.error").hide();

      var header = $("#account-transactions").data("_header");
      $("#export-source").text(header.display.nodeValue + " " + header.subtitle.nodeValue);

      if (page.start || page.end) {
        this.startDate(page.start);
        this.endDate(page.end);
        $("#date-range-select").val("custom");
        $("#custom-date-range").show();
      }
      else {
        $("#date-range-select").val("all");
        $("#custom-date-range").hide();
      }
    },

    onSave: function() {
      var p = wesabe.lang.params;

      var startDate = this.startDate();
      var endDate = this.endDate();

      var params = page.paramsForCurrentSelection();
      var currency = params.currency || wesabe.data.preferences.defaultCurrency();
      delete params.currency;

      // TODO: handle export from search results
      p.remove(params, 'offset');
      p.remove(params, 'limit');
      var format = $("#export-format").val();
      p.set(params, 'format', format);

      if (startDate)
        p.set(params, 'start', wesabe.lang.date.toParam(startDate));

      if (endDate)
        p.set(params, 'end', wesabe.lang.date.toParam(wesabe.lang.date.addDays(endDate, 1)));

      var account = page.selection.getByClass(wesabe.views.widgets.accounts.Account)[0];
      var uri = '/data/' + (account && account.isInvestment() ? 'investment-' : '') + 'transactions/' + currency + '?' + $.param(params);
      // open new window only for non-attachment downloads
      if (format == 'json' || format == 'xml')
        window.open(uri);
      else
        window.location.href = uri;
    },

    onError: function() {
      $("#custom-date-range .notification.error").show();
    }
  });
});

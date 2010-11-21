jQuery(function($) {

var MerchantAutocompleter = function(input, options, callback) {
  return this.init(input, options, callback);
}
MerchantAutocompleter.user_list = [];
MerchantAutocompleter.public_list = [];
MerchantAutocompleter.checks = [];
MerchantAutocompleter.loadMerchants = function() {
  $.ajax({url: '/merchants/my', dataType: 'json',
    success: function(data) { MerchantAutocompleter.user_list = data; }
  });
  $.ajax({url: '/merchants/public', dataType: 'json',
    success: function(data) { MerchantAutocompleter.public_list = data; }
  });
};

MerchantAutocompleter.isReady = function() {
  return MerchantAutocompleter.user_list.length && MerchantAutocompleter.public_list.length
};
MerchantAutocompleter.loadMerchants();
MerchantAutocompleter.prototype = {
  autocomplete: null,

  defaults: {
    queryDelay: 0,
    maxResultsDisplayed: 10,
    queryMatchContains: false,
    useIFrame: true,
    footer: null,
    showChecks: false,
    txactionURI: null
  },

  init: function(input, options, callback) {
    // YUI wants a container for the autocomplete, so create one
    var container = $('<div></div>');
    // explicitly set the container width to that of the element
    // assumes width and padding are in px
    if (input.css("width")) {
      var width = parseInt(input.css("width").replace('px',''));
      if (width > 0) {
        $.each(["padding-left", "padding-right"], function(_,attr) {
          width = width + parseInt(input.css(attr).replace('px',''));
        });
        container.css("width", width + "px");
      }
    }
    input.wrap('<div class="merchant-autocomplete"></div>"');
    input.after(container);

    this.autocomplete = new YAHOO.widget.AutoComplete(input[0], container[0],
      new YAHOO.util.FunctionDataSource(this.doQuery), options);

    if (options.footer) {
      this.autocomplete.setFooter('<div class="yui-ac-tip">' + options.footer + '</div>');
    }

    this.autocomplete.itemSelectEvent.subscribe(
      function(self, item, data) {
        input.focus();
        if (callback)
          callback(data);
      });

    // make the user's merchants bold
    this.autocomplete.formatResult = function(oResultData, sQuery, sResultMatch) {
      var sMarkup = (sResultMatch) ? sResultMatch : "";
      if (oResultData[1] == 0)
        sMarkup   = ["<b>", sMarkup, "</b>"].join('');
      return sMarkup;
    };

    if (options.showChecks) {
      this.loadChecks(options.txactionURI);
    }
  },

  doQuery : function(sQuery) {
    var results = [],
        klass = MerchantAutocompleter,
        i;

    // suggest checks if there are checks and there's a '-' query
    if (klass.checks.length >= 1 && sQuery === "-") {
      for (i=0; i < klass.checks.length; i++) {
        results.push([klass.checks[i],1]);
      }
      return results;
    }

    // finally search if if there's a query string
    sQuery = sQuery.toLowerCase();
    for (i=0; i < klass.user_list.length; i++) {
      var sIndex = encodeURIComponent(klass.user_list[i]).toLowerCase().indexOf(sQuery);
      if (sIndex == 0) {
        results.push([klass.user_list[i],0]);
      }
    }

    for (i=0; i < klass.public_list.length; i++) {
      var sIndex = encodeURIComponent(klass.public_list[i]).toLowerCase().indexOf(sQuery);
      if (sIndex == 0) {
        results.push([klass.public_list[i],1]);
      }
    }

    return results;
  },

  loadChecks: function(txactionURI) {
    var self = this;
    $.ajax({
      url: txactionURI+'/merchant_list_checks',
      dataType: 'json',
      success: function(data) {
        MerchantAutocompleter.checks = data;
        self.autocomplete.sendQuery("-");
      }
    });
  }
};

$.fn.extend({
  merchantAutocomplete: function(options, callback) {
    options = $.extend({}, MerchantAutocompleter.defaults, options);

    return this.each(function() {
      var self = $(this);
      var autocompleter = new MerchantAutocompleter(self, options, callback);
      self.data("autocompleter", autocompleter);
    });
  }
});

});

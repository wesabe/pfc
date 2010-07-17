wesabe.provide('views.shared', {
  setCurrentTab: function(tab) {
    $("#global-nav .current-tab").removeClass("current-tab");
    $("#nav-" + tab).addClass("current-tab");
    return this;
  },

  setPageTitle: function(title) {
    document.title = "Wesabe: " + title;
    return this;
  },

  navigateTo: function(location) {
    this.navigating = true;
    window.location = location;
    return this;
  },

  historyHash: function(parts) {
    var hash;

    if (typeof parts == 'string')
      parts = [parts];

    parts = parts.sort();
    for (var i = 0; i < parts.length; i++)
      parts[i] = encodeURIComponent(parts[i]
        // expand the hash part separator
        .replace(/,/g, '-comma-'))
        // unescape a few harmless characters to improve readability
        .replace(/%2f/gi, '/')
        .replace(/%3d/gi, '=');
    hash = parts.join(',');

    return hash;
  },

  historyParts: function(hash) {
    var parts = hash.split(',');

    for (var i = 0; i < parts.length; i++)
      parts[i] = decodeURIComponent(parts[i]).replace(/-comma-/g, ',');

    return parts;
  },

  addSearchListener: function(fn) {
    $('#nav-search').show();
    $("#searchform").submit(function(event) {
      event.preventDefault();
      fn();
    });
    return this;
  },

  enableDefaultAccountsSearch: function() {
    var self = this;
    self.addSearchListener(function(event) {
      self.navigateTo('/accounts/#/search/'+$('#query').val());
    });
    return self;
  },

  enableDefaultAccountSidebarBehavior: function() {
    var self = this;
    wesabe.ready('wesabe.views.widgets.accounts.__instance__', function(accounts) {
      accounts.getSelection().bind('changed', function(_, selection) {
        self.navigateTo('/accounts/#'+selection[0].getURI());
      });
    });
    return self;
  },

  enableDefaultTagSidebarBehavior: function() {
    var self = this;
    wesabe.ready('wesabe.views.widgets.tags.__instance__', function() {
      wesabe.views.widgets.tags.__instance__.getSelection().bind('changed', function(_, selection) {
        self.navigateTo('/accounts/#'+selection[0].getURI());
      });
    });
    return self;
  },

  populateAccountsTab: function() {
    var accountListColumn = $('#nav-accounts .menu-content');

    wesabe.data.accounts.sharedDataSource.requestDataAndSubscribe(function(data) {
      accountListColumn.children().remove();
      var linkTo = function(object) {
        return $('<a></a>')
          .attr('href', '/accounts#'+object.uri)
          .text(object.name)
          .click(function(){ $.historyLoad(object.uri); });
      };

      $.each(data['account-groups'], function(i, group) {
        $('<li class="menu-head"></li>')
          .append(linkTo(group))
          .appendTo(accountListColumn);

        $.each(group.accounts, function(j, account) {
          $('<li></li>')
            .append(linkTo(account))
            .appendTo(accountListColumn);
        });
      });
    });
  },

  loggedIn: $.getsetdata('loggedIn')
});

$(function(){
  if (wesabe.views.shared.loggedIn())
    wesabe.views.shared.populateAccountsTab();

  $('#forgot-password-link')
    .click(function() {
      window.location = this.href+'?email='+encodeURIComponent($('#email').val());
      return false;
    });

  $('a.hash-link').click(function() {
    var linkPath = this.href.replace(/^http(s)?:\/\/[^\/]+/,'');
    if (linkPath.indexOf(window.location.pathname) == 0) {
      var hash = linkPath.replace(/^.*?#/,'');
      $.historyLoad(hash);
      return false;
    }
  });

  // Highlight and show the sidebar link to this page if there is one
  $("#left a[href$='"+window.location.pathname+"']").parents("li:first").addClass("on")
    .parents("li.group").addClass("open");

  if ($('#accounts').length == 0) {
    // only set this up on non-accounts stuff, like Help or My Profile
    $("#left li.group h6, #left li.group .view").click(function(){
      $(this).parents("li:first").children("ul:first")
        .slideToggle("normal", function(){
          $(this).parents("li.group").toggleClass("open"); });
    });
  }

  // jQuery datepicker defaults
  $.datepicker.setDefaults({
    dateFormat: 'yy-mm-dd',
    defaultDate: null, // null means today
    duration:'fast',
    gotoCurrent:true,
    showAnim:'slideDown',
    showOn: 'both',
    yearRange: '-10:1'
  });
});

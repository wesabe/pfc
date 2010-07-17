(function($) {
ssu = {
  //
  // Internal methods
  //

  tmp: {},

  forced: window.location.search.match(/force=true/),

  log: function() {
    try {
      console.log.apply(console, arguments);
    } catch (e) { /* just swallow the fucker */ }
  },

  iframe: function() {
    return $("#ssu_iframe")[0].contentWindow;
  },

  cred: function() {
    return ssu.iframe().cred;
  },

  //
  // Link targets
  //

  tryAgain: function() {
    ssu.cancel(true);
  },

  cancel: function(tryAgain) {
    if (ssu.guid && !ssu.forced) {
      var url = '/credentials/destroy/'+ssu.guid;
      window.location.href = url+(tryAgain ? '?back=true' : '?intended_uri=/uploads/new');
    } else if (tryAgain) {
      // the standard way to reload a page, window.location.reload(), will cause a re-POST
      // warning/confirmation dialog to appear if any ajax POSTs were executed after the page
      // loaded the first time
      window.location.href = window.location.href;
    } else {
      window.location.href = '/uploads/new';
    }
  },

  //
  // UI methods
  //

  hideForm: function(callback) {
    $("#fi_form, #sq_form").hide();
    $("#fi_form, #sq_form").reset();
    if (callback) callback();
  },

  showSpinner: function() {
    $("#curtain").height($("#color_body").height()+30);
    $("#form_body, #help").hide();
    $("#curtain").fadeIn(500);
  },

  hideSpinner: function() {
    $("#curtain").fadeOut(function(){ $("#form_body, #help").show() });
  },

  showError: function(error, callback) {
    ssu.log('iframe error: ', error);
    ssu.adjustHeight("#iframe_error");
    ssu.hideForm(function() {
      $("#iframe_error").fadeIn(500, callback);
    });
    ssu.hideSpinner();
  },

  hideError: function(callback) {
    ssu.blur();
    $("#iframe_error, #sq_form").filter(':visible').fadeOut(250, function() {
      $("#fi_form").fadeIn(250, callback);
    });
  },

  showAuthError: function(what) {
    what = what || '#creds_invalid';
    ssu.log('auth error ', what);

    // hide the form
    ssu.hideForm();
      // then reveal the whole panel
    ssu.hideSpinner();
    $("#auth_error").show();

    // hide all the error types
    $('#auth_error .error_type').hide();
    ssu.adjustHeight("#auth_error");
    // and show the one we care about
    $(what).show();
  },

  hideAuthError: function() {
    $('#auth_error').fadeOut(250, function() {
      $('#fi_form').fadeIn(250, function() {
        ssu.blur();
      });
    });
  },

  showBankError: function() {
    var errordiv = ssu.forced ? '#bank_error_for_tester' : '#bank_error';
    ssu.adjustHeight(errordiv);

    // hide the spinner
    ssu.hideSpinner();
    // hide the cred form
    ssu.hideForm();
    // hide all the error types
    $('#auth_error .error_type').hide();
    // show the bank error
    $(errordiv).show();
  },

  hideBankError: function() {
    var errordiv = ssu.forced ? '#bank_error_for_tester' : '#bank_error';

    $(errordiv).fadeOut(250, function() {
      $('#fi_form').fadeIn(250, function() {
        ssu.blur();
      });
    });
  },

  // fix the height to be the same as the form to prevent jumping
  adjustHeight: function(elem) {
    var form_height = $('#fi_form').height();
    if (form_height > 0) {
      $(elem).height(form_height);
    }
  },

  showStatus: function(what) {
    $('#animation h1').hide();
    $(what || '#default_status').show();
  },

  blur: function() {
    $("input:visible:first").focus().blur();
  },

  //
  // Managing login fields to circumvent password managers
  //

  getLoginFields: function() {
    return $("#fi_account_credentials .cred_field");
  },

  loginFieldDictionary: {},

  startWatchingLoginFields: function() {
    ssu.getLoginFields().keyup(function(event) {
      if (event.keyCode == 13) return; // ENTER
      ssu.loginFieldDictionary[$(this).attr('name')] = $(this).val();
    });
  },

  getLoginFieldValues: function() {
    var values = {};
    ssu.getLoginFields().each(function() {
      values[$(this).attr('name')] = ssu.getLoginFieldValueForField(this);
    });
    return values;
  },

  getLoginFieldValueForField: function(field) {
    field = $(field);
    return ssu.loginFieldDictionary[field.attr('name')] || field.val();
  },

  getLoginFields: function() {
    return $("#fi_account_credentials .cred_field");
  },

  getLabelForLoginField: function(field) {
    return $('label[for="'+$(field).attr('id')+'"]');
  },

  getErrorSpanForField: function(field) {
    return ssu.getLabelForLoginField(field).find('.error_message');
  },

  clearErrorForField: function(field) {
    field = $(field);
    field.removeClass('has_error');
    ssu.getErrorSpanForField(field).hide();
  },

  showErrorForField: function(field, message) {
    field = $(field);
    field.addClass('has_error');
    ssu.getErrorSpanForField(field).html(message).show();
  },

  validateLoginFieldValues: function() {
    var fields = ssu.getLoginFields(),
        hasError = false;
    $.each(fields, function(i, field) {
      var result = ssu.validateLoginField(field);
      if (!result.isValid) {
        hasError = true;
        ssu.showErrorForField(field, result.errorMessage);
      } else {
        ssu.clearErrorForField(field);
      }
    });
    return !hasError;
  },

  validateLoginField: function(field) {
    if (!ssu.getLoginFieldValueForField(field)) {
      return {isValid: false, errorMessage: "cannot be blank"};
    } else {
      return {isValid: true};
    }
  },

  //
  // Event targets
  //

  submitCreds: function() {
    try {
      var valid = ssu.validateLoginFieldValues();
      ssu.log('valid? '+valid);
      if (!valid) {
        // user needs to fix something, so don't continue
        return false;
      }
      ssu.blur();
      ssu.showSpinner();
      user_creds = ssu.getLoginFieldValues();
      // HACK God damn it Safari
      // Can't call cred.process directly since that causes a
      // SECURITY_ERR: DOM Exception 18. It appears to be that if you directly
      // call (i.e. non-eval) something in another iframe with a different
      // domain EVEN THOUGH you have set document.domain on both pages, that
      // Safari considers the origin of that to be the domain of the page from
      // which the original javascript came, preventing Ajax from happening.
      //
      // So the bottom line is that these next two lines really should be this:
      //
      //   ssu.cred().process($("#fi_id"), user_creds);
      //
      // but this seems to be a decent workaround, despite the fact that
      // Safari's treatment of the above indicates that this may be exploiting
      // a bug in Safari's security model. *shrug*
      var credstring = ssu.cred().encode(user_creds);
      ssu.iframe().setTimeout("cred.process('"+$("#fi_id").val()+"', "+credstring+")", 1);
      return false;
    }
    catch(e) { ssu.showError(e); }
    finally { return false; }
  },

  submitQuestions: function() {
    try {
      ssu.showSpinner();
      // see above rant
      var answers = ssu.cred().encode(ssu.getSecurityQuestionAnswers());
      ssu.iframe().setTimeout("cred.answers('"+ssu.guid+"', '"+ssu.jobid+"', "+answers+")", 1);
    }
    catch(e) { ssu.showError(e); }
    finally { return false; }
  },

  getSecurityQuestionAnswers: function() {
    var sq_answers = [];
    $("#fi_security_questions .ssu-question").each(function() {
      var question = $(this).data("ssu-question");
      sq_answers.push({key: question.key, value: $(this).val(), persistent: question.persistent});
    });
    return sq_answers;
 },

  goToUploadPage: function(page) {
    if (ssu.forced && (page == "error"))
      return window.location = "/accounts";

    path = "/uploads/new/" + page + "?cred=" + ssu.guid;

    // if this is the second time we have tried to upload these creds, note that fact
    // so that we can display an appropriate error message, and delete the bad cred
    if (/second_try=true/.test(location.search)) { path += "&second_try=true"; }

    window.location = (ssu.location_host + path);
  },

  /**
   * An incrementing counter to make sure that security question ids are unique.
   *
   * @private
   */
  inputFieldIndex: 0,

  showSecurityQuestions: function(cred) {
    var data = cred.job.data;

    // clear the security questions
    $("#fi_security_questions").html('');

    // set the title and note, if applicable
    if (data.title) $("#sq_form .title").html(data.title);
    if (data.note)  $("#sq_form .note").html(data.note);

    // set the header and footer, if applicable
    var header = $("#sq_form .sq_header"),
        footer = $("#sq_form .sq_footer");
    header.add(footer).html(''); // clear them first
    if (data.header) header.append($('<p></p>').append(document.createTextNode(data.header)));
    if (data.footer) footer.append($('<p></p>').append(document.createTextNode(data.footer)));

    // write the security questions out into the security questions div
    $.each(data.questions, function(index, question) {
      var handler = ssu.questionHandlers[question.type] || ssu.questionHandlers.defaultHandler;
      $("#fi_security_questions").append($('<p></p>').append(handler(question)));
    });
    ssu.guid = cred.id;
    ssu.jobid = cred.job.id;

    // hide the cred entry form and show the security question form instead
    ssu.hideForm(function() {
      $('#sq_form').fadeIn(500, function() {
        ssu.hideSpinner();
      });
    });
  },

  //
  // Cred/job status management
  //

  checkCredStatus: function() {
    // show error if we have timed out
    if (ssu.tmp.timeout) { ssu.goToUploadPage("error"); }

    // call out for account cred status
    $.getJSON("/credentials/" + ssu.guid, ssu.handleCredResponse);
  },

  handleCredResponse: function(cred) {
    try {
      var oldVersion = (ssu.lastCredResponse && ssu.lastCredResponse.job.version) || 0,
          newVersion = cred.job.version;

      ssu.log('new=', newVersion, ' old=', oldVersion);
      if (!newVersion || (newVersion > oldVersion)) {
        ssu.log(cred.job.status, cred.job.result, cred);

        if (ssu.processCredResponse(cred)) {
          // run again in 2 seconds
          setTimeout(ssu.checkCredStatus, 2000);
          ssu.resetTimeout();
        }
      } else {
        ssu.log("Skipping already-handled status ("+cred.job.status+" "+cred.job.result+")");
        setTimeout(ssu.checkCredStatus, 2000);
      }
    } catch (ex) {
      ssu.log("Problem processing cred response: "+ex);
    } finally {
      ssu.lastCredResponse = cred;
    }
  },

  processCredResponse: function(cred) {
    var status  = cred.job.status,
        result  = cred.job.result,
        version = cred.job.version;

    if (status == 200) {
      // when the job has been completed
      if (cred.accounts.length > 0) {
        // if there are accounts, redirect to select page
        ssu.goToUploadPage("select");
      } else {
        // no accounts, so redirect to the error message
        ssu.goToUploadPage("error");
      }
      // don't keep polling for status
      return false;
    } else if (status == 401) {
      if (/^auth\.user\.invalid/.test(result)) {
        // if the username was entered incorrectly
        ssu.showAuthError('#user_invalid');
      } else if (/^auth\.pass\.invalid/.test(result)) {
        // if the password was entered incorrectly
        ssu.showAuthError('#pass_invalid');
      } else if (/^auth\.security\.invalid/.test(result)) {
        // if the security question was answered incorrectly
        ssu.showAuthError('#security_invalid');
      } else if (/^auth\.creds\.invalid/.test(result)) {
        // if some part of the credentials was entered incorrectly
        ssu.showAuthError('#creds_invalid');
      }
      // don't keep polling for status
      return false;
    } else if (status != 202) {
      // some other kind of error
      ssu.showBankError();
      // don't keep polling for status
      return false;
    } else if (/^suspended.missing-answer/.test(result)) {
      // if the job has unanswered security questions
      ssu.showSecurityQuestions(cred);
      // don't keep polling for status
      return false;
    } else {
      // not done yet, should we update the status?
      if (/^auth\./.test(result)) {
        // show that we're logging in
        ssu.showStatus('#auth_status');
      } else if (/^account\./.test(result)) {
        // show that we're downloading/uploading accounts
        ssu.showStatus('#account_status');
      }
      // keep polling for status
      return true;
    }
  },

  questionHandlers: {
    defaultHandler: function(question) {
      return ssu.questionHandlers.text(question);
    },

    text: function(question, type) {
      var index = ssu.inputFieldIndex++;
      var id = 'ssu-question-'+index;

      var label = $('<label></label>');
      var input = $('<input class="medium_text_field ssu-question" type="'+(type||'text')+'" autocomplete="off"/>');

      // hook up the label to the input field
      label.attr('for', id);
      input.attr('id', id);

      // set the label and make sure we store the key along with the input field
      label.append($('<em></em>').append(document.createTextNode(question.label)));
      input.data('ssu-question', question);

      return label.add(input);
    },

    choice: function(question) {
      var index = ssu.inputFieldIndex++;
      var id  = 'ssu-question-'+index;

      var label  = $('<label></label>');
      var select = $('<select class="medium_text_field ssu-question"></select>');

      // hook up the label to the select field
      label.attr('for', id);
      select.attr('id', id);

      // set the label and make sure we store the key along with the select field
      label.append($('<em></em>').append(document.createTextNode(question.label)));
      select.data('ssu-question', question);

      $.each(question.choices, function(index, choice) {
        select.append(
          $('<option/>')
            .val(choice.value)
            .append(document.createTextNode(choice.label)));
      });

      return label.add(select);
    },

    number: function(question) {
      // for now, just delegate to the text handler
      return ssu.questionHandlers.text(question);
    },

    password: function(question) {
      return ssu.questionHandlers.text(question, 'password');
    }
  },

  credCreated: function(guid) {
    ssu.location_host = window.location.protocol + "//" + window.location.hostname;
    ssu.guid = guid;

    ssu.resetTimeout();
    setTimeout(ssu.checkCredStatus, 6000);
  },

  resetTimeout: function() {
    if (ssu.tmp._runawayTimer) {
      clearTimeout(ssu.tmp._runawayTimer);
      delete ssu.tmp._runawayTimer;
    }

    ssu.tmp._runawayTimer = setTimeout(function() { ssu.tmp.timeout = true }, 3*60*1000);
  },

  keyStoreUrl: window.location.protocol + '//' + window.location.hostname + '/account_creds/create'
};


// called by ssu.wesabe.com
window.credCreated = function(guid) {
  ssu.credCreated(guid);
};


fi = {
  autocompleter: null,

  // When an FI link is clicked, put the FI name into a hidden form field
  //   and then submit the form.
  choose: function(link) {
    var text = $(link).text();
    $('#fi_name').val(text);
    $("#fi_choice").val(text);
    $("#fi_chooser").submit();
  },

  normalize: function(name) {
    // trim surrounding whitespace and make lowercase
    return name.replace(/(^\s*|\s*$)/g, '').toLowerCase();
  },

  compress: function(name) {
    // word characters only & case-insensitive
    return name.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();
  },

  match: function(search, name) {
    // case-insensitive, trim whitespace
    search = fi.normalize(search);
    name = fi.normalize(name);

    // 100% match
    if (search == name) return 1.0;

    // exact prefix match (1/2 bonus over raw % match)
    if (name.slice(0, search.length) == search)
      return (1 + parseFloat(search.length) / name.length) / 2;

    var cname = fi.compress(name), csearch = fi.compress(search);

    // compressed prefix search (1/3 bonus over raw % match)
    if (cname.slice(0, csearch.length) == csearch)
      return (1 + 2*parseFloat(csearch.length) / cname.length) / 3;

    // compressed substring match (inflated % character match)
    if (cname.indexOf(csearch) != -1) return Math.sqrt(parseFloat(csearch.length) / cname.length);

    // Quicksilver-like start of words search (raw % character match)
    var pattern = [];
    for (var i = 0; i < csearch.length; i++) {
      pattern.push(csearch.charAt(i));
    }
    pattern = new RegExp(pattern.join('(.*\\s)?'), 'i');
    if (pattern.test(name)) return parseFloat(csearch.length) / cname.length;

    // no match
    return 0.0;
  },

  sort: function(array) {
    return fi.quicksort(array, 0, array.length);
  },

  quicksort: function(array, begin, end) {
    if (end-1 > begin) {
      var pivot = begin + Math.floor(Math.random()*(end-begin));

      pivot = fi.partition(array, begin, end, pivot);

      fi.quicksort(array, begin, pivot);
      fi.quicksort(array, pivot+1, end);
    }
    return array;
  },

  partition: function(array, left, right, pivotIndex) {
    var tmp;

    var pivotValue = array[pivotIndex];
    // Move pivot to end
    tmp = array[pivotIndex];
    array[pivotIndex] = array[right-1];
    array[right-1] = tmp;

    var storeIndex = left;
    for (var i = left; i < right; i++) {
      // console.log('comparing ', array[i], ' with ', pivotValue);
      if (array[i].rank > pivotValue.rank) {
        tmp = array[i];
        array[i] = array[storeIndex];
        array[storeIndex] = tmp;
        storeIndex++;
      }
    }
    // Move pivot to its final place
    tmp = array[storeIndex];
    array[storeIndex] = array[right-1];
    array[right-1] = tmp;
    return storeIndex;
  },

  init_autocompleter: function(field_id, results_id) {
    var fi_list;

    // Get this user's list of FI names from Wesabe
    $.ajax({url: "/financial-institutions.json", async: false, dataType: "json",
      success: function(fi_names) {
        fi_list = new YAHOO.widget.DS_JSFunction(function(search) {
          var fis = [];
          // restrict relevance to above threshold (tops out at 15%)
          var threshold = Math.min(3, search.length) / 20;

          // YUI seems to pass it in uri-encoded
          search = unescape(search);

          // collect matching FIs above threshold
          for (var i = 0; i < fi_names.length; i++) {
            var rank = fi.match(search, fi_names[i]);
            if (rank > threshold) fis.push({
              rank: rank,
              name: fi_names[i]
            });
          }

          // sort by match rank
          fi.sort(fis);

          // extract just the name
          for (var i = 0; i < fis.length; i++) {
            fis[i] = fis[i].name;
          }

          return fis;
        });

        // Fire up the autocompleter
        fi.autocompleter = new YAHOO.widget.AutoComplete(field_id, results_id, fi_list,
          { highlightClassName: "selected", forceSelection: false, alwaysShowContainer: true,
            queryDelay: 0, maxResultsDisplayed: 50 });

        // Make FI results into links rather than just text
        fi.autocompleter.formatResult = function(result, query) {
          return unescape("%3Ca href='/uploads/new/choose?fi_name=") + result + unescape("' onclick='fi.choose(this);return false;'%3E") + result + unescape("%3C/a%3E");
        };

        // Update the "results for X" text at the top of the results list
        fi.autocompleter.dataRequestEvent.subscribe(function(e, args){
          query = args[1];
          $("#fi_query").text(unescape(query));
        });

        // When the user chooses an FI from the autocompleter (say, with return),
        //   also call choose_fi() with the relevant link.
        fi.autocompleter.itemSelectEvent.subscribe(function(e, args) {
          link = args[1];
          fi.choose(link);
        });

        // When the autocompleter is first queried, hide the featured FI list and show the results list instead
        fi.autocompleter.dataRequestEvent.subscribe(function() {
          if ($("#live_results").is(":hidden")) {
            $("#live_results").show();
            $("#featured_fis").hide();
          }
        });
      }
    });

    // Focus on the FI name input field and select the instructions so the user can type over them
    $('#fi_choice').focus().select();
  }
};

  // FIXME: move this to its own .js file
  createCashAccount = {
    init: function() {
      $("#create-cash-account-button").click(function() {
        $("#create-cash-account-form .button.cancel").click(function() {
          $("#create-cash-account-form").fadeOut();
          $("#create-cash-account-form input").val('');
        });
        $("#create-cash-account-form").fadeIn();
      })
    }
  }
})(jQuery);

// FIXME: needs to be refactored
jQuery(function() {
  // $('#fi_form a.submit').click(function(){ ssu.submitCreds() });
  $('#fi_form a.cancel').click(function(){ ssu.cancel() });
  createCashAccount.init();

  ssu.startWatchingLoginFields();
  $("#fi_form").submit(ssu.submitCreds);
  $("#sq_form").submit(ssu.submitQuestions);
})

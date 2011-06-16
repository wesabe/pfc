$(function() {
  // FIXME: when the user clicks Cancel after filling something out that would cause an error
  // simply hiding the fields doesn't work

  function toggleEmailEditing() {
    $('#email-view, #email-edit').toggle();
  }

  $('#email-view #start-email-edit, #email-edit #stop-email-edit').click(function() {
    toggleEmailEditing()
  });

  if ($('#email-edit .error').length) {
    toggleEmailEditing();
  }
});

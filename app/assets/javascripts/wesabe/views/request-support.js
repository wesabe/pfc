$(function() {
  $('#nonce-submit').click(function() {
    var button = $(this);
    $.post("/support_requests", "format=js", function(nonce) {
      button.hide();
      $('#nonce-container').show();
      $('#nonce').text(nonce);
    }, "json");
  });
});
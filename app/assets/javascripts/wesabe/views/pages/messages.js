jQuery(function($){
  if (wesabe.views) {
    wesabe.views.shared
      .setCurrentTab("inbox")
      .setPageTitle("My Inbox");
  }

  $("#messages-table tbody tr")
    .hover(
      function() {$(this).addClass("hover");},
      function() {$(this).removeClass("hover");}
    );
  $("#messages-table tbody td.clickable")
    .click(function() {
    window.location.href = "/messages/" + $(this).parents("tr").attr("id").split(/_/)[1];
  });

  $('#select-all,#select-none').click(function() {
    $('td.actions input:checkbox').attr('checked', this.id === 'select-all');
    return false;
  });
});

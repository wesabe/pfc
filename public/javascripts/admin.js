jQuery(function($) {
  $('.title-clippy').each(function() {
    $(this).clippy(this.title, '#fff');
  });

  $('.text-clippy').each(function() {
    $(this).clippy($(this).text(), '#fff');
  });

  $('.troubleshoot').click(function() {
    var container = $(this).parents('.credential').find('.troubleshoot-container');

    $(this).html('troubleshoot &'+(container.is(':visible') ? 'd' : 'u')+'arr;');
    container.slideToggle('fast');

    return false;
  });
});

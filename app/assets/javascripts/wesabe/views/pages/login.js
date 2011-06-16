jQuery(function($) {
  $('.fading-label .field').each(function() {
    var field = $(this);
    new wesabe.views.widgets.FadingLabelField(field.find('input:not([type=hidden])'), field.find('label'));
  });
});
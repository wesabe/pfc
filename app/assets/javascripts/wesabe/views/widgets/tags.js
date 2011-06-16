jQuery(function($) {
  var widget = wesabe.provide('views.widgets.tags.__instance__', new wesabe.views.widgets.tags.TagWidget($('#tags'), wesabe.data.tags.sharedDataSource));
  widget.loadData();
});

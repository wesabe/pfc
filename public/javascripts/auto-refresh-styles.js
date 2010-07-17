// Reloads stylesheets with the class "reload" every couple of seconds
// For example:
//   <link class="reload" href="/css/foo" rel="stylesheet" type="test/css" media="screen">

function reloadStylesheets() {
  jQuery("link.reload").each(function(){
    var h = this.href.replace(/(&|\?)forceReload=\d+/,'');
    var c = (h.indexOf("?") >= 0) ? "&" : "?";
    var p = (c + "forceReload=" + new Date().valueOf());
    this.href = h + p;
  });
  setTimeout('reloadStylesheets()', 2000);
}

setTimeout('reloadStylesheets()', 2000);
wesabe.provide('lang.uri', {
  escape: function(string) {
    return string
      .replace(/([^ a-zA-Z0-9_.-]+)/g, function(s) {
        return encodeURIComponent(s);
      })
      .replace(/ /g, '+');
  }
});

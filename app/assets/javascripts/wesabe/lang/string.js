wesabe.provide('lang.string', {
  pluralize: function(count, singular, plural) {
    return (count == 1) ? singular :
                 plural ? plural :
                          singular + 's';
  },

  commonPrefix: function() {
    if (arguments.length == 0)
      return "";

    var shortestString = arguments[0];
    for (var i = 1; i < arguments.length; i++)
      if (arguments[i].length < shortestString.length)
        shortestString = arguments[i];

    for (var i = 0; i < shortestString.length; i++)
      for (var j = 0; j < arguments.length; j++)
        if (arguments[j].substring(0, i) !== arguments[0].substring(0, i))
          return arguments[0].substring(0, i-1);

    return shortestString;
  },

  escapeHTML: function(text) {
    return $('<div></div>').text(text).html();
  },

  // collapse a string to max_length, adding ellipses
  collapse: function(text, max_length, chars_at_end, connector) {
    chars_at_end = chars_at_end == undefined ? 10 : chars_at_end;
    connector = connector || "...";
    if (text.length > max_length) {
      var newText = text.slice(0, max_length - chars_at_end - connector.length) + connector;
      if (chars_at_end > 0) {
         newText += text.slice(-chars_at_end, text.length);
      }
      return newText;
    } else {
      return text;
    }
  },

  // linkify some text. Stolen from ActionView::Helpers::TextHelper
  auto_link: function(text, max_link_length, chars_at_end, connector) {
    var pattern = /(<\w+.*?>|[^=!:'"\/]|^)((?:https?:\/\/)|(?:www\.))([-\w]+(?:\.[-\w]+)*(?::\d+)?(?:\/(?:[~\w\+@%=\(\)-]|(?:[,.;:'][^\s$]))*)*(?:\?[\w\+@%&=.;:-]+)?(?:\#[\w\-]*)?)([[:punct:]]|<|$|)/g;
    return text.replace(pattern, function(match, a, b, c, d) {
      // don't link things that are already linked
      if (a.match(/<a /i)) {
        return match;
      } else {
        var linkText = wesabe.lang.string.collapse(b + c, max_link_length, chars_at_end, connector);
        return a + '<a href="'
                + (b == "www." ? "http://www." : b)
                + c + '">'
                + linkText + '</a>'
                + d;
      }
    });
  },

  /*
   * Title Caps
   *
   * Ported to JavaScript By John Resig - http://ejohn.org/ - 21 May 2008
   * Original by John Gruber - http://daringfireball.net/ - 10 May 2008
   * License: http://www.opensource.org/licenses/mit-license.php
   */
  titleCaps: (function() {
    var small = "(a|an|and|as|at|but|by|en|for|if|in|of|on|or|the|to|v[.]?|via|vs[.]?)";
    var punct = "([!\"#$%&'()*+,./:;<=>?@[\\\\\\]^_`{|}~-]*)";

    function titleCaps(title){
      var parts = [], split = /[:.;?!] |(?: |^)["Ò]/g, index = 0;

      while (true) {
        var m = split.exec(title);

        parts.push( title.substring(index, m ? m.index : title.length)
          .replace(/\b([A-Za-z][a-z.'Õ]*)\b/g, function(all){
            return /[A-Za-z]\.[A-Za-z]/.test(all) ? all : upper(all);
          })
          .replace(RegExp("\\b" + small + "\\b", "ig"), lower)
          .replace(RegExp("^" + punct + small + "\\b", "ig"), function(all, punct, word){
            return punct + upper(word);
          })
          .replace(RegExp("\\b" + small + punct + "$", "ig"), upper));

        index = split.lastIndex;

        if ( m ) parts.push( m[0] );
        else break;
      }

      return parts.join("").replace(/ V(s?)\. /ig, " v$1. ")
        .replace(/(['Õ])S\b/ig, "$1s")
        .replace(/\b(AT&T|Q&A)\b/ig, function(all){
          return all.toUpperCase();
        });
    };

    function lower(word){
      return word.toLowerCase();
    }

    function upper(word){
      return word.substr(0,1).toUpperCase() + word.substr(1);
    }

    return titleCaps;
  })(),

  blank: function(string) {
    return !string || (string.match(/^\s*$/) != null);
  },

  ucfirst: function(word){
    return word.substr(0,1).toUpperCase() + word.substr(1);
  },

  uriEscape: function(string) {
    return string.replace(/[^a-z0-9]/ig, function(c) {
      return '%'+c.charCodeAt(0).toString(16).toUpperCase();
    });
  }
});

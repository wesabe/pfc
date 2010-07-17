(function() {
  // package wesabe.data

  // import jQuery as $
  var $ = jQuery;
  // import wesabe.lang.number
  var number = wesabe.lang.number;
  // import wesabe.lang.string
  var string = wesabe.lang.string;

  /**
   * Provides access to commonly-used tag functionality.
   *
   * module tags
   */
  $.extend(wesabe.provide('data.tags'), {
    parseTagString: function(tagString) {
      if (!tagString || string.blank(tagString))
        return [];

      var me = this,
          tags = [],
          match;

      // extract tags from tagString
      tagString.replace(/('([^']*)'|"([^"]*)"|[^:\s]+)(:\S+)?/g, function(tag) {
        if (string.blank(me.unquote(tag)))
          return;

        tags.push(
          (match = tag.match(/^(.+):(.+)$/)) ?
            {name: me.unquote(match[1]), amount: match[2]} :
            {name: me.unquote(tag)});
      });

      return tags;
    },

    joinTags: function(tags) {
      var strings = [],
          length = tags.length;

      while (length--) {
        var tag = tags[length];

        // fix quoting
        var string = this.quote(this.unquote(tag.name));

        // append splits
        if ('amount' in tag) {
          var amount = tag.amount;
          if (amount.value) amount = amount.value;
          string += ':'+Math.abs(number.parse(amount));
        }

        strings[length] = string;
      }

      return strings.join(' ');
    },

    unquote: function(tag) {
      if (/'([^']*)'|"([^"]*)"/.test(tag))
        return tag.substring(1, tag.length - 1);
      else
        return tag;
    },

    quote: function(tag) {
      if (/['\s]/.test(tag)) {
        return "\"" + tag + "\"";
      } else if (/"/.test(tag)) {
        return "'" + tag + "'";
      } else {
        return tag;
      }
    },

    listsEqual: function(list1, list2) {
      if (list1.length != list2.length) return false;

      var length = list1.length;

      for (var i = length; i--; ) {
        var found = false;

        for (var j = length; j--; ) {
          if ((list1[i].name === list2[j].name) && (list1[i].split === list2[j].split)) {
            found = true;
            break;
          }
        }

        if (!found) return false;
      }

      return true;
    }
  });
})();

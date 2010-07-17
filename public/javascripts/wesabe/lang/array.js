wesabe.provide('lang.array', {
  intersection: (function() {
    function intersection() {
      var args = $.makeArray(arguments);

      switch (args.length) {
        case 0:  return [];
        case 1:  return args[0];
        case 2:  return simpleIntersection(args[0], args[1]);
        default: return this.intersection(args[0], this.intersection.apply(this, args.slice(1)));
      }
    }

    function simpleIntersection(a1, a2) {
      var result = [];

      for (var i = 0; i < a1.length; i++)
        if (wesabe.lang.array.contains(a2, a1[i]))
          result.push(a1[i]);
      for (var i = 0; i < a2.length; i++)
        if (wesabe.lang.array.contains(a1, a2[i]) && !wesabe.lang.array.contains(result, a2[i]))
          result.push(a2[i]);

      return result;
    }

    return intersection;
  })(),

  contains: function(array, item, matcher) {
    if (!matcher) matcher = function(a,b){ return a===b };
    for (var i = 0; i < array.length; i++)
      if (matcher(array[i], item))
        return true;
    return false;
  },

  minus: function(a1, a2) {
    var result = [];
    for (var i = 0; i < a1.length; i++)
      if (!this.contains(a2, a1[i]))
        result.push(a1[i]);
    return result;
  },

  merge: function(ai, aj) {
    var intersection = this.intersection(ai, aj);
    var result = [];

    for (var i = 0, j = 0; i < ai.length || j < aj.length; ) {
      if (ai[i] == aj[j]) {
        result.push(ai[i]);
        i++; j++;
      } else {
        if (this.contains(intersection, ai[i])) {
          result.push(ai[i]);
          i++;
        } else if (this.contains(intersection, aj[j])) {
          result.push(aj[j]);
          j++;
        } else {
          if (i < ai.length) result.push(ai[i++]);
          if (j < aj.length) result.push(aj[j++]);
        }
      }
    }

    return result;
  },

  caseInsensitiveSort: function(array, transform) {
    transform = transform || function(o){ return o };
    return array.sort(function(a, b) {
      a = transform(a).toLowerCase();
      b = transform(b).toLowerCase();
      // fix odd error in IE 6/7 where one of the values is unknown (IE says "Variable uses an Automation type not supported in JScript")
      if (typeof(a) == "unknown" || typeof(b) == "unknown") {
        return 0;
      } else {
        return (a == b) ? 0 : (a < b) ? -1 : 1;
      }
    });
  },

  uniq: function(array) {
    var entries = [];

    return $.grep(array, function(entry) {
      var duplicate = wesabe.lang.array.contains(entries, entry);
      if (!duplicate) entries.push(entry);
      return !duplicate;
    });
  }
});

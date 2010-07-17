wesabe.provide('lang.number');

wesabe.lang.number = {
  ordinalize: function(n) {
    // teens
    if (10 < n && n < 20) return n+'th';
    // everything else
    switch (n % 10) {
      case 1:  return n+'st';
      case 2:  return n+'nd';
      case 3:  return n+'rd';
      default: return n+'th';
    }
  },

  parse: function(expr) {
    if (/^\d+$/.test(expr))
      return parseInt(expr);
    else if (/^\d*\.\d+$/.test(expr))
      return parseFloat(expr);
    else if (/^((?:\d*\.)?\d+)%$/.test(expr))
      return wesabe.lang.number.parse(RegExp.$1) / 100.0;
    else if (/^[\d\.\-\+\(\)\/\*]+$/.test(expr)) {
      try {
        // WARNING: Be aware that this uses eval.
        // While ideally we never want to use eval on the client given anything
        // from the server that might be dangerous (tag names, in this case),
        // this is fairly well protected by the regular expression above.
        //
        // The ^ and $ anchors ensure that the entire string may only contain
        // digits, periods, minus, plus, parentheses, forward slash (division),
        // and asterisks (multiplication). I don't think it is possible to
        // construct malicious javascript using these characters, but if it is
        // then this should be replaced by a proper parser or removed.
        //
        // DO NOT CHANGE THIS FUNCTION WITHOUT KNOWING WHAT YOU'RE DOING!
        var result = eval(expr);
        if (typeof result == "number") return result;
      } catch(e) { }
      return NaN;
    }
  }
};

(function() {
  var string = wesabe.lang.string;

  describe("wesabe.lang.string.pluralize", {
    "uses the plural string for 0": function() {
      expect(string.pluralize(0, 'book', 'books'))
        .to(equal, 'books');
    },

    "uses the singular string for 1": function() {
      expect(string.pluralize(1, 'book', 'books'))
        .to(equal, 'book');
    },

    "uses the plural string for multiple": function() {
      expect(string.pluralize(20, 'book', 'books'))
        .to(equal, 'books');
    },

    "guesses the plural string by adding an 's' if none is given": function() {
      expect(string.pluralize(2, 'book'))
        .to(equal, 'books');
    }
  });

  describe("wesabe.lang.string.commonPrefix", {
    "with no strings returns the empty string": function() {
      expect(string.commonPrefix())
        .to(equal, "");
    },

    "with a single string returns the string": function() {
      expect(string.commonPrefix("apples"))
        .to(equal, "apples");
    },

    "with multiple strings that have no common prefix returns the empty string": function() {
      expect(string.commonPrefix("apples", "oranges"))
        .to(equal, "");
    },

    "with multiple equal strings returns the string": function() {
      expect(string.commonPrefix("apple", "apple", "apple"))
        .to(equal, "apple");
    },

    "with multiple unequal strings that have a common prefix equal to one of the strings returns the shortest string": function() {
      expect(string.commonPrefix("apple", "apples"))
        .to(equal, "apple");
      expect(string.commonPrefix("apples", "apple"))
        .to(equal, "apple");
      expect(string.commonPrefix("applesauce", "apples", "apple"))
        .to(equal, "apple");
    },

    "with multiple unequal strings that have a common prefix shorter than all strings returns the common prefix": function() {
      expect(string.commonPrefix("snack", "snake", "sneak"))
        .to(equal, "sn");
    }
  });

  describe("wesabe.lang.string.escapeHTML", {
    "leaves text without html characters alone": function() {
      var text = "my innocuous string";
      expect(string.escapeHTML(text)).to(equal, text);
    },

    "escapes html characters": function() {
      expect(string.escapeHTML('Click <a href="javascript:malicious()">here!</a>')).
        to(equal, 'Click &lt;a href="javascript:malicious()"&gt;here!&lt;/a&gt;');
    }
  });

  describe("wesabe.lang.string.blank", {
    "returns true for an empty string": function() {
      expect(string.blank('')).to(equal, true);
    },

    "returns false for a string with non-whitespace characters": function() {
      expect(string.blank('a b c')).to(equal, false);
    }
  });

  describe("wesabe.lang.string.ucfirst", {
    "returns a string with the first character upper-cased": function() {
      expect(string.ucfirst("hello there")).to(equal, "Hello there");
    },

    "returns a blank string if the input is a blank string": function() {
      expect(string.ucfirst("")).to(equal, "");
    }
  });

  describe("wesabe.lang.string.uriEscape", {
    "leaves an alnum string alone": function() {
      expect(string.uriEscape("hellojohnny5")).to(equal, "hellojohnny5");
    },

    "escapes all non-alnum characters": function() {
      expect(string.uriEscape("Hello Johnny 5, how are you? It's good to see you."))
        .to(equal, "Hello%20Johnny%205%2C%20how%20are%20you%3F%20It%27s%20good%20to%20see%20you%2E");
    }
  });
})();

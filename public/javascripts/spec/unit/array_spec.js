(function() {
  var array = wesabe.lang.array;

  describe("wesabe.lang.array.intersection", {
    "returns an empty array given nothing": function() {
      expect(array.intersection()).to(equal, []);
    },

    "returns the given array if it is the only argument": function() {
      expect(array.intersection([1, 2])).to(equal, [1, 2]);
    },

    "returns the common elements of the given arrays": function() {
      expect(array.intersection([1, 2, 5], [1, 3, 5])).to(equal, [1, 5]);
    },

    "supports more than two arguments": function() {
      expect(array.intersection([1, 2, 5], [1, 3, 5], [1, 2, 3])).to(equal, [1]);
    }
  });

  describe("wesabe.lang.array.contains", {
    "returns true when given an element contained in the given array": function() {
      expect(array.contains([1, 2, 3], 1)).to(equal, true);
    },

    "returns false when given an element not contained in the given array": function() {
      expect(array.contains([0, false, "yogi"], "")).to(equal, false);
    }
  });

  describe("wesabe.lang.array.minus", {
    "returns all the elements in the first array that are not in the second": function() {
      expect(array.minus([1, 2, 3, 4, 5, 6, 7], [2, 4, 6, 8])).to(equal, [1, 3, 5, 7]);
    }
  });

  describe("wesabe.lang.array.merge", {
    "returns an empty array given two empty arrays": function() {
      expect(array.merge([], [])).to(equal, []);
    },

    "returns an array equal to the non-empty array given one empty and one non-empty": function() {
      expect(array.merge([1, 2], [])).to(equal, [1, 2]);
    },

    "returns the same array given two equal arrays": function() {
      expect(array.merge([1, 2], [1, 2])).to(equal, [1, 2]);
    },

    "returns the longer of two arrays if one is a subset of the other": function() {
      expect(array.merge([1, 2], [1, 2, 3])).to(equal, [1, 2, 3]);
    },

    "weaves the two arrays together, starting with the first, if they do not intersect": function() {
      expect(array.merge([1, 2], [3, 4])).to(equal, [1, 3, 2, 4]);
    },

    "weaves and combines as necessary": function() {
      expect(array.merge([1, 2, 4, 5, 7], [1, 2, 3, 5])).to(equal, [1, 2, 4, 3, 5, 7]);
    }
  });

  describe("wesabe.lang.array.caseInsensitiveSort", {
    before: function() {
      names = ['Computers', 'apple', 'javascript'];
      sortedNames = ['apple', 'Computers', 'javascript'];

      tags = $.map(names, function(name){ return {name: name} });
      sortedTags = $.map(sortedNames, function(name){ return {name: name} });
    },

    "returns an empty array given an empty array": function() {
      expect(array.caseInsensitiveSort([])).to(equal, []);
    },

    "returns an array sorted without regard to case": function() {
      expect(array.caseInsensitiveSort(names))
        .to(equal, sortedNames);
    },

    "accepts an optional transformation function": function() {
      expect(array.caseInsensitiveSort(tags, function(tag){ return tag.name }))
        .to(equal, sortedTags);
    }
  });

  describe("wesabe.lang.array.uniq", {
    "returns an empty array given an empty array": function() {
      expect(array.uniq([])).to(equal, []);
    },

    "returns an already unique array": function() {
      expect(array.uniq([1, 2, 3, 4, 5])).to(equal, [1, 2, 3, 4, 5]);
    },

    "filters out duplicates keeping the first": function() {
      expect(array.uniq([1, 2, 1, 4, 9, 4])).to(equal, [1, 2, 4, 9]);
    }
  });
})();

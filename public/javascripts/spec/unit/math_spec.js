(function() {
  var math = wesabe.lang.math;

  describe("wesabe.lang.math.max", {
    "returns the maximum value from an array of numbers": function() {
      expect(math.max([-1, 3.14159, 42, 0])).to(equal, 42);
    },

    "returns the maximum value from an array of negative numbers": function() {
      expect(math.max([-3, -1, -2])).to(equal, -1);
    },

    "returns the maximum value from an array with one element": function() {
      expect(math.max([42])).to(equal, 42);
    },

    "returns undefined if the array is empty": function() {
      expect(math.max([])).to(equal, undefined);
    }
  });

  describe("wesabe.lang.math.sum", {
    "returns the sum of an array of numbers": function() {
      expect(math.sum([0, 1, 2, 3])).to(equal, 6);
    },

    "returns undefined if the array is empty": function() {
      expect(math.sum([])).to(equal, undefined);
    }
  });

  describe("wesabe.lang.math.avg", {
    "returns the average of an array of numbers": function() {
      expect(math.avg([0, 1, 2, 3])).to(equal, 1.5);
    },

    "returns undefined if the array is empty": function() {
      expect(math.avg([])).to(equal, undefined);
    }
  });

  describe("wesabe.lang.math.stddev", {
    "returns the standard deviation of an array of numbers": function() {
      // FIXME: patch Screw.Unit to support a "be_close" matcher
      expect(math.stddev([0, 1, 2, 3]).toString()).to(match, /^1.11803/);
    },

    "returns undefined if the array is empty": function() {
      expect(math.stddev([])).to(equal, undefined);
    }
  });
})();

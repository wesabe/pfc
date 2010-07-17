(function() {
  var object = wesabe.lang.object;

  describe("wesabe.lang.object.equals(no arg has #isEqualTo)", {
    "returns true if the objects are ===": function() {
      expect(object.equals(1, 1)).to(be_true);
    },

    "returns false if the objects are not ===": function() {
      expect(object.equals(1, 2)).to(be_false);
      expect(object.equals(0, '')).to(be_false);
    }
  });

  describe("wesabe.lang.object.equals(both args have #isEqualTo)", {
    before: function() {
      iEqualEverything = {isEqualTo: function(){ return true }};
      iEqualNothing = {isEqualTo: function(){ return false }};
    },

    "returns true if the objects are ===": function() {
      expect(object.equals(iEqualEverything, iEqualEverything)).to(be_true);
    },

    "returns false if the objects are not === and a.isEqualTo(b) is false": function() {
      expect(object.equals(iEqualNothing, iEqualEverything)).to(be_false);
    },

    "returns true if the objects are not === but a.isEqualTo(b) is true": function() {
      expect(object.equals(iEqualEverything, iEqualNothing)).to(be_true);
    }
  });

  describe("wesabe.lang.object.equals(both args have #valueOf)", {
    before: function() {
      now = new Date();
      otherNow = new Date(now.valueOf());
    },

    "returns true if the objects are ===": function() {
      expect(object.equals(now, now)).to(be_true);
    },

    "returns true if the objects have the same internal value": function() {
      expect(object.equals(now, otherNow)).to(be_true);
    },

    "returns false if the objects are just different Objects whose valueOf calls return themselves": function() {
      expect(object.equals({a: 1}, {b: 1})).to(be_false);
    }
  })
})();

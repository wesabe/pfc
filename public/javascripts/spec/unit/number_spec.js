(function() {
  describe("wesabe.lang.number.ordinalize", {
    "accepts zero": function() {
      expect(wesabe.lang.number.ordinalize(0)).to(equal, '0th');
    },

    "makes an exception for teens": function() {
      expect(wesabe.lang.number.ordinalize(11)).to(equal, '11th');
      expect(wesabe.lang.number.ordinalize(12)).to(equal, '12th');
      expect(wesabe.lang.number.ordinalize(13)).to(equal, '13th');
      expect(wesabe.lang.number.ordinalize(14)).to(equal, '14th');
    },

    "appends 'st' to numbers ending in 1": function() {
      expect(wesabe.lang.number.ordinalize(51)).to(equal, '51st');
    },

    "appends 'nd' to numbers ending in 2": function() {
      expect(wesabe.lang.number.ordinalize(52)).to(equal, '52nd');
    },

    "appends 'rd' to numbers ending in 3": function() {
      expect(wesabe.lang.number.ordinalize(53)).to(equal, '53rd');
    },

    "appends 'th' to everything else": function() {
      expect(wesabe.lang.number.ordinalize(55)).to(equal, '55th');
    }
  });

  describe("wesabe.lang.number.parse", {
    "can parse integers": function() {
      expect(wesabe.lang.number.parse('2')).to(equal, 2);
    },

    "can parse floats": function() {
      expect(wesabe.lang.number.parse('2.3')).to(equal, 2.3);
    },

    "can parse percentages": function() {
      expect(wesabe.lang.number.parse('23%')).to(equal, 0.23);
    },

    "can parse expressions": function() {
      expect(wesabe.lang.number.parse('3+4')).to(equal, 7);
      expect(wesabe.lang.number.parse('(3+4)/(1-.5)')).to(equal, 14);
    },

    "returns NaN when it can't understand the expression": function() {
      expect(wesabe.lang.number.parse('a')).to(beNaN);
    },

    // This is here because wesabe.lang.number.parse currently uses
    // eval. See the source of that method for more information.
    "does not allow eval'ing malicious code": function() {
      expect(wesabe.lang.number.parse('fail()\n4')).to(beNaN);
    }
  });
})();

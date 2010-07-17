(function() {
  var money = wesabe.lang.money;
  money.CURRENCIES = {
    USD: {unit: '$', name: 'USD', delimiter: ',', separator: '.', precision: 2},
    EUR: {unit: '€', name: 'EUR', delimiter: ',', separator: '.', precision: 2},
    GBP: {unit: '£', name: 'GBP', delimiter: ',', separator: '.', precision: 2}
  };
  var prefs = wesabe.data.preferences;

  describe("wesabe.lang.money.format(when the user's default currency is set)", {
    before: function() {
      prefs.set('default_currency', money.CURRENCIES.GBP);
    },

    "uses the default currency to format the number": function() {
      expect(money.format(0)).to(equal, '£0.00');
    },

    after: function() {
      prefs.set('default_currency', null);
    }
  });

  describe("wesabe.lang.money.format(using defaults)", {
    before: function() {
      oneThousandUSD = money.format({USD: 1000, currency: 'USD'});
      dinnerInEUR = money.format({EUR: 23.86, currency: 'EUR'});
      debtInGBP = money.format({GBP: -492.85, currency: 'GBP'});
    },

    "uses commas for the delimiter": function() {
      expect(oneThousandUSD).to(match, /^\$1,000/);
    },

    "uses a period for the separator": function() {
      expect(oneThousandUSD).to(match, /\.00$/);
    },

    "starts with the currency symbol": function() {
      expect(dinnerInEUR).to(match, /^€/);
    },

    "defaults to minus sign prefix and no suffix with negative amounts": function() {
      expect(debtInGBP).to(match, /^-£/);
    },

    "formats the money according to currency defaults": function() {
      expect(oneThousandUSD).to(equal, "$1,000.00");
      expect(dinnerInEUR).to(equal, "€23.86");
      expect(debtInGBP).to(equal, "-£492.85");
    }
  });

  describe("wesabe.lang.money.format(with options)", {
    before: function() {
      oneThousandUSD = {USD: 1000, currency: 'USD'}
      oneThousandUSDWithoutDelimiter =
        money.format(oneThousandUSD, {delimiter: ''});
      oneThousandUSDWithCustomSeparator =
        money.format(oneThousandUSD, {separator: '_'});
      oneThousandUSDWithoutCents =
        money.format(oneThousandUSD, {precision: 0});
      highPrecisionUSD =
        money.format({USD: 19.478, currency: 'USD'}, {precision: 3});
    },

    "uses the delimiter provided in the options": function() {
      expect(oneThousandUSDWithoutDelimiter).to(equal, "$1000.00");
    },

    "uses the separator provided in the options": function() {
      expect(oneThousandUSDWithCustomSeparator).to(equal, "$1,000_00");
    },

    "uses the precision provided in the options": function() {
      expect(highPrecisionUSD).to(equal, "$19.478")
      expect(oneThousandUSDWithoutCents).to(equal, "$1,000");
    },

    "rounds the amount appropriately when the precision is less than that of the original amount": function() {
      expect(money.format({USD: 19.59, currency: 'USD'}, {precision: 0})).to(equal, "$20");
      expect(money.format({USD: 19.59, currency: 'USD'}, {precision: 1})).to(equal, "$19.6");
    },

    "uses the currency unit provided in the options": function() {
      expect(money.format(20, {currency: 'USD', unit: ''})).to(equal, '20.00');
    },

    "given a negative amount, allows overriding the negative prefix and suffix": function() {
      negativeOne = {USD: -1, currency: "USD"};
      expect(money.format(negativeOne, {negativePrefix: '(', negativeSuffix: ')'}))
        .to(equal, "($1.00)");
    },

    "given a positive amount, allows overriding the positive prefix and suffix": function() {
      positiveOne = {USD: 1, currency: "USD"};
      expect(money.format(positiveOne, {positivePrefix: '+', positiveSuffix: '!'}))
        .to(equal, "+$1.00!");
    }
  });

  describe("wesabe.lang.money.format(where money is a number)", {
    before: function() {
      twenty = money.format(20);
      twentyEUR = money.format(20, {currency: 'EUR'});
    },

    "defaults to USD": function() {
      expect(twenty).to(equal, "$20.00");
    },

    "allows specifying the currency in the options": function() {
      expect(twentyEUR).to(equal, "€20.00");
    },

    "does not format as NaN given zero in a non-USD currency": function() {
      expect(money.format(0, {currency: 'EUR'})).to(equal, "€0.00");
    }
  });

  describe("wesabe.lang.money.formatWithMarkup", {
    "surrounds the result of #format in a span.credit given a positive amount": function() {
      expect(money.formatWithMarkup(20))
        .to(equal, '<span class="credit">$20.00</span>');
    },

    "is the same as calling #format given a negative amount": function() {
      expect(money.formatWithMarkup(-20))
        .to(equal, "-$20.00");
    }
  });

  describe("wesabe.lang.money.amount", {
    "returns the USD portion of the money object when asking for USD": function() {
      expect(money.amount({USD: 20, currency: 'USD'}, 'USD'))
        .to(equal, 20);
    }
  });

  describe("wesabe.lang.money.currency", {
    "returns its name given currency name not in cache": function() {
      var actual = money.currency('TEST');
      expect(actual.name).to(equal, 'TEST');
    }
  });

  describe("wesabe.lang.money.abs", {
    before: function() {
      spending    = {"USD": -2.3, "GBP": -1.2, "AUD": -2.1, "currency": "USD"};
      absSpending = {"USD":  2.3, "GBP":  1.2, "AUD":  2.1, "currency": "USD"};
    },

    "abs should not have side-effects": function() {
      var before_abs = spending['USD'];
      money.abs(spending);
      var after_abs  = spending['USD'];

      expect(before_abs).to(equal, after_abs);
    },

    "returns a money object with all positive amounts": function() {
      expect(money.abs(spending)).to(equal, absSpending);
    }
  });
})();

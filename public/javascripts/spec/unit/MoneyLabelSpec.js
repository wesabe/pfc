(function() {
  describe("wesabe.views.widgets.MoneyLabel", {
    before: function() {
      element = $('<span></span>');
      label  = new wesabe.views.widgets.MoneyLabel(element);
      plus4  = {display:'$4.00', value: 4}
      minus4 = {display:'-$4.00', value: -4};
    },

    "has no currency by default": function() {
      expect(label.getCurrency()).to(be_null);
    },

    "allows overriding the currency": function() {
      label.setCurrency('USD');
      expect(label.getCurrency()).to(equal, 'USD');
    },

    "optionally adds credit/debit classes to the element": function() {
      // enable the feature
      label.setAmountClassesEnabled(true);

      // check the getter
      expect(label.areAmountClassesEnabled()).to(be_true);

      // check credit
      label.setMoney(plus4);
      expect(element).to(match_selector, '.credit');

      // check debit
      label.setMoney(minus4);
      expect(element).to(match_selector, '.debit');
    },

    "defaults to a null value for doesShowSignum": function() {
      expect(label.doesShowSignum()).to(be_null);
    },

    "optionally forces showing the signum (sign)": function() {
      label.setShowSignum(true);
      expect(label.doesShowSignum()).to(be_true);

      // check positive values
      label.setMoney(plus4);
      expect(element.text()).to(equal, '+$4.00');

      // check negative values
      label.setMoney(minus4);
      expect(element.text()).to(equal, '-$4.00');
    },

    "optionally forces suppressing the signum (sign)": function() {
      label.setShowSignum(false);
      expect(label.doesShowSignum()).to(be_false);

      // check positive values
      label.setMoney(plus4);
      expect(element.text()).to(equal, '$4.00');

      // check positive values
      label.setMoney(minus4);
      expect(element.text()).to(equal, '$4.00');
    }
  });
})();

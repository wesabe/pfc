(function() {
  var params = wesabe.lang.params;

  describe("using a single-value params", {
    before: function() {
      p = {foo: 'bar'};
    },

    "wesabe.lang.params.add sets the value": function() {
      expect(params.add(p, 'foo', 'baz'))
        .to(equal, {foo: 'baz'});
    },

    "wesabe.lang.params.set sets the value": function() {
      expect(params.set(p, 'foo', 'baz'))
        .to(equal, {foo: 'baz'});
    },

    "wesabe.lang.params.remove removes the value": function() {
      expect(params.remove(p, 'foo'))
        .to(equal, {});
    },

    "wesabe.lang.params.get returns the value for a key": function() {
      expect(params.get(p, 'foo'))
        .to(equal, 'bar');
    }
  });


  describe("using a multi-value params", {
    before: function() {
      p = [
        {name: 'foo', value: 'bar'},
        {name: 'test', value: 'value'},
        {name: 'foo', value: 'huh?'}
      ];
    },

    "wesabe.lang.params.add just adds another value": function() {
      expect(params.add(p, 'test', 'TEST'))
        .to(equal, [{name: 'foo', value: 'bar'}, {name: 'test', value: 'value'}, {name: 'foo', value: 'huh?'}, {name: 'test', value: 'TEST'}]);
    },

    "wesabe.lang.params.set removes all the existing values and sets the new one": function() {
      expect(params.set(p, 'foo', 'baz'))
        .to(equal, [{name: 'test', value: 'value'}, {name: 'foo', value: 'baz'}]);
    },

    "wesabe.lang.params.remove clears all values by the given name": function() {
      expect(params.remove(p, 'foo'))
        .to(equal, [{name: 'test', value: 'value'}]);
    },

    "wesabe.lang.params.get returns the first value for a key": function() {
      expect(params.get(p, 'foo'))
        .to(equal, 'bar');
    }
  });
})();

var Screw = (function($) {
  var screw = {
    Unit: function(fn) {
      var contents = fn.toString().match(/^[^\{]*{((.*\n*)*)}/m)[1];
      var fn = new Function("matchers", "specifications",
        "with (specifications) { with (matchers) { " + contents + " } }"
      );
    },

    Specifications: {
      describes: [],
      context: [],

      describe: function(name, fn) {
        var describe = {
          name: name,
          its: [],
          befores: [],
          afters: [],
          parent: this.context[this.context.length-1]
        };

        this.describes.push(describe);

        this.context.push(describe);
        fn.call();
        this.context.pop();

        if (this.context.length == 0) {
          while (this.describes.length) {
            describe = this.describes.unshift();

            var testCaseClass = function(){};
            testCaseClass.prototype.describe = describe;

            testCaseClass.prototype.setUp = function() {
              if (this.describe.parent) this.describe.parent.setUp();
              for (var i = 0; i < this.describe.befores.length; i++)
                this.describe.befores[i].call(this);
            };

            testCaseClass.prototype.tearDown = function() {
              if (this.describe.parent) this.describe.parent.tearDown();
              for (var i = 0; i < this.describe.afters.length; i++)
                this.describe.afters[i].call(this);
            };

            jstestdriver.testCaseManager.testCases_[describe.name] = testCaseClass;
          }
        }
      },

      it: function(name, fn) {
        this.context[this.context.length-1]
          .its.push({name: name, body: fn});
      },

      before: function(fn) {
        this.context[this.context.length-1]
          .befores.push(fn);
      },

      after: function(fn) {
        this.context[this.context.length-1]
          .afters.push(fn);
      }
    }
  };

  return screw;
})(jQuery);

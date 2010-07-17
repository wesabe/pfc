(function() {
  var tags = wesabe.data.tags;
  var ds = tags.sharedDataSource;

  describe("wesabe.data.tags.TagDataSource(without tag data)", {
    before: function() {
      ds.setData(null);
    },

    "has no data": function() {
      expect(ds.hasData()).to(be_false);
    },

    "getData returns null": function() {
      expect(ds.getData()).to(be_null);
    },

    "returns an empty list of tag names": function() {
      expect(ds.getTagNames()).to(be_empty);
    }
  });

  describe("wesabe.data.tags.TagDataSource(with tag data)", {
    before: function() {
      data = {summaries: [{tag: {name: 'food'}}, {tag: {name: 'dining'}}]};
      ds.setData(data);
    },

    "has data": function() {
      expect(ds.hasData()).to(be_true);
    },

    "getData returns the tag data": function() {
      expect(ds.getData()).to(equal, data);
    },

    "returns an array of tag names": function() {
      expect(ds.getTagNames()).to(equal, ['food', 'dining']);
    }
  });

  describe("wesabe.data.tags.parseTagString", {
    "returns an empty array given an empty string": function() {
      expect(tags.parseTagString('')).to(equal, []);
    },

    "returns an array of tag entries given a list of unquoted tags": function() {
      expect(tags.parseTagString('food dining'))
        .to(equal, [{name: 'food'}, {name: 'dining'}]);
    },

    "returns an array of tag entries given a list of unquoted tags with splits": function() {
      expect(tags.parseTagString('food:10 groceries:10 transfer:20'))
        .to(equal, [{name: 'food', amount: '10'}, {name: 'groceries', amount: '10'}, {name: 'transfer', amount: '20'}]);
    },

    "returns an array of tag entries given a list of quoted tags": function() {
      expect(tags.parseTagString('"utilities & internet" \'dog food\''))
        .to(equal, [{name: 'utilities & internet'}, {name: 'dog food'}]);
    },

    "ignores those with no content": function() {
      expect(tags.parseTagString('"foo bar" ""'))
        .to(equal, [{name: 'foo bar'}]);
    },

    "returns an array of tag entries given a list of quoted tags with splits": function() {
      expect(tags.parseTagString('"utilities & internet":20 \'dog food\':39.81'))
        .to(equal, [{name: 'utilities & internet', amount: '20'}, {name: 'dog food', amount: '39.81'}]);
    },

    "handles mixed quoted, unquoted, and split tags": function() {
      expect(tags.parseTagString('  "utilities & internet" food:40 \'dog food\':2+9  freedom a b:0 c   '))
        .to(equal, [{name: 'utilities & internet'}, {name: 'food', amount: '40'},
                    {name: 'dog food', amount: '2+9'}, {name: 'freedom'},
                    {name: 'a'}, {name: 'b', amount: '0'}, {name: 'c'}]);
    }
  });

  describe("wesabe.data.tags.joinTags", {
    "returns an empty string given an empty array": function() {
      expect(tags.joinTags([])).to(equal, '');
    },

    "returns the names joined by spaces given a list of tags without spaces": function() {
      expect(tags.joinTags([{name: 'food'}, {name: 'dining'}]))
        .to(equal, 'food dining');
    },

    "returns the names quoted and joined by spaces given a list of tags with spaces": function() {
      expect(tags.joinTags([{name: 'utilities & internet'}, {name: 'dog food'}]))
        .to(equal, '"utilities & internet" "dog food"');
    },

    "returns the names joined by spaces with splits appended after colons given a list of tags with splits but without spaces": function() {
      expect(tags.joinTags([{name: 'food', amount: '10'}, {name: 'groceries', amount: '10'}, {name: 'transfer', amount: '20'}]))
        .to(equal, 'food:10 groceries:10 transfer:20');
    },

    "returns the names quoted with splits appended after colons joined by spaces given a list of tags with splits and spaces": function() {
      expect(tags.joinTags([{name: 'utilities & internet', amount: '20'}, {name: 'dog food', amount: '39.81'}]))
        .to(equal, '"utilities & internet":20 "dog food":39.81');
    },

    "returns a proper tag string for a list of mixed quoted, unquoted, and split tags": function() {
      expect(tags.joinTags([{name: 'utilities & internet'}, {name: 'food', amount: '40'},
                            {name: 'dog food', amount: '2+9'}, {name: 'freedom'},
                            {name: 'a'}, {name: 'b', amount: '0'}, {name: 'c'}]))
        .to(equal, '"utilities & internet" food:40 "dog food":11 freedom a b:0 c');
    },

    "does not add a set of quotes to an already-quoted tag name": function() {
      expect(tags.joinTags([{name: '"test quotes"'}]))
        .to(equal, '"test quotes"');
    },

    "quotes a tag name with a single double-quote in single quotes": function() {
      expect(tags.joinTags([{name: "test\"quote"}]))
        .to(equal, "'test\"quote'");
    },

    "quotes a tag name that contains a single quote with double quotes": function() {
      expect(tags.joinTags([{name: "test'quote"}]))
        .to(equal, "\"test'quote\"");
    }
  });

  describe("wesabe.data.tags.listsEqual", {
    before: function() {
      empty = []
      lunch = [{name: 'food'}, {name: 'dining'}, {name: 'lunch'}];
      lunchCopy = $.makeArray(lunch);
      lunchReverse = $.makeArray(lunch).reverse();
      lunchWithSplit = $.map(lunch, function(t){ return $.extend({split: 1}, t) });
    },

    "returns true given identical arrays": function() {
      expect(tags.listsEqual(empty, empty)).to(be_true);
      expect(tags.listsEqual(lunch, lunch)).to(be_true);
    },

    "returns true given non-identical duplicate arrays": function() {
      expect(tags.listsEqual(lunch, lunchCopy)).to(be_true);
    },

    "returns false given lists containing different tags": function() {
      expect(tags.listsEqual(lunch, lunch.slice(1))).to(be_false);
    },

    "returns false given identical tag names but different splits": function() {
      expect(tags.listsEqual(lunch, lunchWithSplit)).to(be_false);
    },

    "returns true given lists with the same tags in different orders": function() {
      expect(tags.listsEqual(lunch, lunchReverse)).to(be_true);
    }
  });
})();

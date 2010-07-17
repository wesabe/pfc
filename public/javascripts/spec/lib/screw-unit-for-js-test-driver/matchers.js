function expect(actual) {
  return {to: function(matcher, expected) {
    matcher(actual, expected);
  }};
}

function be(actual, expected) {
  jstestdriver.assertCount++;
  if (actual !== expected)
    failNotEqual(actual, expected);
}

function be_false(actual) {
  assertFalse(actual);
}

function be_true(actual) {
  assertTrue(actual);
}

function be_null(actual) {
  assertNull(actual);
}

function be_empty(actual) {
  jstestdriver.assertCount++;
  if (actual.length)
    fail('expected ' + to_s(actual) + ' to be empty');
  return true;
}

function beNaN(actual) {
  jstestdriver.assertCount++;
  if (!isNaN(actual))
    fail('expected ' + to_s(actual) + ' to be NaN');
  return true;
}

function equal(actual, expected) {
  function run(){ assertEquals(expected, actual) }

  if (actual == expected) {
    run();
  } else if (typeof actual != typeof expected) {
    run();
  } else if ($.isArray(actual)) {
    if (actual.length != expected.length) run();
    for (var i = 0; i < actual.length; i++)
      equal(actual[i], expected[i]);
  } else if (actual && $.isFunction(actual.isEqualTo)) {
    actual.isEqualTo(expected) || failNotEqual(actual, expected);
  } else if (expected && $.isFunction(expected.isEqualTo)) {
    expected.isEqualTo(actual) || failNotEqual(actual, expected);
  } else if (typeof actual == 'object') {
    for (var k in actual)
      equal(actual[k], expected[k]);
    for (var k in expected)
      equal(actual[k], expected[k]);
  } else {
    run();
  }
}

function match(actual, expected) {
  jstestdriver.assertCount++;
  var matches = actual.match(expected);

  if (!matches)
    failNotEqual(actual, expected);
  return true;
}

function match_selector(actual, expected) {
  jstestdriver.assertCount++;
  function failSelector(actual, expected) {
    fail('expected ' + to_s(actual) +
      ' to match CSS selector ' + to_s(expected));
  }

  if (!actual) {
    failSelector(actual, expected);
  } else if (!actual.jquery && !actual.nodeType) {
    failSelector(actual, expected);
  } else if (!$(actual).is(expected)) {
    failSelector($(actual).get(0), expected);
  } else {
    return true;
  }
}

function contain_the_same_elements_as_with_matcher(matcher) {
  function failNotSameArrays(actual, expected) {
    fail('expected ' + to_s(actual) + ' to contain the same elements as ' + to_s(expected));
  }
  function failNotArray(object) {
    fail('expected actual value ' + to_s(object) + ' to be an array');
  }

  return function(actual, expected) {
    if (!$.isArray(actual)) {
      failNotArray(actual);
    } else if (!$.isArray(expected)) {
      failNotArray(expected);
    } else if (actual.length !== expected.length) {
      failNotSameArrays(actual, expected);
    } else {
      var length = expected.length;
      while (length--)
        if (!wesabe.lang.array.contains(expected, actual[length], matcher))
          failNotSameArrays(actual, expected);
    }
  };
}

var contain_the_same_elements_as = contain_the_same_elements_as_with_matcher(null);

function throw_error(actual, expected) {
  try {
    actual();
    fail('expected callback to throw error, but none was thrown');
  } catch (e) {
    if (!expected) return true;

    if (jQuery.isFunction(expected.test))
      return expected.test(e.message) || fail('expected callback to throw error matching ' +
        to_s(expected) + ' but was ' +
        to_s(e.message));

    return (e.message == expected) || fail('expected callback to throw error ' +
      to_s(expected) + ' but was ' +
      to_s(e.message));
  }
}

function failNotEqual(actual, expected){
  fail('expected ' + to_s(expected) + ' but was ' +
      to_s(actual) + '');
}

function to_s(object) {
  try { return this.prettyPrintEntity_(object) }
  catch (e) {
    return (object === null)   ? 'null' :
      (object === undefined)   ? 'undefined' :
               object.jquery   ? jQuery_to_s(object) :
             object.nodeType   ? jQuery_to_s(jQuery(object)) :
$.isFunction(object.toString)  ? object.toString() :
                                 Object.prototype.toString.call(object);
  }
}

function jQuery_to_s(element) {
  var node = element[0],
      name = node.tagName.toLowerCase();

  if (element.attr('id'))
    return name+'#'+element.attr('id');
  else if (element.attr('class'))
    return name+'.'+element.attr('class').split(' ')[0];
  else
    return name;
}

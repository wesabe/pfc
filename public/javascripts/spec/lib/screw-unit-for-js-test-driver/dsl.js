function describe(name, its) {
  var tests = {};

  for (var test in its) {
    var it = its[test];
    if (test == 'before' || test == 'setUp') test = 'setUp';
    else if (test == 'after' || test == 'tearDown') test = 'tearDown';
    else if (test.indexOf('test') != 0) test = 'test: ' + test;
    tests[test] = it;
  }

  return TestCase(name, tests);
}

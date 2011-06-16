wesabe.provide('lang.math');

wesabe.lang.math = {
  // return the max number in an array of numbers
  max: function(array) {
    if (array.length == 0) return;
    var max = array[0];
    for (var i=1; i<array.length; i++) {
      if (array[i] > max) max = array[i];
    }
    return max;
  },

  // return the sum of an array of numbers
  sum: function(array) {
    if (array.length == 0) return;
    var sum = 0;
    for (var i=0; i<array.length; i++) {
      sum = sum + array[i];
    }
    return sum;
  },

  // return the average (mean) of an array of numbers
  avg: function(array) {
    if (array.length == 0) return;
    return wesabe.lang.math.sum(array) / array.length;
  },

  // return the standard deviation of an array of numbers
  stddev: function(array) {
    if (array.length == 0) return;
    var sum = 0;
    var avg = wesabe.lang.math.avg(array);
    for (var i=0; i<array.length; i++) {
      sum = sum + Math.pow(array[i] - avg, 2);
    }
    return Math.sqrt(sum / array.length);
  }
};

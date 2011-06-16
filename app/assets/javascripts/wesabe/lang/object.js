wesabe.provide('lang.object', {
  equals: function(o1, o2) {
    if (o1 === o2)
      return true;

    if (this.isPrimitive(o1) || this.isPrimitive(o2))
      return false;

    if (o1 && o1.isEqualTo)
      return o1.isEqualTo(o2);

    if (o2 && o2.isEqualTo)
      return o2.isEqualTo(o1);

    if (o1 && o2 && o1.valueOf && o2.valueOf)
      return o1.valueOf() == o2.valueOf();

    return false;
  },

  isPrimitive: function(object) {
    return (/^\[object (Number|Array|String|Function)\]$/.test(Object.prototype.toString.call(object)));
  }
});

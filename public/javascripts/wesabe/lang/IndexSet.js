/**
 * Represents a set of indexes.
 */
wesabe.$class('wesabe.lang.IndexSet', function($class, $super, $package) {
  // import jQuery as $
  var $ = jQuery;

  $.extend($class.prototype, {
    _ranges: null,

    init: function() {
      this._ranges = [];
    },

    /**
     * Returns +true+ if +index+ exists in this index set, +false+ otherwise.
     *
     * @param {!Number} index
     * @return Boolean
     */
    contains: function(index) {
      var range = this._ranges[this.closestRangeIndexFromBelow(index)];

      if (!range || (range.location+range.length) <= index)
        return false;

      return true;
    },

    /**
     * Adds +index+ to this index set.
     *
     * @param {!Number} index
     */
    addIndex: function(index) {
      this.addRange(index, 1);
    },

    /**
     * Adds +length+ indexes starting at +location+ to this index set.
     *
     * @param {!Number} location
     * @param {!Number} length
     */
    addRange: function(location, length) {
      var closestRangeIndex = this.closestRangeIndexFromBelow(location),
          range = this._ranges[closestRangeIndex];

      if (range && (range.location+range.length > location)) {
        // new range overlaps with another range
        range.length = Math.max(range.length+range.location, location+length) - range.location;
      } else {
        // need to create a new range for this
        this.insertRange({location: location, length: length}, closestRangeIndex+1);
      }

      this.normalize();
    },

    /**
     * Removes +index+ from this index set. If the index is not present then
     * this call is simply ignored.
     *
     * @param {!Number} index
     */
    remove: function(index) {
      var closestRangeIndex = this.closestRangeIndexFromBelow(index),
          range = this._ranges[closestRangeIndex];

      if (range && (range.location === index)) {
        // marks the beginning of the range
        range.location++;
        range.length--;
        if (range.length === 0)
          this.deleteRange(closestRangeIndex);
      } else if (range && (range.location+range.length === index + 1)) {
        // marks the end of the range
        range.length--;
        if (range.length === 0)
          this.deleteRange(closestRangeIndex);
      } else if (range && (range.location+range.length > index)) {
        // appears in the middle of the range, so we need to split it
        var tail = {location: index+1, length: range.location+range.length - index-1};
        range.length = index - range.location;
        this.insertRange(tail, closestRangeIndex+1);
      }

      this.normalize();
    },

    /**
     * @private
     */
    normalize: function() {
      var range, next;

      for (var i = 0; (range = this._ranges[i]) && (next = this._ranges[i+1]); i++) {
        if (range.location+range.length >= next.location) {
          range.length = Math.max(range.location+range.length, next.location+next.length) - range.location;
          this.deleteRange(i+1);
          i--;
        }
      }
    },

    /**
     * @private
     */
    deleteRange: function(rangeIndex) {
      delete this._ranges[rangeIndex];

      for (var i = rangeIndex, length = this._ranges.length; i < length - 1; i++)
        this._ranges[i] = this._ranges[i+1];

      this._ranges.length--;
    },

    /**
     * @private
     */
    insertRange: function(range, rangeIndex) {
      this._ranges.length++;

      for (var i = this._ranges.length - 1; i > rangeIndex; i--)
        this._ranges[i] = this._ranges[i-1];

      this._ranges[rangeIndex] = range;
    },

    /**
     * @private
     */
    closestRangeIndexFromBelow: function(index) {
      var rangeIndex = -1;

      for (var i = 0, length = this._ranges.length; i < length; i++) {
        var range = this._ranges[i];

        if (range.location > index)
          break;

        rangeIndex = i;
      }

      return rangeIndex;
    },

    equals: function(other) {
      if (!other || !other.isInstanceOf || !other.isInstanceOf(this.getClass()))
        return false;

      // both should have normalized ranges, so just compare the ranges
      if (this._ranges.length !== other._ranges.length)
        return false;

      for (var i = 0, length = this._ranges.length; i < length; i++) {
        var thisRange = this._ranges[i], otherRange = other._ranges[i];
        if (thisRange.location !== otherRange.location || thisRange.length !== otherRange.length)
          return false;
      }

      return true;
    },

    toString: function() {
      var result = '#<'+this.getClass().__name__+' ',
          parts = [];

      if (this._ranges.length == 0) {
        result += '(empty)';
      } else {
        for (var i = 0, length = this._ranges.length; i < length; i++) {
          var range = this._ranges[i];
          if (range.length == 1) parts.push(range.location);
          else parts.push(range.location+'-'+(range.location+range.length-1));
        }

        result += 'indexes={'+parts.join(', ')+'}';
      }

      result += '>';

      return result;
    }
  });
});

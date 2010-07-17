/**
 * Manages a list of selected objects and provides callbacks for when the
 * list changes. The objects can be any JavaScript or DOM objects, though
 * it's recommended to use JavaScript objects to take advantage of the
 * {onSelect} and {onDeselect} callbacks which are called on objects as
 * they are added and removed, respectively, from the list.
 *
 * To observe any change to the list bind to the 'changed' event.
 */
wesabe.$class('wesabe.util.Selection', function($class, $super, $package) {
  // import wesabe.lang.array
  var array = wesabe.lang.array;
  // import wesabe.lang.object
  var object = wesabe.lang.object;

  $.extend($class.prototype, {
    _current: null,

    init: function() {
      this._current = [];
    },

    /**
     * Gets the current list of selected objects.
     */
    get: function() {
      return this._current.concat(); // return a copy
    },

    /**
     * Gets all the instances of {klass} contained by this {Selection}.
     *
     * @param {function()} klass The class to search for instances of.
     * @return {Array.<*>}
     */
    getByClass: function(klass) {
      var result = [];
      for (var items = this._current, i = items.length; i--;) {
        var item = items[i];
        if (item && $.isFunction(item.isInstanceOf) && item.isInstanceOf(klass))
          result.push(item);
      }
      return result;
    },

    /**
     * Uses {newsel} as the new selection, removing any existing objects from
     * the selection. {newsel} may be an array or a single object.
     */
    set: function(newsel) {
      newsel = $.makeArray(newsel);

      if (!this._selectionsEqual(newsel, this._current)) {
        var oldsel = this._current;

        this._current = newsel;

        var length;

        length = oldsel.length;
        while (length--)
          oldsel[length].onDeselect && oldsel[length].onDeselect();

        length = newsel.length;
        while (length--)
          newsel[length].onSelect && newsel[length].onSelect();

        this.trigger('changed', [newsel, oldsel]);
      }
    },

    /**
     * Adds {elems}, which may be an array or single object, to the current
     * selection.
     */
    add: function(elems) {
      this.set(array.merge(this._current, [elems]));
    },

    /**
     * Removes {elems}, which may be an array or single object, from the
     * current selection.
     */
    remove: function(elems) {
      this.set(array.minus(this._current, [elems]));
    },

    /**
     * Removes objects from the current selection already present in {elems}
     * and adds objects in {elems} not already in the current selection. {elems}
     * may be an array or a single object.
     */
    toggle: function(elems) {
      elems = $.makeArray(elems);
      var oldsel = $.makeArray(this._current),
          itemsToRemove = array.intersection(oldsel, elems),
          itemsToAdd = array.minus(elems, itemsToRemove),
          newsel = array.minus(oldsel, itemsToRemove).concat(itemsToAdd);

      this.set(newsel);
    },

    /**
     * Removes all elements from the current selection.
     */
    clear: function() {
      this.set([]);
    },

    /**
     * Returns a boolean indicating whether {elem} is contained in the
     * current selection.
     */
    contains: function(elem) {
      return array.contains(this._current, elem);
    },

    /**
     * Helper function to determine whether two selection lists contain the
     * same list of objects in any order, with equality determined by
     * {wesabe.lang.object.equals}.
     *
     * @private
     */
    _selectionsEqual: function(sel1, sel2) {
      sel1 = $.makeArray(sel1);
      sel2 = $.makeArray(sel2);

      if (sel1.length !== sel2.length)
        return false;

      var len1 = sel1.length;
      while (len1--) {
        var found = false,
            s1 = sel1[len1],
            len2 = sel2.length;

        while (len2--) {
          if (object.equals(s1, sel2[len2])) {
            found = true;
            break;
          }
        }

        if (!found)
          return false;
      }

      return true;
    }
  });
});

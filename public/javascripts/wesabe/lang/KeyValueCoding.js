wesabe.provide('lang.KeyValueCoding', {
  get: function(keyPath) {
    return this.valueForKeyPath(keyPath);
  },

  valueForKey: function(keyPath) {
    return this.valueForKeyPath(keyPath);
  },

  valueForKeyPath: function(keyPath) {
    var dotIndex = keyPath.indexOf('.');

    if (dotIndex != -1) {
      var head = keyPath.substring(0, dotIndex),
          tail = keyPath.substring(dotIndex+1),
          nextObject = this.valueForKeyPath(head);

      return nextObject.valueForKeyPath(tail);
    }

    var key = keyPath,
        getterNames = [key, 'get'+key.substring(0,1).toUpperCase()+key.substring(1)],
        prefixes = ['', '_'];

    for (var i = 0; i < prefixes.length; i++) {
      for (var j = 0; j < getterNames.length; j++) {
        var property = prefixes[i]+getterNames[j];

        if (!this.hasOwnProperty(property) && (typeof this[property] == 'undefined'))
          continue;

        var value = this[property];

        if ($.isFunction(value))
          return value.call(this);

        return value;
      }
    }

    return this.valueForUndefinedKey(key);
  },

  valueForUndefinedKey: function(key) {
    throw new Error(""+this+" is not key value coding-compliant for the key "+key);
  },

  set: function(keyPath, value) {
    this.setValueForKeyPath(keyPath, value);
  },

  setValueForKey: function(keyPath, value) {
    this.setValueForKeyPath(keyPath, value);
  },

  setValueForKeyPath: function(keyPath, value) {
    var dotIndex = keyPath.indexOf('.');

    if (dotIndex != -1) {
      var head = keyPath.substring(0, dotIndex),
          tail = keyPath.substring(dotIndex+1),
          nextObject = this.valueForKeyPath(head);

      return nextObject.setValueForKeyPath(tail, value);
    }

    var key = keyPath,
        property = key,
        privateProperty = '_'+property;
        setter = 'set'+key.substring(0,1).toUpperCase()+key.substring(1),
        privateSetter = '_'+setter,
        candidate = null;

    // prefer setters to manipulating values directly
    candidate = this[setter];
    if ($.isFunction(candidate))
      return candidate.call(this, value);

    candidate = this[privateSetter];
    if ($.isFunction(candidate))
      return candidate.call(this, value);

    // if there are no setters, try to set it ourselves, but don't override getters
    candidate = this[property];
    if ((this.hasOwnProperty(property) || (typeof candidate != 'undefined')) && !$.isFunction(candidate))
      return this[property] = value;

    candidate = this[privateProperty];
    if ((this.hasOwnProperty(privateProperty) || (typeof candidate != 'undefined')) && !$.isFunction(candidate))
      return this[privateProperty] = value;

    this.setValueForUndefinedKey(key);
  },

  setValueForUndefinedKey: function(key, value) {
    throw new Error(""+this+" is not key-value coding compliant for the key "+key);
  }
});

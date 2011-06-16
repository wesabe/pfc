wesabe.provide('lang.KeyValueCoding', {
  get: function(keyPath) {
    return this.valueForKey(keyPath);
  },

  valueForKey: function(key) {
    var getterNames = [key, 'get'+key.substring(0,1).toUpperCase()+key.substring(1)],
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

  getPath: function(keyPath) {
    return this.valueForKeyPath(keyPath);
  },

  valueForKeyPath: function(keyPath) {
    var headAndTail = this._keyPathHeadAndTail(keyPath),
        head = headAndTail[0],
        tail = headAndTail[1],
        headValue = this.valueForKey(head);

    if (tail)
      return headValue.valueForKeyPath(tail);

    return headValue;
  },

  valueForUndefinedKey: function(key) {
    throw new Error(""+this+" is not key value coding-compliant for the key "+key);
  },

  set: function(keyPath, value) {
    this.setValueForKey(keyPath, value);
  },

  setValueForKey: function(key, value) {
    var property = key,
        privateProperty = '_'+property;
        setter = 'set'+key.substring(0,1).toUpperCase()+key.substring(1),
        privateSetter = '_'+setter,
        candidate = null,
        self = this;

    function wrapSet(doSet) {
      self.willChangeValueForKey(key);
      doSet();
      self.didChangeValueForKey(key);
    }

    // prefer setters to manipulating values directly
    candidate = this[setter];
    if ($.isFunction(candidate))
      return wrapSet(function(){ candidate.call(self, value); });

    candidate = this[privateSetter];
    if ($.isFunction(candidate))
      return wrapSet(function(){ candidate.call(self, value); });

    // if there are no setters, try to set it ourselves, but don't override getters
    candidate = this[property];
    if ((this.hasOwnProperty(property) || (typeof candidate != 'undefined')) && !$.isFunction(candidate))
      return wrapSet(function(){ self[property] = value; });

    candidate = this[privateProperty];
    if ((this.hasOwnProperty(privateProperty) || (typeof candidate != 'undefined')) && !$.isFunction(candidate))
      return wrapSet(function(){ self[privateProperty] = value; });

    this.setValueForUndefinedKey(key);
  },

  setPath: function(keyPath, value) {
    this.setValueForKeyPath(keyPath, value);
  },

  setValueForKeyPath: function(keyPath, value) {
    var headAndTail = this._keyPathHeadAndTail(keyPath),
        head = headAndTail[0],
        tail = headAndTail[1];

    if (tail) this.valueForKey(head).setValueForKeyPath(tail, value);
    else this.setValueForKey(head, value);
  },

  setValueForUndefinedKey: function(key, value) {
    throw new Error(""+this+" is not key value coding-compliant for the key "+key);
  },

  willChangeValueForKey: function(key) {
  },

  didChangeValueForKey: function(key) {
  },

  _keyPathHeadAndTail: function(keyPath) {
    var dotIndex = keyPath.indexOf('.');

    if (dotIndex == -1)
      return [keyPath, null];

    return [keyPath.substring(0, dotIndex), keyPath.substring(dotIndex+1)];
  }
});

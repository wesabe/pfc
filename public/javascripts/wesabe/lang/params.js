wesabe.provide('lang.params', {
  add: function(params, name, value) {
    if (jQuery.isArray(params)) {
      params.push({name: name, value: value});
    } else {
      params[name] = value;
    }
    return params;
  },

  set: function(params, name, value) {
    return this.add(this.remove(params, name), name, value);
  },

  remove: function(params, name) {
    if (jQuery.isArray(params)) {
      for (var i = 0; i < params.length; ) {
        if (params[i].name == name) params.splice(i, 1);
        else i++;
      }
    } else {
      delete params[name];
    }
    return params;
  },

  get: function(params, name) {
    if (jQuery.isArray(params)) {
      for (var i = 0; i < params.length; i++) {
        if (params[i].name == name) return params[i].value;
      }
    } else {
      return params[name];
    }
  },

  has: function(params, name) {
    if (jQuery.isArray(params)) {
      for (var i = params.length; i--;)
        if (params[i].name === name)
          return true;
      return false;
    } else {
      return params.hasOwnProperty(name);
    }
  },

  copy: function(params) {
    if (jQuery.isArray(params)) {
      return params.concat();
    } else {
      return $.extend({}, params);
    }
  }
});

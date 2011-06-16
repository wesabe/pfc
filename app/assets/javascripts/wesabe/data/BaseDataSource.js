/**
 * Provides a base class with all the basic functionality of a data source.
 */
wesabe.$class('wesabe.data.BaseDataSource', function($class) {
  // import jQuery as $
  var $ = jQuery;

  /**
   * Build an anonymous subclass of {BaseDataSource} with endpoint {uri}.
   * If {uri} is a function it will be executed each time it is used.
   */
  $class.dataSourceWithURI = function(uri) {
    return $.extend(new $class(), {
      sourceURI: uri
    });
  };

  $.extend($class.prototype, {
    /**
     * URI indicating what XHR endpoint to use.
     *
     * @type {String}
     */
    sourceURI: null,

    /**
     * The jQuery data type this data source should ask for.
     *
     * @type {String}
     */
    dataType: 'json',

    /**
     * The data retrieved from the server.
     */
    data: null,

    /**
     * true if requests to the same URL (including query params) will
     * be stored and retrieved from a cache.
     *
     * @type {boolean}
     */
    cachingEnabled: false,

    _cache: {},
    _loading: false,
    _data: null,
    _pollers: [],

    init: function() {
      // TODO: implement this in subclasses
    },

    /**
     * Requests data if there is no data already available. The passed
     * {callback} will be called in either case.
     */
    requestDataUnlessHasData: function(callback) {
      if (this.hasData()) {
        callback && callback(this.get('data'));
      } else {
        this.requestData(callback);
      }
    },

    /**
     * Requests data if there is no data already available. The passed
     * {callback} will be called in either case and subscribed to future
     * changes in data.
     */
    requestDataAndSubscribe: function(callback, context) {
      context = context || this;
      // subscribe the callback
      this.subscribe(callback, context);

      if (!this.hasData()) {
        // no data yet, ask for data and let the subscription handle callback
        this.requestData();
      } else {
        // we've already got the data, run the callback ourselves
        if (callback && callback.change)
          callback.change.call(context, this.get('data'));
        else if (callback)
          callback.call(context, this.get('data'));
      }
    },

    /**
     * Requests the data again, calling {callback} if one was given when the
     * new data is fetched. If a request is already in progress another one
     * will not be issued, but the callback will be queued with the
     * already-existing request.
     *
     * Returns the {XMLHTTPRequest} instance used to send the request.
     */
    requestData: function(callback, context) {
      context = context || this;
      if ($.isFunction(callback))
        $(this).one('change', function(_, data){ callback.call(context, data) });

      if (this.isLoading())
        return;

      var cachedData = this.getCache(this.get('requestOptions'));
      if (cachedData) this.set('data', cachedData);
      else return this._doBeginLoading();
    },

    /**
     * Returns the cached data given the jQuery ajax options.
     */
    getCache: function(options) {
      return this._cache[this._cacheKey(options)];
    },

    /**
     * Sets the cache given the jQuery ajax options.
     */
    setCache: function(options, data) {
      this._cache[this._cacheKey(options)] = data;
    },

    /**
     * Clears the entire cache for this data source, but not the currently
     * loaded data (i.e. calling {#get('data')} will still return data).
     */
    clearCache: function() {
      this._cache = {};
    },

    /**
     * Generates a cache key given the jQuery ajax options.
     *
     * @return {string}
     * @private
     */
    _cacheKey: function(options) {
      var key = options.url;

      if (options.data) {
        var data = $.param(options.data);
        key += ((key.indexOf('?') == -1) ? '?' : '&') + data;
      }

      return key;
    },

    /**
     * Returns true if this data source is requesting data from the server,
     * false otherwise.
     */
    isLoading: function() {
      return this._loading;
    },

    /**
     * Gets the default set of options to pass to {jQuery.ajax}.
     */
    requestOptions: function() {
      return {
        url: this.get('sourceURI'),
        dataType: this.get('dataType')
      };
    },

    /**
     * Begins loading the data. Override this method to make non-XHR sources.
     *
     * @private
     */
    _doBeginLoading: function() {
      var me = this,
          options = $.extend({
            success: function(data){ me.onDataLoaded(data, options) },
            error: function(){ me.onDataError(options) },
            complete: function(){ me.onAfterLoad(options) }
          }, me.get('requestOptions'));

      me.onBeforeLoad();
      return $.ajax(options);
    },

    /**
     * Called immediately before the data source begins loading new data.
     */
    onBeforeLoad: function() {
      $(this).trigger('beforeLoad');
      this._loading = true;
    },

    /**
     * Called immediately after the data source begins loading new data.
     */
    onAfterLoad: function() {
      this._loading = false;
      $(this).trigger('afterLoad');
    },

    /**
     * Handles incoming data from the server.
     *
     * @private
     */
    onDataLoaded: function(data, options) {
      this.set('data', data);
      if (this.get('cachingEnabled'))
        this.setCache(options, data);
    },

    /**
     * Handles errors in retrieving data from the server.
     *
     * @private
     */
    onDataError: function() {
      $(this).trigger('error');
    },

    /**
     * Called when the data changes.
     *
     * @private
     */
    onDataChanged: function() {
      $(this).trigger('change', [this.get('data')]);
    },

    /**
     * Sets the data to {data}.
     */
    setData: function(data) {
      this.data = data;
      this.onDataChanged();
    },

    /**
     * Returns true if this data source has data, false otherwise.
     */
    hasData: function() {
      return this.get('data') != null;
    },

    /**
     * Requests data every {duration} ms and calls {callback} with the result.
     * You may also call this function with only a duration.
     *
     * Returns a polling interval id.
     */
    startPoller: function(duration, callback) {
      if (typeof duration != 'number')
        throw new Error("Expected duration to be a number, got " + duration);

      var me = this,
          poller = {
            id: setInterval(function(){ me._doPoll(poller) }, duration),
            xhr: null,
            callback: callback
          };
      this._pollers.push(poller);
      this._doPoll(poller);
      return poller;
    },

    /**
     * Execute the polling request for {poller} if one isn't already running.
     *
     * @private
     */
    _doPoll: function(poller) {
      poller.xhr = poller.xhr || this.requestData(function(data) {
        poller.xhr = null;
        if (poller.callback) poller.callback(data);
      });
    },

    /**
     * Stops a polling interval by id.
     */
    stopPoller: function(poller) {
      // stop the poller
      clearInterval(poller.id);

      // cancel any requests that might be running or about to run
      try { poller.xhr && poller.xhr.abort() }
      catch (e) {}
      poller.xhr = null;

      // remove the poller from the list
      var length = this._pollers.length;
      while (length--) {
        if (this._pollers[length] === poller) {
          this._pollers[length] = this._pollers.pop();
          break;
        }
      }
    },

    /**
     * Stops all pollers set on this {CredentialDataSource}, preventing
     * all previously-registered polling.
     */
    stopAllPollers: function() {
      while (this._pollers.length)
        this.stopPoller(this._pollers.shift());
    }
  });
});

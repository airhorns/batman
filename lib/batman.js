(function() {
  /*
  # batman.js
  # batman.coffee
  */  var $mixin, $redirect, $route, $typeOf, $unmixin, Batman, camelize_rx, escapeRegExp, global, helpers, isFunction, namedOrSplat, namedParam, splatParam, underscore_rx1, underscore_rx2, _objectToString;
  var __slice = Array.prototype.slice, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  Batman = function() {
    var mixins;
    mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return (function(func, args, ctor) {
      ctor.prototype = func.prototype;
      var child = new ctor, result = func.apply(child, args);
      return typeof result === "object" ? result : child;
    })(Batman.Object, mixins, function() {});
  };
  _objectToString = Object.prototype.toString;
  Batman.typeOf = $typeOf = function(object) {
    return _objectToString.call(object).slice(8, -1);
  };
  isFunction = Batman.isFunction = function(obj) {
    return !!(obj && obj.constructor && obj.call && obj.apply);
  };
  /*
  # Mixins
  */
  Batman.mixin = $mixin = function() {
    var hasSet, key, mixin, mixins, set, to, value, _base, _i, _len;
    to = arguments[0], mixins = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    set = to.set;
    hasSet = $typeOf(set) === 'Function';
    for (_i = 0, _len = mixins.length; _i < _len; _i++) {
      mixin = mixins[_i];
      if ($typeOf(mixin) !== 'Object') {
        continue;
      }
      for (key in mixin) {
        value = mixin[key];
        if (key === 'initialize' || key === 'deinitialize' || key === 'prototype') {
          continue;
        }
        if (hasSet) {
          set.call(to, key, value);
        } else {
          to[key] = value;
        }
      }
      if ($typeOf(mixin.initialize) === 'Function') {
        to._batman || (to._batman = {});
        mixin.initialize.call(to);
        (_base = to._batman).initializers || (_base.initializers = []);
        to._batman.initializers.push(mixin.initialize);
      }
    }
    return to;
  };
  Batman.unmixin = $unmixin = function() {
    var from, key, mixin, mixins, _i, _len;
    from = arguments[0], mixins = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    for (_i = 0, _len = mixins.length; _i < _len; _i++) {
      mixin = mixins[_i];
      for (key in mixin) {
        if (key === 'initialize' || key === 'deinitialize') {
          continue;
        }
        from[key] = null;
        delete from[key];
      }
      if ($typeOf(mixin.deinitialize) === 'Function') {
        mixin.deinitialize.call(from);
      }
    }
    return from;
  };
  Batman._initializeObject = function(object) {
    var batman, init, old, _i, _len, _ref;
    if (object._batman != null) {
      if (object._batman.initializedOn !== object) {
        old = object._batman;
        delete object._batman;
        batman = object._batman = {};
        batman.initializedOn = object;
        if (old.initializers != null) {
          batman.initializers = [];
        }
        _ref = old.initializers;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          init = _ref[_i];
          batman.initializers.push(init);
          init.call(object);
        }
        return true;
      }
    } else {
      return object._batman = {};
    }
  };
  Batman._findName = function(f, context) {
    var key, value;
    if (!f.displayName) {
      for (key in context) {
        value = context[key];
        if (value === f) {
          f.displayName = key;
          break;
        }
      }
    }
    return f.displayName;
  };
  /*
  # Batman.Keypath
  */
  Batman.Keypath = (function() {
    function Keypath(base, string) {
      this.base = base;
      this.string = string;
    }
    Keypath.prototype.eachPartition = function(f) {
      var index, segments, _ref, _results;
      segments = this.segments();
      _results = [];
      for (index = 0, _ref = segments.length; 0 <= _ref ? index < _ref : index > _ref; 0 <= _ref ? index++ : index--) {
        _results.push(f(segments.slice(0, index).join('.'), segments.slice(index).join('.')));
      }
      return _results;
    };
    Keypath.prototype.eachKeypath = function(f) {
      var index, keypath, _ref, _results;
      _results = [];
      for (index = 0, _ref = this.segments().length; 0 <= _ref ? index < _ref : index > _ref; 0 <= _ref ? index++ : index--) {
        keypath = this.keypathAt(index);
        if (!keypath) {
          break;
        }
        _results.push(f(keypath, index));
      }
      return _results;
    };
    Keypath.prototype.eachValue = function(f) {
      var index, _ref, _results;
      _results = [];
      for (index = 0, _ref = this.segments().length; 0 <= _ref ? index < _ref : index > _ref; 0 <= _ref ? index++ : index--) {
        _results.push(f(this.valueAt(index), index));
      }
      return _results;
    };
    Keypath.prototype.keypathAt = function(index) {
      var obj, remainingKeypath, segments;
      segments = this.segments();
      if (index >= segments.length || index < 0 || !this.base.get) {
        return;
      }
      if (index === 0) {
        return this;
      }
      obj = this.base.get(segments.slice(0, index).join('.'));
      if (!(obj && obj.get)) {
        return;
      }
      remainingKeypath = segments.slice(index).join('.');
      return new Batman.Keypath(obj, remainingKeypath);
    };
    Keypath.prototype.valueAt = function(index) {
      var segments;
      segments = this.segments();
      if (index >= segments.length || index < 0 || !this.base.get) {
        return;
      }
      return this.base.get(segments.slice(0, index + 1).join('.'));
    };
    Keypath.prototype.segments = function() {
      return this.string.split('.');
    };
    Keypath.prototype.get = function() {
      return this.base.get(this.string);
    };
    return Keypath;
  })();
  /*
  # Batman.Observable
  */
  Batman.Observable = {
    initialize: function() {
      var _base, _base2;
      (_base = this._batman).observers || (_base.observers = {});
      return (_base2 = this._batman).preventCounts || (_base2.preventCounts = {});
    },
    keypath: function(string) {
      return new Batman.Keypath(this, string);
    },
    get: function(key) {
      var value;
      return value = this[key];
    },
    set: function(key, value) {
      var newValue, oldValue;
      oldValue = this.get(key);
      newValue = this[key] = value;
      if (newValue !== oldValue) {
        return this.fire(key, newValue, oldValue);
      }
    },
    unset: function(key) {
      var oldValue;
      oldValue = this[key];
      if (oldValue && oldValue.unset) {
        return oldValue.unset(key, this);
      } else {
        this[key] = null;
        delete this[key];
        return this.fire(key, oldValue);
      }
    },
    observe: function(wholeKeypathString, fireImmediately, callback) {
      var keyObservers, self, value, wholeKeypath, _base;
      Batman._initializeObject(this);
      if (!callback) {
        callback = fireImmediately;
        fireImmediately = false;
      }
      if (!callback) {
        return this;
      }
      wholeKeypath = this.keypath(wholeKeypathString);
      keyObservers = (_base = this._batman.observers)[wholeKeypathString] || (_base[wholeKeypathString] = []);
      keyObservers.push(callback);
      self = this;
      if (wholeKeypath.segments().length > 1) {
        callback._triggers = [];
        callback._refresh_triggers = function() {
          return wholeKeypath.eachKeypath(function(keypath, index) {
            var segments, trigger, _base2;
            segments = keypath.segments();
            if (trigger = callback._triggers[index]) {
              keypath.base.forget(segments[0], trigger);
            }
            trigger = function(value, oldValue) {
              var oldKeypath;
              if (segments.length > 1 && (oldKeypath = typeof oldValue.keypath === "function" ? oldValue.keypath(segments.slice(1).join('.')) : void 0)) {
                oldKeypath.eachKeypath(function(k, i) {
                  var absoluteIndex;
                  absoluteIndex = index + i;
                  console.log("forgetting trigger at '" + k.segments()[0] + "' for '" + wholeKeypathString + "'");
                  return k.base.forget(k.segments()[0], callback._triggers[index + i]);
                });
                callback._refresh_triggers(index);
                oldValue = oldKeypath.get();
              }
              return callback.call(self, self.get(wholeKeypathString), oldValue);
            };
            console.log("adding trigger to '" + segments[0] + "' for '" + wholeKeypathString + "'");
            callback._triggers[index] = trigger;
            return typeof (_base2 = keypath.base).observe === "function" ? _base2.observe(segments[0], trigger) : void 0;
          });
        };
        callback._refresh_triggers();
        callback._forgotten = __bind(function() {
          return wholeKeypath.eachKeypath(__bind(function(keypath, index) {
            var trigger;
            if (trigger = callback._triggers[index]) {
              console.log("forgetting trigger at '" + keypath.segments()[0] + "' for '" + wholeKeypathString + "'");
              keypath.base.forget(keypath.segments()[0], trigger);
              return callback._triggers[index] = null;
            }
          }, this));
        }, this);
      }
      if (fireImmediately) {
        value = this.get(wholeKeypathString);
        callback(value, value);
      }
      return this;
    },
    fire: function(key, value, oldValue) {
      var callback, observers, _i, _j, _len, _len2, _ref, _ref2, _ref3;
      if (!this.allowed(key)) {
        return;
      }
      if (typeof value === 'undefined') {
        value = this.get(key);
      }
      _ref3 = [this._batman.observers[key], (_ref = this.constructor.prototype._batman) != null ? (_ref2 = _ref.observers) != null ? _ref2[key] : void 0 : void 0];
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        observers = _ref3[_i];
        if (observers) {
          for (_j = 0, _len2 = observers.length; _j < _len2; _j++) {
            callback = observers[_j];
            if (callback) {
              callback.call(this, value, oldValue);
            }
          }
        }
      }
      return this;
    },
    forget: function(key, callback) {
      var array, ary, callbackIndex, k, o, _i, _j, _len, _len2, _ref, _ref2;
      if (key != null) {
        if (callback != null) {
          array = this._batman.observers[key];
          callbackIndex = array.indexOf(callback);
          if (array && callbackIndex !== -1) {
            array.splice(callbackIndex, 1);
          }
          if (typeof callback._forgotten === "function") {
            callback._forgotten();
          }
        } else {
          _ref = this._batman.observers[key];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            o = _ref[_i];
            if (typeof o._forgotten === "function") {
              o._forgotten();
            }
          }
          this._batman.observers[key] = [];
        }
      } else {
        _ref2 = this._batman.observers;
        for (k in _ref2) {
          ary = _ref2[k];
          for (_j = 0, _len2 = ary.length; _j < _len2; _j++) {
            o = ary[_j];
            if (typeof o._forgotten === "function") {
              o._forgotten();
            }
          }
        }
        this._batman.observers = {};
      }
      return this;
    },
    prevent: function(key) {
      var counts, _base;
      Batman._initializeObject(this);
      counts = (_base = this._batman).preventCounts || (_base.preventCounts = {});
      counts[key] || (counts[key] = 0);
      counts[key]++;
      return this;
    },
    allow: function(key) {
      var counts, _base;
      Batman._initializeObject(this);
      counts = (_base = this._batman).preventCounts || (_base.preventCounts = {});
      if (counts[key] > 0) {
        counts[key]--;
      }
      return this;
    },
    preventAll: function() {
      return this.prevent('__all');
    },
    allowAll: function(key) {
      return this.allow('__all');
    },
    allowed: function(key) {
      var _ref, _ref2;
      Batman._initializeObject(this);
      return !(((_ref = this._batman.preventCounts) != null ? _ref[key] : void 0) > 0 || ((_ref2 = this._batman.preventCounts) != null ? _ref2['__all'] : void 0) > 0);
    },
    fireAfter: function(f) {
      this.preventAll();
      f();
      this.allowAll();
      return this;
    }
  };
  /*
  # Batman.Event
  */
  Batman.EventEmitter = {
    initialize: function() {
      var _base;
      return (_base = this._batman).events || (_base.events = {});
    },
    event: function(callback) {
      var f;
      if (!this.observe) {
        throw "EventEmitter needs to be on an object that has Batman.Observable.";
      }
      f = function(observer) {
        var key, props, value, _base;
        Batman._initializeObject(this);
        key = Batman._findName(f, this);
        props = (_base = this._batman.events)[key] || (_base[key] = {});
        if ($typeOf(observer) === 'Function') {
          if (f.isOneShot && props.fired) {
            return observer.call(this, props.value);
          } else {
            return this.observe(key, observer);
          }
        } else if (this.allowed(key)) {
          if (f.isOneShot && f.fired) {
            return false;
          }
          if (callback != null) {
            value = callback.apply(this, arguments);
          }
          value || (value = arguments[0]);
          value || (value = null);
          this.fire(key, value);
          props.fired = true;
          props.value = value;
          return value;
        } else {
          return false;
        }
      };
      return $mixin(f, {
        isEvent: true
      });
    },
    eventOneShot: function(callback) {
      return $mixin(Batman.EventEmitter.event.apply(this, arguments)({
        isOneShot: true
      }));
    }
  };
  /*
  # Batman.Object
  */
  Batman.Object = (function() {
    Object.global = function(isGlobal) {
      if (isGlobal === false) {
        return;
      }
      return global[this.name] = this;
    };
    Object.mixin = function() {
      var mixins;
      mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return $mixin.apply(null, [this].concat(__slice.call(mixins)));
    };
    Object.property = function() {
      var defaults, dependencies, f, options, optionsOrFn, _i;
      dependencies = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), optionsOrFn = arguments[_i++];
      if (optionsOrFn == null) {
        optionsOrFn = {};
      }
      f = function(value) {
        var key;
        key = Batman._findName(f, this);
        if (value != null) {
          return f.set(key, value, this);
        } else {
          return f.get(key, this);
        }
      };
      defaults = {
        get: function(key, context) {},
        set: function(key, value, context) {},
        observe: function(observer) {
          (f._preInstantiationObservers || (f._preInstantiationObservers = [])).push(observer);
          return f;
        }
      };
      if (isFunction(optionsOrFn)) {
        options = $mixin({}, defaults, {
          get: optionsOrFn
        });
      } else {
        options = $mixin({}, defaults, optionsOrFn);
      }
      $mixin(f, options);
      f.isProperty = true;
      return f;
    };
    Object.prototype.mixin = function() {
      var mixins;
      mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return $mixin.apply(null, [this].concat(__slice.call(mixins)));
    };
    function Object() {
      var mixins;
      mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      Batman._initializeObject(this);
      this.mixin.apply(this, mixins);
    }
    Object.prototype.mixin(Batman.Observable);
    Object.mixin(Batman.Observable, Batman.EventEmitter);
    return Object;
  })();
  /*
  # Batman.Deferred
  # Test Code - what is it useful for?
  */
  Batman.Deferred = (function() {
    Deferred.prototype.success = Deferred.eventOneShot();
    __extends(Deferred, Batman.Object);
    Deferred.prototype.failure = Deferred.eventOneShot();
    Deferred.prototype.all = Deferred.eventOneShot();
    function Deferred(original) {
      if (original == null) {
        original = function() {};
      }
      this.resolved = false;
      this.rejected = false;
    }
    Deferred.prototype.then = function(f) {
      this.all(f);
      return this;
    };
    Deferred.prototype.always = function() {
      return this.then.apply(this, arguments);
    };
    Deferred.prototype.done = function(f) {
      this.success(f);
      return this;
    };
    Deferred.prototype.fail = function(f) {
      this.failure(f);
      return this;
    };
    Deferred.prototype.resolve = function(resolution) {
      this.resolved = true;
      this.rejected = false;
      this.success(resolution);
      this.all(resolution);
      return this;
    };
    Deferred.prototype.reject = function(failResolution) {
      this.resolved = true;
      this.rejected = true;
      this.failure(failResolution);
      this.all(failResolution);
      return this;
    };
    Deferred.prototype.mixin(Batman.EventEmitter);
    return Deferred;
  })();
  /*
  # Batman.App
  */
  Batman.App = (function() {
    function App() {
      App.__super__.constructor.apply(this, arguments);
    }
    __extends(App, Batman.Object);
    App.requirePath = '';
    App._require = function() {
      var base, name, names, path, _i, _len, _results;
      path = arguments[0], names = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      base = this.requirePath + path;
      _results = [];
      for (_i = 0, _len = names.length; _i < _len; _i++) {
        name = names[_i];
        this.prevent('run');
        path = base + '/' + name + '.coffee';
        _results.push(new Batman.Request({
          url: path,
          type: 'html',
          success: __bind(function(response) {
            CoffeeScript.eval(response);
            this.allow('run');
            return this.run();
          }, this)
        }));
      }
      return _results;
    };
    App.controller = function() {
      var names;
      names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this._require.apply(this, ['controllers'].concat(__slice.call(names)));
    };
    App.model = function() {
      var names;
      names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this._require.apply(this, ['models'].concat(__slice.call(names)));
    };
    App.view = function() {
      var names;
      names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this._require.apply(this, ['views'].concat(__slice.call(names)));
    };
    App.layout = void 0;
    App.run = App.eventOneShot(function() {
      if (typeof this.layout === 'undefined') {
        this.set('layout', new Batman.View({
          node: document
        }));
      }
      return this.startRouting();
    });
    App.startRouting = function() {
      var f;
      if (!Batman._routes.length) {
        return;
      }
      f = function() {
        return Batman._routes[0]();
      };
      addEventListener('hashchange', f);
      if (window.location.hash.length <= 1) {
        return $redirect('/');
      } else {
        return f();
      }
    };
    App.root = function(callback) {
      return $route('/', callback);
    };
    return App;
  })();
  /*
  # Routing
  */
  namedParam = /:([\w\d]+)/g;
  splatParam = /\*([\w\d]+)/g;
  namedOrSplat = /[:|\*]([\w\d]+)/g;
  escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g;
  Batman.Route = {
    isRoute: true,
    toString: function() {
      return "route: " + this.pattern + " " + this.action;
    }
  };
  $mixin(Batman, {
    HASH_PATTERN: '#!',
    _routes: [],
    route: function(pattern, callback) {
      var callbackEater;
      callbackEater = function(callback) {
        var f;
        f = function() {
          var context;
          context = f.context || this;
          if (context && context.sharedInstance) {
            context = context.get('sharedInstance');
          }
          if (context && context.dispatch) {
            return context.dispatch(f, this);
          } else {
            return f.action.apply(context, arguments);
          }
        };
        $mixin(f, Batman.Route, {
          pattern: pattern,
          action: callback,
          context: callbackEater.context
        });
        Batman._routes.push(f);
        return f;
      };
      callbackEater.context = this;
      if ($typeOf(callback) === 'Function') {
        return callbackEater(callback);
      } else {
        return callbackEater;
      }
    },
    redirect: function(urlOrFunction) {
      var url;
      url = (urlOrFunction != null ? urlOrFunction.isRoute : void 0) ? urlOrFunction.pattern : urlOrFunction;
      return window.location.hash = "" + Batman.HASH_PATTERN + url;
    }
  });
  Batman.Object.route = $route = Batman.route;
  Batman.Object.redirect = $redirect = Batman.redirect;
  $mixin(Batman.App, {
    startRouting: function() {
      var parseUrl;
      if (typeof window === 'undefined') {
        return;
      }
      if (!Batman._routes.length) {
        return;
      }
      parseUrl = __bind(function() {
        var hash;
        hash = window.location.hash.replace(Batman.HASH_PATTERN, '');
        if (hash === this._cachedRoute) {
          return;
        }
        this._cachedRoute = hash;
        return this.dispatch(hash);
      }, this);
      if (!window.location.hash) {
        window.location.hash = "" + Batman.HASH_PATTERN + "/";
      }
      setTimeout(parseUrl, 0);
      if ('onhashchange' in window) {
        this._routeHandler = parseUrl;
        return window.addEventListener('hashchange', parseUrl);
      } else {
        return this._routeHandler = setInterval(parseUrl, 100);
      }
    },
    root: function(callback) {
      return $route('/', callback);
    }
  });
  /*
    @match: (url, action) ->
      routes = @::_routes ||= []
      match = url.replace(escapeRegExp, '\\$&')
      regexp = new RegExp('^' + match.replace(namedParam, '([^\/]*)').replace(splatParam, '(.*?)') + '$')
      namedArguments = []
  
      while (array = namedOrSplat.exec(match))?
        namedArguments.push(array[1]) if array[1]
  
      routes.push match: match, regexp: regexp, namedArguments: namedArguments, action: action
    
    startRouting: ->
      return if typeof window is 'undefined'
  
      
  
    stopRouting: ->
      if 'onhashchange' of window
        window.removeEventListener 'hashchange', @_routeHandler
        @_routeHandler = null
      else
        @_routeHandler = clearInterval @_routeHandler
  
    match: (url, action) ->
      Batman.App.match.apply @constructor, arguments
  
    routePrefix: '#!'
    redirect: (url) ->
      @_cachedRoute = url
      window.location.hash = @routePrefix + url
      @dispatch url
  
    dispatch: (url) ->
      route = @_matchRoute url
      if not route
        @redirect '/404' unless url is '/404'
        return
  
      params = @_extractParams url, route
      action = route.action
      return unless action
  
      if typeOf(action) is 'String'
        components = action.split '.'
        controllerName = helpers.camelize(components[0] + 'Controller')
        actionName = helpers.camelize(components[1], true)
  
        controller = @controller controllerName
      else if typeof action is 'object'
        controller = @controller action.controller?.name || action.controller
        actionName = action.action
  
      controller._actedDuringAction = no
      controller._currentAction = actionName
  
      controller[actionName](params)
      controller.render() if not controller._actedDuringAction
  
      delete controller._actedDuringAction
      delete controller._currentAction
  
    _matchRoute: (url) ->
      routes = @_routes
      for route in routes
        return route if route.regexp.test(url)
  
      null
  
    _extractParams: (url, route) ->
      array = route.regexp.exec(url).slice(1)
      params = url: url
  
      for param in array
        params[route.namedArguments[_i]] = param
  */
  /*
  # Batman.Controller
  */
  Batman.Controller = (function() {
    function Controller() {
      Controller.__super__.constructor.apply(this, arguments);
    }
    __extends(Controller, Batman.Object);
    Controller.sharedInstance = function() {
      if (!this._sharedInstance) {
        this._sharedInstance = new this;
      }
      return this._sharedInstance;
    };
    Controller.prototype.dispatch = function() {
      var key, params, result, route, _ref;
      route = arguments[0], params = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      this._actedDuringAction = false;
      result = (_ref = route.action).call.apply(_ref, [this].concat(__slice.call(params)));
      key = Batman._findName(route, this);
      if (!this._actedDuringAction) {
        new Batman.View({
          source: ""
        });
      }
      return delete this._actedDuringAction;
    };
    Controller.prototype.redirect = function(url) {
      this._actedDuringAction = true;
      return $redirect(url);
    };
    Controller.prototype.render = function(options) {
      var key, m, push, value, view;
      if (options == null) {
        options = {};
      }
      this._actedDuringAction = true;
      if (!options.view) {
        options.source = 'views/' + helpers.underscore(this.constructor.name.replace('Controller', '')) + '/' + this._currentAction + '.html';
        options.view = new Batman.View(options);
      }
      if (view = options.view) {
        view.context = global;
        m = {};
        push = function(key, value) {
          return function() {
            Array.prototype.push.apply(this, arguments);
            return view.context.fire(key, this);
          };
        };
        for (key in this) {
          if (!__hasProp.call(this, key)) continue;
          value = this[key];
          if (key.substr(0, 1) === '_') {
            continue;
          }
          m[key] = value;
          if (typeOf(value) === 'Array') {
            value.push = push(key, value);
          }
        }
        $mixin(global, m);
        return view.ready(function() {
          Batman.DOM.contentFor('main', view.get('node'));
          return Batman.unmixin(global, m);
        });
      }
    };
    return Controller;
  })();
  /*
  # Batman.DataStore
  */
  Batman.DataStore = (function() {
    function DataStore(model) {
      this.model = model;
      this._data = {};
    }
    __extends(DataStore, Batman.Object);
    DataStore.prototype.set = function(id, json) {
      if (!id) {
        id = model.getNewId();
      }
      return this._data['' + id] = json;
    };
    DataStore.prototype.get = function(id) {
      var record, response;
      record = this._data['' + id];
      response = {};
      response[record.id] = record;
      return response;
    };
    DataStore.prototype.all = function() {
      return Batman.mixin({}, this._data);
    };
    DataStore.prototype.query = function(params) {
      var id, json, key, match, results, value, _ref;
      results = {};
      _ref = this._data;
      for (id in _ref) {
        json = _ref[id];
        match = true;
        for (key in params) {
          value = params[key];
          if (json[key] !== value) {
            match = false;
            break;
          }
        }
        if (match) {
          results[id] = json;
        }
      }
      return results;
    };
    return DataStore;
  })();
  /*
  # Batman.Model
  */
  Batman.Model = (function() {
    Model._makeRecords = function(ids) {
      var id, json, r, _results;
      _results = [];
      for (id in ids) {
        json = ids[id];
        r = new this({
          id: id
        });
        _results.push($mixin(r, json));
      }
      return _results;
    };
    __extends(Model, Batman.Object);
    Model.hasMany = function(relation) {
      var inverse, model;
      model = helpers.camelize(helpers.singularize(relation));
      inverse = helpers.camelize(this.name, true);
      return this.prototype[relation] = Batman.Object.property(function() {
        var query;
        query = {
          model: model
        };
        query[inverse + 'Id'] = '' + this.id;
        return App.constructor[model]._makeRecords(App.dataStore.query(query));
      });
    };
    Model.hasOne = function(relation) {};
    Model.belongsTo = function(relation) {
      var key, model;
      model = helpers.camelize(helpers.singularize(relation));
      key = helpers.camelize(model, true) + 'Id';
      return this.prototype[relation] = Batman.Object.property(function(value) {
        if (arguments.length) {
          this.set(key, value && value.id ? '' + value.id : '' + value);
        }
        return App.constructor[model]._makeRecords(App.dataStore.query({
          model: model,
          id: this[key]
        }))[0];
      });
    };
    Model.persist = function(mixin) {
      if (mixin === false) {
        return;
      }
      if (!this.dataStore) {
        this.dataStore = new Batman.DataStore(this);
      }
      if (mixin === Batman) {
        ;
      } else {
        return Batman.mixin(this, mixin);
      }
    };
    Model.all = Model.property(function() {
      return this._makeRecords(this.dataStore.all());
    });
    Model.first = Model.property(function() {
      return this._makeRecords(this.dataStore.all())[0];
    });
    Model.last = Model.property(function() {
      var array;
      array = this._makeRecords(this.dataStore.all());
      return array[array.length - 1];
    });
    Model.find = function(id) {
      console.log(this.dataStore.get(id));
      return this._makeRecords(this.dataStore.get(id))[0];
    };
    Model.create = Batman.Object.property(function() {
      return new this;
    });
    Model.destroyAll = function() {
      var all, r, _i, _len, _results;
      all = this.get('all');
      _results = [];
      for (_i = 0, _len = all.length; _i < _len; _i++) {
        r = all[_i];
        _results.push(r.destroy());
      }
      return _results;
    };
    function Model() {
      this.destroy = __bind(this.destroy, this);;      this._data = {};
      Model.__super__.constructor.apply(this, arguments);
    }
    Model.prototype.id = '';
    Model.prototype.isEqual = function(rhs) {
      return this.id === rhs.id;
    };
    Model.prototype.set = function(key, value) {
      return this._data[key] = Model.__super__.set.apply(this, arguments);
    };
    Model.prototype.save = function() {
      var model;
      model = this.constructor;
      model.dataStore.set(this.id, this.toJSON());
      return this;
    };
    Model.prototype.destroy = function() {
      if (typeof this.id === 'undefined') {
        return;
      }
      App.dataStore.unset(this.id);
      App.dataStore.needsSync();
      this.constructor.fire('all', this.constructor.get('all'));
      return this;
    };
    Model.prototype.toJSON = function() {
      return this._data;
    };
    Model.prototype.fromJSON = function(data) {
      return Batman.mixin(this, data);
    };
    return Model;
  })();
  /*
  # Batman.View
  */
  Batman.View = (function() {
    function View() {
      this.reloadSource = __bind(this.reloadSource, this);;      View.__super__.constructor.apply(this, arguments);
    }
    __extends(View, Batman.Object);
    View.prototype.source = '';
    View.prototype.html = '';
    View.prototype.node = null;
    View.prototype.contentFor = null;
    View.prototype.observe('source', function() {
      return setTimeout(this.reloadSource, 0);
    });
    View.prototype.reloadSource = function() {
      if (!this.source) {
        return;
      }
      return new Batman.Request({
        url: "views/" + this.source,
        type: 'html',
        success: function(response) {
          return this.set('html', response);
        }
      });
    };
    View.prototype.observe('html', function(html) {
      var node;
      if (this.contentFor) {
        ;
      } else {
        node = this.node || document.createElement('div');
        node.innerHTML = html;
        this.node = null;
        return this.set('node', node);
      }
    });
    View.prototype.observe('node', function(node) {
      return Batman.DOM.parseNode(node);
    });
    return View;
  })();
  /*
  # Helpers
  */
  camelize_rx = /(?:^|_)(.)/g;
  underscore_rx1 = /([A-Z]+)([A-Z][a-z])/g;
  underscore_rx2 = /([a-z\d])([A-Z])/g;
  helpers = Batman.helpers = {
    camelize: function(string, firstLetterLower) {
      string = string.replace(camelize_rx, function(str, p1) {
        return p1.toUpperCase();
      });
      if (firstLetterLower) {
        return string.substr(0, 1).toLowerCase() + string.substr(1);
      } else {
        return string;
      }
    },
    underscore: function(string) {
      return string.replace(underscore_rx1, '$1_$2').replace(underscore_rx2, '$1_$2').replace('-', '_').toLowerCase();
    },
    singularize: function(string) {
      if (string.substr(-1) === 's') {
        return string.substr(0, string.length - 1);
      } else {
        return string;
      }
    },
    pluralize: function(count, string) {
      if (string) {
        if (count === 1) {
          return string;
        }
      } else {
        string = count;
      }
      if (string.substr(-1) === 'y') {
        return "" + (string.substr(0, string.length - 1)) + "ies";
      } else {
        return "" + string + "s";
      }
    }
  };
  /*
  # DOM Helpers
  */
  Batman.DOM = {
    attributes: {
      bind: function(string, node, context, observer) {
        var FIXME_firstObject, FIXME_firstPath, FIXME_lastPath, index;
        observer || (observer = function(value) {
          return Batman.DOM.valueForNode(node, value);
        });
        if ((index = string.lastIndexOf('.')) !== -1) {
          FIXME_firstPath = string.substr(0, index);
          FIXME_lastPath = string.substr(index + 1);
          FIXME_firstObject = context.get(FIXME_firstPath);
          if (FIXME_firstObject != null) {
            FIXME_firstObject.observe(FIXME_lastPath, true, observer);
          }
          Batman.DOM.events.change(node, function(value) {
            return FIXME_firstObject.set(FIXME_lastPath, value);
          });
          node._bindingContext = FIXME_firstObject;
          node._bindingKey = FIXME_lastPath;
          node._bindingObserver = observer;
        } else {
          context.observe(string, true, observer);
          Batman.DOM.events.change(node, function(value) {
            return context.set(key, value);
          });
          node._bindingContext = context;
          node._bindingKey = string;
          node._bindingObserver = observer;
        }
      },
      visible: function(string, node, context) {
        var original;
        original = node.style.display;
        return Batman.DOM.attributes.bind(string, node, context, function(value) {
          return node.style.display = !!value ? original : 'none';
        });
      },
      mixin: function(string, node, context) {
        var mixin;
        mixin = Batman.mixins[string];
        if (mixin) {
          return $mixin(node, mixin);
        }
      },
      yield: function(string, node, context) {
        return Batman.DOM.yield(string, node);
      },
      contentfor: function(string, node, context) {
        return Batman.DOM.contentFor(string, node);
      }
    },
    keyBindings: {
      bind: function(key, string, node, context) {
        return Batman.DOM.attributes.bind(string, node, context, function(value) {
          return node[key] = value;
        });
      },
      foreach: function(key, string, node, context) {
        var nodes, placeholder, prototype;
        prototype = node.cloneNode(true);
        prototype.removeAttribute("data-foreach-" + key);
        placeholder = document.createElement('span');
        placeholder.style.display = 'none';
        node.parentNode.replaceChild(placeholder, node);
        nodes = [];
        context.observe(string, true, function(array) {
          var f, node, nodesToRemove, object, _i, _j, _k, _len, _len2, _len3;
          nodesToRemove = [];
          for (_i = 0, _len = nodes.length; _i < _len; _i++) {
            node = nodes[_i];
            if (array.indexOf(node._eachItem) === -1) {
              nodesToRemove.push(node);
            }
          }
          for (_j = 0, _len2 = nodesToRemove.length; _j < _len2; _j++) {
            node = nodesToRemove[_j];
            nodes.splice(nodes.indexOf(node), 1);
            Batman.DOM.forgetNode(node);
            if (typeof node.hide === 'function') {
              node.hide(true);
            } else {
              node.parentNode.removeChild(node);
            }
          }
          for (_k = 0, _len3 = array.length; _k < _len3; _k++) {
            object = array[_k];
            if (!object) {
              continue;
            }
            node = nodes[_k];
            if (node && node._eachItem === object) {
              continue;
            }
            context[key] = object;
            node = prototype.cloneNode(true);
            node._eachItem = object;
            node.style.opacity = 0;
            Batman.DOM.parseNode(node, context);
            placeholder.parentNode.insertBefore(node, placeholder);
            nodes.push(node);
            if (node.show) {
              f = function() {
                return node.show();
              };
              setTimeout(f, 0);
            } else {
              node.style.opacity = 1;
            }
            context[key] = null;
            delete context[key];
          }
          return this;
        });
        return false;
      },
      event: function(key, string, node, context) {
        var callback, handler;
        if (key === 'click' && node.nodeName.toUpperCase() === 'A') {
          node.href = '#';
        }
        if (handler = Batman.DOM.events[key]) {
          callback = context.get(string);
          if (typeof callback === 'function') {
            handler(node, function() {
              var e;
              e = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
              return callback.apply(null, e);
            });
          }
        }
      },
      "class": function(key, string, node, context) {
        context.observe(string, true, function(value) {
          var className;
          className = node.className;
          return node.className = !!value ? "" + className + " " + key : className.replace(key, '');
        });
      },
      formfor: function(key, string, node, context) {
        context.set(key, context.get(string));
        Batman.DOM.addEventListener(node, 'submit', function(e) {
          Batman.DOM.forgetNode(node);
          context.unset(key);
          Batman.DOM.parseNode(node, context);
          return e.preventDefault();
        });
        return function() {
          return context.unset(key);
        };
      }
    },
    events: {
      change: function(node, callback) {
        var eventName, nodeName, nodeType, _ref;
        nodeName = node.nodeName.toUpperCase();
        nodeType = (_ref = node.type) != null ? _ref.toUpperCase() : void 0;
        eventName = 'change';
        if ((nodeName === 'INPUT' && nodeType === 'TEXT') || nodeName === 'TEXTAREA') {
          eventName = 'keyup';
        }
        return Batman.DOM.addEventListener(node, eventName, function() {
          var e;
          e = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return callback.apply(null, [Batman.DOM.valueForNode(node)].concat(__slice.call(e)));
        });
      },
      click: function(node, callback) {
        return Batman.DOM.addEventListener(node, 'click', function(e) {
          callback.apply(this, arguments);
          return e.preventDefault();
        });
      },
      submit: function(node, callback) {
        var nodeName;
        nodeName = node.nodeName.toUpperCase();
        if (nodeName === 'FORM') {
          return Batman.DOM.addEventListener(node, 'submit', function(e) {
            callback.apply(this, arguments);
            return e.preventDefault();
          });
        } else if (nodeName === 'INPUT') {
          return Batman.DOM.addEventListener(node, 'keyup', function(e) {
            if (e.keyCode === 13) {
              callback.apply(this, arguments);
              return e.preventDefault();
            }
          });
        }
      }
    },
    yield: function(name, node) {
      var content, yields, _base, _ref;
      yields = (_base = Batman.DOM)._yields || (_base._yields = {});
      yields[name] = node;
      if (content = (_ref = Batman.DOM._yieldContents) != null ? _ref[name] : void 0) {
        node.innerHTML = '';
        return node.appendChild(content);
      }
    },
    contentFor: function(name, node) {
      var contents, yield, _base, _ref;
      contents = (_base = Batman.DOM)._yieldContents || (_base._yieldContents = {});
      contents[name] = node;
      if (yield = (_ref = Batman.DOM._yields) != null ? _ref[name] : void 0) {
        yield.innerHTML = '';
        return yield.appendChild(node);
      }
    },
    parseNode: function(node, context) {
      var attribute, binding, c, child, continuations, index, key, result, value, _i, _j, _k, _len, _len2, _len3, _ref, _ref2;
      if (!node) {
        return;
      }
      continuations = null;
      if (typeof node.getAttribute === 'function') {
        _ref = node.attributes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          attribute = _ref[_i];
          key = attribute.nodeName;
          if (key.substr(0, 5) !== 'data-') {
            continue;
          }
          key = key.substr(5);
          value = attribute.nodeValue;
          result = (index = key.indexOf('-')) !== -1 && (binding = Batman.DOM.keyBindings[key.substr(0, index)]) ? binding(key.substr(index + 1), value, node, context) : (binding = Batman.DOM.attributes[key]) ? binding(value, node, context) : void 0;
          if (result === false) {
            return;
          } else if (typeof result === 'function') {
            continuations || (continuations = []);
            continuations.push(result);
          }
        }
      }
      _ref2 = node.childNodes;
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        child = _ref2[_j];
        Batman.DOM.parseNode(child, context);
      }
      if (continuations) {
        for (_k = 0, _len3 = continuations.length; _k < _len3; _k++) {
          c = continuations[_k];
          c();
        }
      }
    },
    forgetNode: function(node) {
      var child, _base, _i, _len, _ref, _results;
      return;
      if (!node) {
        return;
      }
      if (node._bindingContext && node._bindingObserver) {
        if (typeof (_base = node._bindingContext).forget === "function") {
          _base.forget(node._bindingKey, node._bindingObserver);
        }
      }
      _ref = node.childNodes;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        _results.push(Batman.DOM.forgetNode(child));
      }
      return _results;
    },
    valueForNode: function(node, value) {
      var isSetting, nodeName, nodeType, _ref;
      nodeName = node.nodeName.toUpperCase();
      nodeType = (_ref = node.type) != null ? _ref.toUpperCase() : void 0;
      isSetting = arguments.length > 1;
      if (isSetting) {
        value || (value = '');
      }
      if (isSetting && value === Batman.DOM.valueForNode(node)) {
        return;
      }
      if (nodeName === 'INPUT' || nodeName === 'TEXTAREA' || nodeName === 'SELECT') {
        if (nodeType === 'CHECKBOX') {
          if (isSetting) {
            return node.checked = !!value;
          } else {
            return !!node.checked;
          }
        } else {
          if (isSetting) {
            return node.value = value;
          } else {
            return node.value;
          }
        }
      }
    }
  };
  /*
  # Batman.Request
  */
  Batman.Request = (function() {
    function Request() {
      Request.__super__.constructor.apply(this, arguments);
    }
    __extends(Request, Batman.Object);
    Request.prototype.url = '';
    Request.prototype.data = '';
    Request.prototype.method = 'get';
    Request.prototype.response = null;
    Request.prototype.observe('url', function() {
      return setTimeout((__bind(function() {
        return this.send();
      }, this)), 0);
    });
    Request.prototype.loading = Request.event(function() {});
    Request.prototype.loaded = Request.event(function() {});
    Request.prototype.success = Request.event(function() {});
    Request.prototype.error = Request.event(function() {});
    return Request;
  })();
  global = typeof exports !== "undefined" && exports !== null ? exports : this;
  global.Batman = Batman;
  Batman.exportGlobals = function() {
    global.$typeOf = $typeOf;
    global.$mixin = $mixin;
    global.$unmixin = $unmixin;
    global.$route = $route;
    return global.$redirect = $redirect;
  };
}).call(this);

(function() {
  /*
  # batman.js
  # batman.coffee
  */  var $mixin, $redirect, $route, $typeOf, $unmixin, Batman, global, _objectToString;
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  Batman = function() {
    var mixins;
    mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return (function(func, args, ctor) {
      ctor.prototype = func.prototype;
      var child = new ctor, result = func.apply(child, args);
      return typeof result === "object" ? result : child;
    })(Batman.Object, mixins, function() {});
  };
  Batman.typeOf = $typeOf = function(object) {
    return _objectToString.call(object).slice(8, -1);
  };
  _objectToString = Object.prototype.toString;
  /*
  # Mixins
  */
  Batman.mixin = $mixin = function() {
    var hasSet, key, mixin, mixins, set, to, value, _i, _len;
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
        mixin.initialize.call(to);
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
  # Batman.Observable
  */
  Batman.Observable = {
    initialize: function() {
      var key, o, value, _ref;
      if (this.hasOwnProperty('_observers')) {
        return;
      }
      o = {};
      if (this._observers) {
        _ref = this._observers;
        for (key in _ref) {
          value = _ref[key];
          if (key.substr(0, 2) === '__') {
            continue;
          }
          o[key] = value.slice(0);
        }
      }
      return this._observers = o;
    },
    get: function(key) {
      var value;
      value = this[key];
      if (value && value.get) {
        return value.get(key, this);
      } else {
        return value;
      }
    },
    set: function(key, value) {
      var oldValue;
      oldValue = this[key];
      if (oldValue && oldValue.set) {
        return oldValue.set(key, value, this);
      } else {
        this[key] = value;
        return this.fire(key, value);
      }
    },
    observe: function(key, fireImmediately, callback) {
      var observers, _base;
      Batman._observerClassHack.call(this);
      if (!callback) {
        callback = fireImmediately;
        fireImmediately = false;
      }
      observers = (_base = this._observers)[key] || (_base[key] = []);
      if (observers.indexOf(callback) === -1) {
        observers.push(callback);
      }
      if (fireImmediately) {
        callback.call(this, this.get(key));
      }
      return this;
    },
    fire: function(key, value) {
      var observer, observers, _i, _len;
      if (!this.allowed(key)) {
        return;
      }
      if (typeof value === 'undefined') {
        value = this.get(key);
      }
      observers = this._observers[key];
      if (observers) {
        for (_i = 0, _len = observers.length; _i < _len; _i++) {
          observer = observers[_i];
          observer.call(this, value);
        }
      }
      return this;
    },
    prevent: function(key) {
      var counts, _base;
      Batman._observerClassHack.call(this);
      counts = (_base = this._observers).__preventCounts__ || (_base.__preventCounts__ = {});
      counts[key] || (counts[key] = 0);
      counts[key]++;
      return this;
    },
    allow: function(key) {
      var counts, _base;
      Batman._observerClassHack.call(this);
      counts = (_base = this._observers).__preventCounts__ || (_base.__preventCounts__ = {});
      if (counts[key] > 0) {
        counts[key]--;
      }
      return this;
    },
    allowed: function(key) {
      var _ref;
      Batman._observerClassHack.call(this);
      return !(((_ref = this._observers.__preventCounts__) != null ? _ref[key] : void 0) > 0);
    }
  };
  Batman._observerClassHack = function() {
    var _ref;
    if (this.prototype && ((_ref = this._observers) != null ? _ref.__initClass__ : void 0) !== this) {
      return this._observers = {
        __initClass__: this
      };
    }
  };
  /*
  # Batman.Event
  */
  Batman.Event = {
    isEvent: true,
    get: function(key, parent) {
      return this.call(parent);
    },
    set: function(key, value, parent) {
      return parent.observe(key, value);
    }
  };
  Batman.EventEmitter = {
    event: function(callback) {
      var f;
      if (!this.observe) {
        throw "EventEmitter needs to be on an object that has Batman.Observable.";
      }
      f = function(observer) {
        var key, value;
        key = Batman._findName(f, this);
        if ($typeOf(observer) === 'Function') {
          return this.observe(key, f.isOneShot && f.fired, observer);
        } else if (this.allowed(key)) {
          if (f.isOneShot && f.fired) {
            return false;
          }
          value = callback.apply(this, arguments);
          if (typeof value === 'undefined') {
            value = arguments[0];
          }
          if (typeof value === 'undefined') {
            value = null;
          }
          this.fire(key, value);
          if (f.isOneShot) {
            f.fired = true;
          }
          return value;
        } else {
          return false;
        }
      };
      return $mixin(f, Batman.Event);
    },
    eventOneShot: function(callback) {
      var f;
      f = Batman.EventEmitter.event.apply(this, arguments);
      f.isOneShot = true;
      return f;
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
    Object.prototype.mixin = function() {
      var mixins;
      mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return $mixin.apply(null, [this].concat(__slice.call(mixins)));
    };
    function Object() {
      var mixins;
      mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      Batman.Observable.initialize.call(this);
      this.mixin.apply(this, mixins);
    }
    Object.mixin(Batman.Observable, Batman.EventEmitter);
    Object.prototype.mixin(Batman.Observable);
    return Object;
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
            return this.get('run');
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
    return App;
  })();
  /*
  # Routing
  */
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
    },
    root: function(callback) {
      return $route('/', callback);
    }
  });
  /*
  # Batman.Controller
  */
  Batman.Controller = (function() {
    function Controller() {
      Controller.__super__.constructor.apply(this, arguments);
    }
    __extends(Controller, Batman.Object);
    Controller.isController = true;
    Controller._sharedInstance = null;
    Controller.sharedInstance = function() {
      if (!this._sharedInstance) {
        this._sharedInstance = new this;
      }
      return this._sharedInstance;
    };
    Controller.dispatch = function() {
      var key, params, result, route, _ref;
      route = arguments[0], params = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      this.actionTaken = false;
      result = (_ref = route.action).call.apply(_ref, [this].concat(__slice.call(params)));
      key = Batman._findName(route, this.prototype);
      if (!this.actionTaken) {
        new Batman.View({
          source: ""
        });
      }
      return delete this.actionTaken;
    };
    return Controller;
  })();
  /*
  # Batman.Model
  */
  Batman.Model = (function() {
    function Model() {
      Model.__super__.constructor.apply(this, arguments);
    }
    __extends(Model, Batman.Object);
    Model.persist = function(mechanism) {};
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
  # DOM helpers
  */
  Batman.DOM = {
    parseNode: function() {}
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

(function() {
  /*
  # batman.js
  # batman.coffee
  */  var $mixin, $redirect, $route, $typeOf, $unmixin, Batman, camelize_rx, escapeRegExp, filters, global, helpers, namedOrSplat, namedParam, splatParam, underscore_rx1, underscore_rx2, _objectToString;
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
    var key, o, value, _ref, _ref2;
    if (object.prototype && ((_ref = object._batman) != null ? _ref.__initClass__ : void 0) !== this) {
      return object._batman = {
        __initClass__: this
      };
    } else if (!object.hasOwnProperty('_batman')) {
      o = {};
      if (object._batman) {
        _ref2 = object._batman;
        for (key in _ref2) {
          value = _ref2[key];
          if ($typeOf(value) === 'Array') {
            value = Array.prototype.slice.call(value);
          }
          o[key] = value;
        }
      }
      return object._batman = o;
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
    function Keypath(base, segments) {
      this.base = base;
      this.segments = segments;
      if ($typeOf(this.segments) === 'String') {
        this.segments = this.segments.split('.');
      }
    }
    Keypath.prototype.path = function() {
      return this.segments.join('.');
    };
    Keypath.prototype.depth = function() {
      return this.segments.length;
    };
    Keypath.prototype.slice = function(begin, end) {
      var base, index, segment, _len, _ref;
      base = this.base;
      _ref = this.segments.slice(0, begin);
      for (index = 0, _len = _ref.length; index < _len; index++) {
        segment = _ref[index];
        if (!(base = base != null ? base[segment] : void 0)) {
          return;
        }
      }
      return new Batman.Keypath(base, this.segments.slice(begin, end));
    };
    Keypath.prototype.finalPair = function() {
      return this.slice(-1);
    };
    Keypath.prototype.eachPair = function(callback) {
      var base, index, nextBase, segment, _len, _ref, _results;
      base = this.base;
      _ref = this.segments;
      _results = [];
      for (index = 0, _len = _ref.length; index < _len; index++) {
        segment = _ref[index];
        if (!(nextBase = base != null ? base[segment] : void 0)) {
          return;
        }
        callback(new Batman.Keypath(base, segment), index);
        _results.push(base = nextBase);
      }
      return _results;
    };
    Keypath.prototype.resolve = function() {
      var _ref;
      switch (this.depth()) {
        case 0:
          return this.base;
        case 1:
          return this.base[this.segments[0]];
        default:
          return (_ref = this.finalPair()) != null ? _ref.resolve() : void 0;
      }
    };
    Keypath.prototype.assign = function(val) {
      switch (this.depth()) {
        case 0:
          break;
        case 1:
          return this.base[this.segments[0]] = val;
        default:
          return this.finalPair().assign(val);
      }
    };
    Keypath.prototype.remove = function() {
      switch (this.depth()) {
        case 0:
          break;
        case 1:
          this.base[this.segments[0]] = null;
          delete this.base[this.segments[0]];
          break;
        default:
          return this.finalPair().remove();
      }
    };
    Keypath.prototype.isEqual = function(other) {
      return this.base === other.base && this.path() === other.path();
    };
    return Keypath;
  })();
  /*
  # Batman.TriggerSet
  */
  Batman.TriggerSet = (function() {
    function TriggerSet() {
      this.triggers = [];
    }
    TriggerSet.prototype.add = function(keypath, depth) {
      var triggerIndex;
      triggerIndex = this._indexOfTrigger(keypath, depth);
      if (triggerIndex !== -1) {
        this.triggers[triggerIndex].observerCount++;
      } else {
        this.triggers.push({
          keypath: keypath,
          depth: depth,
          observerCount: 1
        });
      }
      return this;
    };
    TriggerSet.prototype.remove = function(keypath, depth) {
      var trigger, triggerIndex;
      triggerIndex = this._indexOfTrigger(keypath, depth);
      if (triggerIndex !== -1) {
        trigger = this.triggers[triggerIndex];
        trigger.observerCount--;
        if (trigger.observerCount === 0) {
          this.triggers.splice(triggerIndex, 1);
        }
        return trigger;
      }
    };
    TriggerSet.prototype._indexOfTrigger = function(keypath, depth) {
      var index, trigger, _len, _ref;
      _ref = this.triggers;
      for (index = 0, _len = _ref.length; index < _len; index++) {
        trigger = _ref[index];
        if (trigger.keypath.isEqual(keypath) && trigger.depth === depth) {
          return index;
        }
      }
      return -1;
    };
    return TriggerSet;
  })();
  /*
  # Batman.Observable
  */
  Batman.Observable = {
    initialize: function() {
      var _base, _base2, _base3;
      Batman._initializeObject(this);
      (_base = this._batman).observers || (_base.observers = {});
      (_base2 = this._batman).outboundTriggers || (_base2.outboundTriggers = {});
      return (_base3 = this._batman).preventCounts || (_base3.preventCounts = {});
    },
    keypath: function(string) {
      return new Batman.Keypath(this, string);
    },
    get: function(key) {
      return this.keypath(key).resolve();
    },
    set: function(key, val) {
      var minimalKeypath, oldValue;
      minimalKeypath = this.keypath(key).finalPair();
      oldValue = minimalKeypath.resolve();
      minimalKeypath.base.fire(minimalKeypath.segments[0], minimalKeypath.assign(val), oldValue);
      return val;
    },
    unset: function(key) {
      var minimalKeypath, oldValue;
      minimalKeypath = this.keypath(key).finalPair();
      oldValue = minimalKeypath.resolve();
      minimalKeypath.remove();
      minimalKeypath.base.fire(minimalKeypath.segments[0], void(0), oldValue);
    },
    observe: function() {
      var callback, currentVal, fireImmediately, key, keypath, observers, _base, _i;
      key = arguments[0], fireImmediately = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), callback = arguments[_i++];
      Batman.Observable.initialize.call(this);
      fireImmediately = fireImmediately[0] != null;
      keypath = this.keypath(key);
      currentVal = keypath.resolve();
      observers = (_base = this._batman.observers)[key] || (_base[key] = []);
      observers.push(callback);
      if (keypath.depth() > 1) {
        this._populateTriggers(keypath);
      }
      if (fireImmediately) {
        callback(currentVal, currentVal);
      }
      return this;
    },
    _populateTriggers: function(keypath, startAtIndex) {
      if (startAtIndex == null) {
        startAtIndex = 0;
      }
      return keypath.slice(startAtIndex).eachPair(function(minimalKeypath, index) {
        var thisKey, triggers;
        if (!minimalKeypath.base.observe) {
          return;
        }
        Batman.Observable.initialize.call(minimalKeypath.base);
        triggers = minimalKeypath.base._batman.outboundTriggers;
        thisKey = minimalKeypath.segments[0];
        triggers[thisKey] || (triggers[thisKey] = new Batman.TriggerSet);
        return triggers[thisKey].add(keypath, startAtIndex + index);
      });
    },
    _removeTriggers: function(key, keypath, depth) {
      var triggerSet, _ref, _ref2;
      if (triggerSet = (_ref = this._batman) != null ? (_ref2 = _ref.outboundTriggers) != null ? _ref2[key] : void 0 : void 0) {
        return triggerSet.remove(keypath, depth);
      }
    },
    fire: function(key, value, oldValue) {
      var callback, depth, keypath, observers, pathToTargetOldValue, targetNewValue, targetOldValue, trigger, triggerSet, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3, _ref4;
      if (!this.allowed(key)) {
        return;
      }
      Batman.Observable.initialize.call(this);
      _ref3 = [this._batman.observers[key], (_ref = this.constructor.prototype._batman) != null ? (_ref2 = _ref.observers) != null ? _ref2[key] : void 0 : void 0];
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        observers = _ref3[_i];
        if (!observers) {
          continue;
        }
        for (_j = 0, _len2 = observers.length; _j < _len2; _j++) {
          callback = observers[_j];
          callback.call(this, value, oldValue);
        }
      }
      if (triggerSet = this._batman.outboundTriggers[key]) {
        _ref4 = triggerSet.triggers;
        for (_k = 0, _len3 = _ref4.length; _k < _len3; _k++) {
          trigger = _ref4[_k];
          keypath = trigger.keypath, depth = trigger.depth;
          pathToTargetOldValue = new Batman.Keypath(oldValue, keypath.segments.slice(depth + 1));
          pathToTargetOldValue.eachPair(function(minimalKeypath, index) {
            return minimalKeypath.base._removeTriggers(minimalKeypath.segments[0], keypath, depth + index + 1);
          });
          keypath.base._populateTriggers(keypath, depth);
          targetOldValue = pathToTargetOldValue.resolve();
          targetNewValue = keypath.resolve();
          keypath.base.fire(keypath.path(), targetNewValue, targetOldValue);
        }
      }
      return this;
    },
    forget: function(key, callback) {
      var array, ary, callbackIndex, k, o, _i, _j, _len, _len2, _ref, _ref2;
      Batman.Observable.initialize.call(this);
      if (key) {
        if (callback) {
          array = this._batman.observers[key];
          if (array) {
            callbackIndex = array.indexOf(callback);
            if (array && callbackIndex !== -1) {
              array.splice(callbackIndex, 1);
            }
            if (typeof callback._forgotten === "function") {
              callback._forgotten();
            }
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
      var counts;
      Batman.Observable.initialize.call(this);
      counts = this._batman.preventCounts;
      counts[key] || (counts[key] = 0);
      counts[key]++;
      return this;
    },
    allow: function(key) {
      var counts;
      Batman.Observable.initialize.call(this);
      counts = this._batman.preventCounts;
      if (counts[key] > 0) {
        counts[key]--;
      }
      return this;
    },
    allowed: function(key) {
      var _ref;
      Batman.Observable.initialize.call(this);
      return !(((_ref = this._batman.preventCounts) != null ? _ref[key] : void 0) > 0);
    }
  };
  /*
  # Batman.Event
  */
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
      return $mixin(f, {
        isEvent: true
      });
    },
    eventOneShot: function(callback) {
      return $mixin(Batman.EventEmitter.event.apply(this, arguments), {
        isOneShot: true
      });
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
    Object.property = function(foo) {
      return {};
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
      Batman._initializeObject(this);
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
    __extends(App, Batman.Object);
    function App() {
      App.__super__.constructor.apply(this, arguments);
    }
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
        return this.set('layout', new Batman.View({
          node: document
        }));
      }
    });
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
  # Batman.Controller
  */
  Batman.Controller = (function() {
    __extends(Controller, Batman.Object);
    function Controller() {
      Controller.__super__.constructor.apply(this, arguments);
    }
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
    __extends(DataStore, Batman.Object);
    function DataStore(model) {
      this.model = model;
      this._data = {};
    }
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
    __extends(Model, Batman.Object);
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
      this.destroy = __bind(this.destroy, this);      this._data = {};
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
    __extends(View, Batman.Object);
    function View() {
      this.reloadSource = __bind(this.reloadSource, this);
      View.__super__.constructor.apply(this, arguments);
    }
    View.prototype.source = '';
    View.prototype.html = '';
    View.prototype.node = null;
    View.prototype.contentFor = null;
    View.prototype.ready = View.event(function() {});
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
      return new Batman.Renderer(node, __bind(function() {
        return this.ready();
      }, this));
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
  # Filters
  */
  filters = Batman.filters = {};
  /*
  # DOM Helpers
  */
  Batman.Renderer = (function() {
    var regexp;
    __extends(Renderer, Batman.Object);
    function Renderer(node, callback) {
      this.node = node;
      this.callback = callback;
      this.resume = __bind(this.resume, this);
      this.start = __bind(this.start, this);
      Renderer.__super__.constructor.apply(this, arguments);
      setTimeout(this.start, 0);
    }
    Renderer.prototype.start = function() {
      this.tree = {};
      this.startTime = new Date;
      return this.parseNode(this.node);
    };
    Renderer.prototype.resume = function() {
      console.log('resume');
      this.startTime = new Date;
      return this.parseNode(this.resumeNode);
    };
    Renderer.prototype.finish = function() {
      console.log('done');
      this.startTime = null;
      return this.callback();
    };
    regexp = /data\-(.*)/;
    Renderer.prototype.parseNode = function(node) {
      var attr, name, nextNode, _i, _len, _ref;
      if ((new Date) - this.startTime > 50) {
        console.log('stopping');
        this.resumeNode = node;
        setTimeout(this.resume, 0);
        return;
      }
      if (node.getAttribute) {
        _ref = node.attributes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          attr = _ref[_i];
          name = attr.nodeName;
          console.log(node.nodeName, name, name.match(regexp));
        }
      }
      if ((nextNode = this.nextNode(node))) {
        return this.parseNode(nextNode);
      } else {
        return this.finish;
      }
    };
    Renderer.prototype.nextNode = function(node) {
      var children, nextParent, parentSibling, sibling;
      children = node.childNodes;
      if (children != null ? children.length : void 0) {
        return children[0];
      }
      sibling = node.nextSibling;
      if (sibling) {
        return sibling;
      }
      nextParent = node;
      while (nextParent = nextParent.parentNode) {
        parentSibling = nextParent.nextSibling;
        if (parentSibling) {
          return parentSibling;
        }
      }
    };
    return Renderer;
  })();
  Batman.DOM = {
    readers: {},
    keyReaders: {}
  };
  /*
  # Batman.Request
  */
  Batman.Request = (function() {
    __extends(Request, Batman.Object);
    function Request() {
      Request.__super__.constructor.apply(this, arguments);
    }
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

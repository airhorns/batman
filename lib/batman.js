(function() {
  var $block, $event, $eventOneShot, $findName, $mixin, $redirect, $route, $typeOf, $unmixin, Batman, camelize_rx, container, escapeRegExp, filters, helpers, matchContext, mixins, namedOrSplat, namedParam, queryParam, splatParam, underscore_rx1, underscore_rx2, validators, _class, _class2, _objectToString, _stateMachine_setState;
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
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
  Batman.typeOf = $typeOf = function(object) {
    return _objectToString.call(object).slice(8, -1);
  };
  _objectToString = Object.prototype.toString;
  Batman.mixin = $mixin = function() {
    var hasSet, key, mixin, mixins, set, to, value, _i, _len;
    to = arguments[0], mixins = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    set = to.set;
    hasSet = typeof set === 'function';
    for (_i = 0, _len = mixins.length; _i < _len; _i++) {
      mixin = mixins[_i];
      if ($typeOf(mixin) !== 'Object') {
        continue;
      }
      for (key in mixin) {
        value = mixin[key];
        if (key === 'initialize' || key === 'uninitialize' || key === 'prototype') {
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
        if (key === 'initialize' || key === 'uninitialize') {
          continue;
        }
        from[key] = null;
        delete from[key];
      }
      if (typeof mixin.deinitialize === 'function') {
        mixin.deinitialize.call(from);
      }
    }
    return from;
  };
  Batman._block = $block = function(fn) {
    var callbackEater;
    return callbackEater = function() {
      var args, ctx, f;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      ctx = this;
      f = function(callback) {
        args.push(callback);
        return fn.apply(ctx, args);
      };
      if (typeof args[args.length - 1] === 'function') {
        return f(args.pop());
      } else {
        return f;
      }
    };
  };
  Batman._findName = $findName = function(f, context) {
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
  Batman.Property = (function() {
    Property.defaultAccessor = {
      get: function(key) {
        return this[key];
      },
      set: function(key, val) {
        return this[key] = val;
      },
      unset: function(key) {
        this[key] = null;
        delete this[key];
      }
    };
    Property.triggerTracker = null;
    Property["for"] = function(base, key) {
      var properties, _base;
      if (base._batman) {
        Batman._initializeObject(base);
        properties = (_base = base._batman).properties || (_base.properties = new Batman.SimpleHash);
        return properties.get(key) || properties.set(key, new this(base, key));
      } else {
        return new this(base, key);
      }
    };
    function Property(base, key) {
      this.base = base;
      this.key = key;
    }
    Property.prototype.isProperty = true;
    Property.prototype.accessor = function() {
      var key, result, val, _i, _len, _ref;
      key = this.key;
      _ref = Batman._lookupAllBatmanKeys(this.base, 'keyAccessors');
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        result = _ref[_i];
        if ((val = result.get(key))) {
          return val;
        }
      }
      return Batman._lookupBatmanKey(this.base, 'defaultAccessor') || Batman.Property.defaultAccessor;
    };
    Property.prototype.registerAsTrigger = function() {
      var tracker;
      if (tracker = Batman.Property.triggerTracker) {
        return tracker.add(this);
      }
    };
    Property.prototype.getValue = function() {
      var _ref;
      this.registerAsTrigger();
      return (_ref = this.accessor()) != null ? _ref.get.call(this.base, this.key) : void 0;
    };
    Property.prototype.setValue = function(val) {
      var _ref;
      return (_ref = this.accessor()) != null ? _ref.set.call(this.base, this.key, val) : void 0;
    };
    Property.prototype.unsetValue = function() {
      var _ref;
      return (_ref = this.accessor()) != null ? _ref.unset.call(this.base, this.key) : void 0;
    };
    Property.prototype.isEqual = function(other) {
      return this.constructor === other.constructor && this.base === other.base && this.key === other.key;
    };
    return Property;
  })();
  Batman.ObservableProperty = (function() {
    __extends(ObservableProperty, Batman.Property);
    function ObservableProperty(base, key) {
      ObservableProperty.__super__.constructor.apply(this, arguments);
      this.observers = new Batman.SimpleSet;
      if (this.hasObserversToFire()) {
        this.refreshTriggers();
      }
      this._preventCount = 0;
    }
    ObservableProperty.prototype.setValue = function(val) {
      this.cacheDependentValues();
      ObservableProperty.__super__.setValue.apply(this, arguments);
      this.fireDependents();
      return val;
    };
    ObservableProperty.prototype.unsetValue = function() {
      this.cacheDependentValues();
      ObservableProperty.__super__.unsetValue.apply(this, arguments);
      this.fireDependents();
    };
    ObservableProperty.prototype.cacheDependentValues = function() {
      if (this.dependents) {
        return this.dependents.each(function(prop) {
          return prop.cachedValue = prop.getValue();
        });
      }
    };
    ObservableProperty.prototype.fireDependents = function() {
      if (this.dependents) {
        return this.dependents.each(function(prop) {
          if (typeof prop.hasObserversToFire === "function" ? prop.hasObserversToFire() : void 0) {
            return prop.fire(prop.getValue(), prop.cachedValue);
          }
        });
      }
    };
    ObservableProperty.prototype.observe = function() {
      var callback, currentValue, fireImmediately, _i;
      fireImmediately = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), callback = arguments[_i++];
      fireImmediately = fireImmediately[0] === true;
      currentValue = this.getValue();
      this.observers.add(callback);
      this.refreshTriggers();
      if (fireImmediately) {
        callback.call(this.base, currentValue, currentValue);
      }
      return this;
    };
    ObservableProperty.prototype.hasObserversToFire = function() {
      var _base;
      if (this.observers.length > 0) {
        return true;
      }
      if (this.base === this.base.constructor.prototype) {
        return false;
      }
      return (typeof (_base = this.base.constructor).prototype.property === "function" ? _base.prototype.property(this.key).observers.length : void 0) > 0;
    };
    ObservableProperty.prototype.preventFire = function() {
      return this._preventCount++;
    };
    ObservableProperty.prototype.allowFire = function() {
      if (this._preventCount > 0) {
        return this._preventCount--;
      }
    };
    ObservableProperty.prototype.isAllowedToFire = function() {
      return this._preventCount <= 0;
    };
    ObservableProperty.prototype.fire = function() {
      var args, base, key, observers, properties, propertyObservers, _i, _len;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (!this.hasObserversToFire()) {
        return;
      }
      key = this.key;
      base = this.base;
      properties = Batman._lookupAllBatmanKeys(this.base);
      propertyObservers = [this.observers].concat(properties.map(function(property) {
        return property != null ? typeof property.property === "function" ? property.property(key).observers : void 0 : void 0;
      }));
      for (_i = 0, _len = propertyObservers.length; _i < _len; _i++) {
        observers = propertyObservers[_i];
        if (observers != null) {
          observers.each(function(callback) {
            return callback != null ? callback.apply(base, args) : void 0;
          });
        }
      }
      return this.refreshTriggers();
    };
    ObservableProperty.prototype.forget = function(observer) {
      if (observer) {
        this.observers.remove(observer);
      } else {
        this.observers = new Batman.SimpleSet;
      }
      if (!this.hasObserversToFire()) {
        return this.clearTriggers();
      }
    };
    ObservableProperty.prototype.refreshTriggers = function() {
      Batman.Property.triggerTracker = new Batman.SimpleSet;
      this.getValue();
      if (this.triggers) {
        this.triggers.each(__bind(function(property) {
          var _ref;
          if (!Batman.Property.triggerTracker.has(property)) {
            return (_ref = property.dependents) != null ? _ref.remove(this) : void 0;
          }
        }, this));
      }
      this.triggers = Batman.Property.triggerTracker;
      this.triggers.each(__bind(function(property) {
        property.dependents || (property.dependents = new Batman.SimpleSet);
        return property.dependents.add(this);
      }, this));
      return Batman.Property.triggerTracker = null;
    };
    ObservableProperty.prototype.clearTriggers = function() {
      this.triggers.each(__bind(function(property) {
        return property.dependents.remove(this);
      }, this));
      return this.triggers = new Batman.SimpleSet;
    };
    return ObservableProperty;
  })();
  Batman.Keypath = (function() {
    __extends(Keypath, Batman.ObservableProperty);
    function Keypath(base, key) {
      if ($typeOf(key) === 'String') {
        this.segments = key.split('.');
        this.depth = this.segments.length;
      } else {
        this.segments = [key];
        this.depth = 1;
      }
      Keypath.__super__.constructor.apply(this, arguments);
    }
    Keypath.prototype.slice = function(begin, end) {
      var base, segment, _i, _len, _ref;
      base = this.base;
      _ref = this.segments.slice(0, begin);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        segment = _ref[_i];
        if (!((base != null) && (base = Batman.Keypath["for"](base, segment).getValue()))) {
          return;
        }
      }
      return Batman.Keypath["for"](base, this.segments.slice(begin, end).join('.'));
    };
    Keypath.prototype.terminalProperty = function() {
      return this.slice(-1);
    };
    Keypath.prototype.getValue = function() {
      var _ref;
      this.registerAsTrigger();
      if (this.depth === 1) {
        return Keypath.__super__.getValue.apply(this, arguments);
      } else {
        return (_ref = this.terminalProperty()) != null ? _ref.getValue() : void 0;
      }
    };
    Keypath.prototype.setValue = function(val) {
      var _ref;
      if (this.depth === 1) {
        return Keypath.__super__.setValue.apply(this, arguments);
      } else {
        return (_ref = this.terminalProperty()) != null ? _ref.setValue(val) : void 0;
      }
    };
    Keypath.prototype.unsetValue = function() {
      var _ref;
      if (this.depth === 1) {
        return Keypath.__super__.unsetValue.apply(this, arguments);
      } else {
        return (_ref = this.terminalProperty()) != null ? _ref.unsetValue() : void 0;
      }
    };
    return Keypath;
  })();
  Batman.Observable = {
    isObservable: true,
    property: function(key) {
      Batman._initializeObject(this);
      return Batman.Keypath["for"](this, key);
    },
    get: function(key) {
      return this.property(key).getValue();
    },
    set: function(key, val) {
      return this.property(key).setValue(val);
    },
    unset: function(key) {
      return this.property(key).unsetValue();
    },
    observe: function() {
      var args, key, _ref;
      key = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      (_ref = this.property(key)).observe.apply(_ref, args);
      return this;
    },
    fire: function() {
      var args, key, _ref;
      key = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return (_ref = this.property(key)).fire.apply(_ref, args);
    },
    forget: function(key, observer) {
      if (key) {
        this.property(key).forget(observer);
      } else {
        this._batman.properties.each(function(key, property) {
          return property.forget();
        });
      }
      return this;
    },
    prevent: function(key) {
      this.property(key).preventFire();
      return this;
    },
    allow: function(key) {
      this.property(key).allowFire();
      return this;
    },
    allowed: function(key) {
      return this.property(key).isAllowedToFire();
    }
  };
  Batman.EventEmitter = {
    event: $block(function(key, context, callback) {
      var f;
      if (!callback && typeof context !== 'undefined') {
        callback = context;
        context = null;
      }
      if (!callback && $typeOf(key) !== 'String') {
        callback = key;
        key = null;
      }
      f = function(observer) {
        var args, fired, firings, value, _base, _ref, _ref2;
        if (!this.observe) {
          throw "EventEmitter requires Observable";
        }
        Batman._initializeObject(this);
        key || (key = $findName(f, this));
        fired = (_ref = this._batman._oneShotFired) != null ? _ref[key] : void 0;
        if (typeof observer === 'function') {
          this.observe(key, observer);
          if (f.isOneShot && fired) {
            return observer.apply(this, f._firedArgs);
          }
        } else if (this.allowed(key)) {
          if (f.isOneShot && fired) {
            return false;
          }
          value = callback != null ? callback.apply(this, arguments) : void 0;
          if (value !== false) {
            f._firedArgs = typeof value !== 'undefined' ? (_ref2 = [value]).concat.apply(_ref2, arguments) : arguments.length === 0 ? [] : Array.prototype.slice.call(arguments);
            args = Array.prototype.slice.call(f._firedArgs);
            args.unshift(key);
            this.fire.apply(this, args);
            if (f.isOneShot) {
              firings = (_base = this._batman)._oneShotFired || (_base._oneShotFired = {});
              firings[key] = true;
            }
          }
          return value;
        } else {
          return false;
        }
      };
      if (context) {
        f = f.bind(context);
      }
      if (key != null) {
        this[key] = f;
      }
      return $mixin(f, {
        isEvent: true,
        action: callback,
        isOneShot: this.isOneShot
      });
    }),
    eventOneShot: function(callback) {
      return $mixin(Batman.EventEmitter.event.apply(this, arguments), {
        isOneShot: true
      });
    }
  };
  $event = function(callback) {
    var context;
    context = new Batman.Object;
    return context.event('_event', context, callback);
  };
  $eventOneShot = function(callback) {
    var context;
    context = new Batman.Object;
    return context.eventOneShot('_event', context, callback);
  };
  /*
  # Batman.StateMachine
  */
  Batman.StateMachine = {
    initialize: function() {
      Batman._initializeObject(this);
      if (!this._batman.states) {
        this._batman.states = {};
        return this.accessor('state', {
          get: function() {
            return this.state();
          },
          set: function(key, value) {
            return _stateMachine_setState.call(this, value);
          }
        });
      }
    },
    state: function(name, callback) {
      var event;
      Batman.StateMachine.initialize.call(this);
      if (!name) {
        return Batman._lookupBatmanKey(this, 'state');
      }
      if (!this.event) {
        throw "StateMachine requires EventEmitter";
      }
      event = this[name] || this.event(name, function() {
        _stateMachine_setState.call(this, name);
        return false;
      });
      if (typeof callback === 'function') {
        event.call(this, callback);
      }
      return event;
    },
    transition: function(from, to, callback) {
      var event, name, transitions;
      Batman.StateMachine.initialize.call(this);
      this.state(from);
      this.state(to);
      name = "" + from + "->" + to;
      transitions = this._batman.states;
      event = transitions[name] || (transitions[name] = $event(function() {}));
      if (callback) {
        event(callback);
      }
      return event;
    }
  };
  _stateMachine_setState = function(newState) {
    var event, name, oldState, _base, _i, _len, _ref, _ref2;
    Batman.StateMachine.initialize.call(this);
    if (this._batman.isTransitioning) {
      ((_base = this._batman).nextState || (_base.nextState = [])).push(newState);
      return false;
    }
    this._batman.isTransitioning = true;
    oldState = this.state();
    this._batman.state = newState;
    if (newState && oldState) {
      name = "" + oldState + "->" + newState;
      _ref = Batman._lookupAllBatmanKeys(this, 'states', name);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        event = _ref[_i];
        if (event) {
          event(newState, oldState);
        }
      }
    }
    if (newState) {
      this.fire(newState, newState, oldState);
    }
    this._batman.isTransitioning = false;
    if ((_ref2 = this._batman.nextState) != null ? _ref2.length : void 0) {
      this[this._batman.nextState.shift()]();
    }
    return newState;
  };
  Batman._initializeObject = function(object) {
    var _ref;
    if (object.prototype && ((_ref = object._batman) != null ? _ref.__initClass__ : void 0) !== object) {
      return object._batman = {
        __initClass__: object
      };
    } else if (!object.hasOwnProperty('_batman')) {
      return object._batman = {};
    }
  };
  Batman._lookupBatmanKey = function(object, key) {
    var nextClass, val, _ref, _ref2, _ref3, _ref4;
    if ((val = (_ref = object._batman) != null ? _ref[key] : void 0)) {
      return val;
    }
    nextClass = object.constructor;
    while (nextClass) {
      if ((val = (_ref2 = nextClass.prototype) != null ? (_ref3 = _ref2._batman) != null ? _ref3[key] : void 0 : void 0)) {
        return val;
      }
      nextClass = (_ref4 = nextClass.__super__) != null ? _ref4.constructor : void 0;
    }
  };
  Batman._lookupAllBatmanKeys = function(object, key, subkey) {
    var isClass, nextClass, results, val, _ref, _ref2, _ref3, _ref4, _ref5, _ref6;
    results = [];
    if ((val = (_ref = object._batman) != null ? _ref[key] : void 0)) {
      results.push(val);
    }
    isClass = !!object.prototype;
    nextClass = isClass ? (_ref2 = object.__super__) != null ? _ref2.constructor : void 0 : object.constructor;
    while (nextClass) {
      if (!key) {
        results.push(nextClass.prototype);
      } else if (isClass && (val = (_ref3 = nextClass._batman) != null ? _ref3[key] : void 0)) {
        results.push(val);
      } else if (!isClass && (val = (_ref4 = nextClass.prototype) != null ? (_ref5 = _ref4._batman) != null ? _ref5[key] : void 0 : void 0)) {
        results.push(val);
      }
      nextClass = (_ref6 = nextClass.__super__) != null ? _ref6.constructor : void 0;
    }
    if (subkey) {
      return results.map(function(result) {
        return result[subkey];
      });
    } else {
      return results;
    }
  };
  Batman.Object = (function() {
    Object.global = function(isGlobal) {
      if (isGlobal === false) {
        return;
      }
      return container[this.name] = this;
    };
    Object.mixin = function() {
      var mixins;
      mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return $mixin.apply(null, [this].concat(__slice.call(mixins)));
    };
    Object.prototype.mixin = Object.mixin;
    Object.accessor = function() {
      var accessor, key, keys, value, _base, _base2, _i, _j, _len, _results, _results2;
      keys = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), accessor = arguments[_i++];
      Batman._initializeObject(this);
      if (keys.length === 0) {
        if (accessor.get || accessor.set) {
          return this._batman.defaultAccessor = accessor;
        } else {
          (_base = this._batman).keyAccessors || (_base.keyAccessors = new Batman.SimpleHash);
          _results = [];
          for (key in accessor) {
            value = accessor[key];
            this._batman.keyAccessors.set(key, {
              get: value,
              set: value
            });
            _results.push(this[key] = value);
          }
          return _results;
        }
      } else {
        (_base2 = this._batman).keyAccessors || (_base2.keyAccessors = new Batman.SimpleHash);
        _results2 = [];
        for (_j = 0, _len = keys.length; _j < _len; _j++) {
          key = keys[_j];
          _results2.push(this._batman.keyAccessors.set(key, accessor));
        }
        return _results2;
      }
    };
    Object.prototype.accessor = Object.accessor;
    function Object() {
      var mixins;
      mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      Batman._initializeObject(this);
      this.mixin.apply(this, mixins);
    }
    Object.mixin(Batman.Observable, Batman.EventEmitter);
    Object.prototype.mixin(Batman.Observable, Batman.EventEmitter);
    return Object;
  })();
  Batman.SimpleHash = (function() {
    function SimpleHash() {
      this._storage = {};
      this.length = 0;
    }
    SimpleHash.prototype.hasKey = function(key) {
      return typeof this.get(key) !== 'undefined';
    };
    SimpleHash.prototype.get = function(key) {
      var matches, obj, v, _i, _len, _ref;
      if (key === 'length') {
        return this.length;
      }
      if (matches = this._storage[key]) {
        for (_i = 0, _len = matches.length; _i < _len; _i++) {
          _ref = matches[_i], obj = _ref[0], v = _ref[1];
          if (this.equality(obj, key)) {
            return v;
          }
        }
      }
    };
    SimpleHash.prototype.set = function(key, val) {
      var match, matches, pair, _base, _i, _len;
      matches = (_base = this._storage)[key] || (_base[key] = []);
      for (_i = 0, _len = matches.length; _i < _len; _i++) {
        match = matches[_i];
        if (this.equality(match[0], key)) {
          pair = match;
        }
      }
      if (!pair) {
        pair = [key];
        matches.push(pair);
      }
      return pair[1] = val;
    };
    SimpleHash.prototype.unset = function(key) {
      var index, matches, obj, v, _len, _ref;
      if (matches = this._storage[key]) {
        for (index = 0, _len = matches.length; index < _len; index++) {
          _ref = matches[index], obj = _ref[0], v = _ref[1];
          if (this.equality(obj, key)) {
            matches.splice(index, 1);
            return;
          }
        }
      }
    };
    SimpleHash.prototype.equality = function(lhs, rhs) {
      if (typeof lhs.isEqual === 'function') {
        return lhs.isEqual(rhs);
      } else if (typeof rhs.isEqual === 'function') {
        return rhs.isEqual(lhs);
      } else {
        return lhs === rhs;
      }
    };
    SimpleHash.prototype.each = function(iterator) {
      var key, obj, value, values, _ref, _results;
      _ref = this._storage;
      _results = [];
      for (key in _ref) {
        values = _ref[key];
        _results.push((function() {
          var _i, _len, _ref2, _results2;
          _results2 = [];
          for (_i = 0, _len = values.length; _i < _len; _i++) {
            _ref2 = values[_i], obj = _ref2[0], value = _ref2[1];
            _results2.push(iterator(obj, value));
          }
          return _results2;
        })());
      }
      return _results;
    };
    SimpleHash.prototype.keys = function() {
      var result;
      result = [];
      this.each(function(obj) {
        return result.push(obj);
      });
      return result;
    };
    SimpleHash.prototype.clear = function() {
      return this.each(function(obj) {
        return this.unset(obj);
      });
    };
    SimpleHash.prototype.isEmpty = function() {
      return this.keys().length === 0;
    };
    return SimpleHash;
  })();
  Batman.Hash = (function() {
    var k, _i, _len, _ref;
    __extends(Hash, Batman.Object);
    function Hash() {
      Hash.__super__.constructor.apply(this, arguments);
      _class.apply(this, arguments);
    }
    _class = Batman.SimpleHash;
    Hash.prototype.accessor({
      get: Batman.SimpleHash.prototype.get,
      set: Batman.SimpleHash.prototype.set,
      unset: Batman.SimpleHash.prototype.unset
    });
    Hash.prototype.accessor('isEmpty', {
      get: function() {
        return this.isEmpty();
      }
    });
    _ref = ['hasKey', 'equality', 'each', 'keys'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      k = _ref[_i];
      Hash.prototype[k] = Batman.SimpleHash.prototype[k];
    }
    return Hash;
  })();
  Batman.SimpleSet = (function() {
    var k, _i, _len, _ref;
    function SimpleSet() {
      this._storage = new Batman.SimpleHash;
      this.length = 0;
      if (arguments.length > 0) {
        this.add.apply(this, arguments);
      }
    }
    SimpleSet.prototype.has = function(item) {
      return this._storage.hasKey(item);
    };
    _ref = ['get', 'set', 'unset'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      k = _ref[_i];
      SimpleSet.prototype[k] = Batman.Property.defaultAccessor[k];
    }
    SimpleSet.prototype.add = function() {
      var item, items, _j, _len2;
      items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      for (_j = 0, _len2 = items.length; _j < _len2; _j++) {
        item = items[_j];
        if (!this._storage.hasKey(item)) {
          this._storage.set(item, true);
          this.set('length', this.length + 1);
          this.set('isEmpty', true);
        }
      }
      return items;
    };
    SimpleSet.prototype.remove = function() {
      var item, items, results, _j, _len2;
      items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      results = [];
      for (_j = 0, _len2 = items.length; _j < _len2; _j++) {
        item = items[_j];
        if (this._storage.hasKey(item)) {
          this._storage.unset(item);
          results.push(item);
          this.set('length', this.length - 1);
          this.set('isEmpty', true);
        }
      }
      return results;
    };
    SimpleSet.prototype.each = function(iterator) {
      return this._storage.each(function(key, value) {
        return iterator(key);
      });
    };
    SimpleSet.prototype.isEmpty = function() {
      return this.get('length') === 0;
    };
    SimpleSet.prototype.clear = function() {
      return this.remove(this.toArray());
    };
    SimpleSet.prototype.toArray = function() {
      return this._storage.keys();
    };
    return SimpleSet;
  })();
  Batman.Set = (function() {
    var k, _i, _j, _len, _len2, _ref, _ref2;
    __extends(Set, Batman.Object);
    function Set() {
      Set.__super__.constructor.apply(this, arguments);
      _class2.apply(this, arguments);
    }
    _class2 = Batman.SimpleSet;
    _ref = ['add', 'remove'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      k = _ref[_i];
      Set.prototype[k] = Set.event(Batman.SimpleSet.prototype[k]);
    }
    _ref2 = ['has', 'each', 'isEmpty', 'toArray', 'clear'];
    for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
      k = _ref2[_j];
      Set.prototype[k] = Batman.SimpleSet.prototype[k];
    }
    Set.prototype.accessor('isEmpty', {
      get: (function() {
        return this.isEmpty();
      }),
      set: function() {}
    });
    return Set;
  })();
  Batman.SortableSet = (function() {
    __extends(SortableSet, Batman.Set);
    function SortableSet(index) {
      SortableSet.__super__.constructor.apply(this, arguments);
      this._indexes = {};
      this.addIndex(index);
    }
    SortableSet.prototype.add = SortableSet.event(function() {
      var results;
      results = Batman.SimpleSet.prototype.add.apply(this, arguments);
      this._reIndex();
      return results;
    });
    SortableSet.prototype.remove = SortableSet.event(function() {
      var results;
      results = Batman.SimpleSet.prototype.remove.apply(this, arguments);
      this._reIndex();
      return results;
    });
    SortableSet.prototype.addIndex = function(keypath) {
      this._reIndex(keypath);
      return this.activeIndex = keypath;
    };
    SortableSet.prototype.removeIndex = function(keypath) {
      this._indexes[keypath] = null;
      delete this._indexes[keypath];
      return keypath;
    };
    SortableSet.prototype.each = function(iterator) {
      var el, _i, _len, _ref, _results;
      _ref = toArray();
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        el = _ref[_i];
        _results.push(iterator(el));
      }
      return _results;
    };
    SortableSet.prototype.toArray = function() {
      var ary, _ref;
      return ary = (_ref = this._indexes[this.activeIndex]) != null ? _ref : {
        ary: SortableSet.__super__.toArray.apply(this, arguments)
      };
    };
    SortableSet.prototype._reIndex = function(index) {
      var ary, keypath, ordering, _ref, _results;
      if (index) {
        _ref = index.split(' '), keypath = _ref[0], ordering = _ref[1];
        ary = Batman.Set.prototype.toArray.call(this);
        return this._indexes[index] = ary.sort(function(a, b) {
          var valueA, valueB, _ref2, _ref3, _ref4;
          valueA = (_ref2 = (Batman.Observable.property.call(a, keypath)).getValue()) != null ? _ref2.valueOf() : void 0;
          valueB = (_ref3 = (Batman.Observable.property.call(b, keypath)).getValue()) != null ? _ref3.valueOf() : void 0;
          if ((ordering != null ? ordering.toLowerCase() : void 0) === 'desc') {
            _ref4 = [valueB, valueA], valueA = _ref4[0], valueB = _ref4[1];
          }
          if (valueA < valueB) {
            return -1;
          } else if (valueA > valueB) {
            return 1;
          } else {
            return 0;
          }
        });
      } else {
        _results = [];
        for (index in this._indexes) {
          _results.push(this._reIndex(index));
        }
        return _results;
      }
    };
    return SortableSet;
  })();
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
      return this._autosendTimeout = setTimeout((__bind(function() {
        return this.send();
      }, this)), 0);
    });
    Request.prototype.loading = Request.event(function() {});
    Request.prototype.loaded = Request.event(function() {});
    Request.prototype.success = Request.event(function() {});
    Request.prototype.error = Request.event(function() {});
    Request.prototype.send = function() {
      throw "Please source a dependency file for a request implementation";
    };
    Request.prototype.cancel = function() {
      if (this._autosendTimeout) {
        return clearTimeout(this._autosendTimeout);
      }
    };
    return Request;
  })();
  Batman.App = (function() {
    __extends(App, Batman.Object);
    function App() {
      App.__super__.constructor.apply(this, arguments);
    }
    App.requirePath = '';
    App.require = function() {
      var base, name, names, path, _i, _len;
      path = arguments[0], names = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      base = this.requirePath + path;
      for (_i = 0, _len = names.length; _i < _len; _i++) {
        name = names[_i];
        this.prevent('run');
        path = base + '/' + name + '.coffee';
        new Batman.Request({
          url: path,
          type: 'html',
          success: __bind(function(response) {
            CoffeeScript.eval(response);
            this.allow('run');
            return this.run();
          }, this)
        });
      }
      return this;
    };
    App.controller = function() {
      var names;
      names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.require.apply(this, ['controllers'].concat(__slice.call(names)));
    };
    App.model = function() {
      var names;
      names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.require.apply(this, ['models'].concat(__slice.call(names)));
    };
    App.view = function() {
      var names;
      names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.require.apply(this, ['views'].concat(__slice.call(names)));
    };
    App.layout = void 0;
    App.run = App.eventOneShot(function() {
      if (this.hasRun) {
        return false;
      }
      Batman.currentApp = this;
      if (typeof this.layout === 'undefined') {
        this.set('layout', new Batman.View({
          node: document
        }));
      }
      this.startRouting();
      return this.hasRun = true;
    });
    return App;
  })();
  namedParam = /:([\w\d]+)/g;
  splatParam = /\*([\w\d]+)/g;
  queryParam = '(?:\\?.+)?';
  namedOrSplat = /[:|\*]([\w\d]+)/g;
  escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g;
  Batman.Route = {
    isRoute: true,
    pattern: null,
    regexp: null,
    namedArguments: null,
    action: null,
    context: null,
    fire: function(args, context) {
      var action, controller, controllerName, index;
      action = this.action;
      if ($typeOf(action) === 'String') {
        if ((index = action.indexOf('#')) !== -1) {
          controllerName = helpers.camelize(action.substr(0, index) + 'Controller');
          controller = Batman.currentApp[controllerName];
          context = controller;
          if (context != null ? context.sharedInstance : void 0) {
            context = context.sharedInstance();
          }
          action = context[action.substr(index + 1)];
        }
      }
      if (action) {
        return action.apply(context || this.context, args);
      }
    },
    toString: function() {
      return "route: " + this.pattern;
    }
  };
  $mixin(Batman, {
    HASH_PATTERN: '#!',
    _routes: [],
    route: $block(function(pattern, callback) {
      var array, f, match, namedArguments, regexp;
      f = function(params) {
        var context, key, value;
        context = f.context || this;
        if (context && context.sharedInstance) {
          context = context.sharedInstance();
        }
        pattern = f.pattern;
        if (params && !params.url) {
          for (key in params) {
            value = params[key];
            pattern = pattern.replace(new RegExp('[:|\*]' + key), value);
          }
        }
        if ((params && !params.url) || !params) {
          Batman.currentApp._cachedRoute = pattern;
          window.location.hash = Batman.HASH_PATTERN + pattern;
        }
        if (context && context.dispatch) {
          return context.dispatch(f, params);
        } else {
          return f.fire(arguments, context);
        }
      };
      match = pattern.replace(escapeRegExp, '\\$&');
      regexp = new RegExp('^' + match.replace(namedParam, '([^\/]*)').replace(splatParam, '(.*?)') + queryParam + '$');
      namedArguments = [];
      while ((array = namedOrSplat.exec(match)) != null) {
        if (array[1]) {
          namedArguments.push(array[1]);
        }
      }
      $mixin(f, Batman.Route, {
        pattern: match,
        regexp: regexp,
        namedArguments: namedArguments,
        action: callback,
        context: this
      });
      Batman._routes.push(f);
      return f;
    }),
    redirect: function(urlOrFunction) {
      var url;
      url = (urlOrFunction != null ? urlOrFunction.isRoute : void 0) ? urlOrFunction.pattern : urlOrFunction;
      return window.location.hash = "" + Batman.HASH_PATTERN + url;
    }
  });
  Batman.Object.route = Batman.App.route = $route = Batman.route;
  Batman.Object.redirect = Batman.App.redirect = $redirect = Batman.redirect;
  $mixin(Batman.App, {
    startRouting: function() {
      var old, parseUrl;
      if (typeof window === 'undefined') {
        return;
      }
      parseUrl = __bind(function() {
        var hash;
        hash = window.location.hash.replace(Batman.HASH_PATTERN, '');
        if (hash === this._cachedRoute) {
          return;
        }
        this._cachedRoute = hash;
        return this._dispatch(hash);
      }, this);
      if (!window.location.hash) {
        window.location.hash = "" + Batman.HASH_PATTERN + "/";
      }
      setTimeout(parseUrl, 0);
      if ('onhashchange' in window) {
        this._routeHandler = parseUrl;
        return window.addEventListener('hashchange', parseUrl);
      } else {
        old = window.location.hash;
        return this._routeHandler = setInterval(parseUrl, 100);
      }
    },
    stopRouting: function() {
      if (this._routeHandler == null) {
        return;
      }
      if ('onhashchange' in window) {
        window.removeEventListener('hashchange', this._routeHandler);
        return this._routeHandler = null;
      } else {
        return this._routeHandler = clearInterval(this._routeHandler);
      }
    },
    _dispatch: function(url) {
      var params, route;
      route = this._matchRoute(url);
      if (!route) {
        if (url === '/404') {
          Batman.currentApp['404']();
        } else {
          $redirect('/404');
        }
        return;
      }
      params = this._extractParams(url, route);
      return route(params);
    },
    _matchRoute: function(url) {
      var route, _i, _len, _ref;
      _ref = Batman._routes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        route = _ref[_i];
        if (route.regexp.test(url)) {
          return route;
        }
      }
      return null;
    },
    _extractParams: function(url, route) {
      var array, index, k, param, params, query, s, v, _i, _len, _len2, _ref, _ref2, _ref3;
      _ref = url.split('?'), url = _ref[0], query = _ref[1];
      array = route.regexp.exec(url).slice(1);
      params = {
        url: url
      };
      for (index = 0, _len = array.length; index < _len; index++) {
        param = array[index];
        params[route.namedArguments[index]] = param;
      }
      if (query != null) {
        _ref2 = query.split('&');
        for (_i = 0, _len2 = _ref2.length; _i < _len2; _i++) {
          s = _ref2[_i];
          _ref3 = s.split('='), k = _ref3[0], v = _ref3[1];
          params[k] = v;
        }
      }
      return params;
    },
    root: function(callback) {
      return $route('/', callback);
    },
    '404': function() {
      var view;
      return view = new Batman.View({
        html: '<h1>Page could not be found</h1>',
        contentFor: 'main'
      });
    }
  });
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
    Controller.beforeFilter = function(nameOrFunction) {
      var filters;
      filters = this._beforeFilters || (this._beforeFilters = []);
      return filters.push(nameOrFunction);
    };
    Controller.resources = function(base) {
      var f;
      f = __bind(function() {
        if (this.prototype.index) {
          this.prototype.index = this.route("/" + base, this.prototype.index);
        }
        if (this.prototype.create) {
          this.prototype.create = this.route("/" + base + "/new", this.prototype.create);
        }
        if (this.prototype.show) {
          this.prototype.show = this.route("/" + base + "/:id", this.prototype.show);
        }
        if (this.prototype.edit) {
          return this.prototype.edit = this.route("/" + base + "/:id/edit", this.prototype.edit);
        }
      }, this);
      return setTimeout(f, 0);
    };
    Controller.prototype.dispatch = function() {
      var filter, filters, key, params, result, route, _i, _len;
      route = arguments[0], params = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      key = $findName(route, this);
      this._actedDuringAction = false;
      this._currentAction = key;
      filters = this.constructor._beforeFilters;
      if (filters) {
        for (_i = 0, _len = filters.length; _i < _len; _i++) {
          filter = filters[_i];
          filter.call(this);
        }
      }
      result = route.fire(params, this);
      if (!this._actedDuringAction) {
        this.render();
      }
      delete this._actedDuringAction;
      return delete this._currentAction;
    };
    Controller.prototype.redirect = function(url) {
      this._actedDuringAction = true;
      return $redirect(url);
    };
    Controller.prototype.render = function(options) {
      var view;
      if (options == null) {
        options = {};
      }
      this._actedDuringAction = true;
      if (!options.view) {
        options.source = helpers.underscore(this.constructor.name.replace('Controller', '')) + '/' + this._currentAction + '.html';
        options.view = new Batman.View(options);
      }
      if (view = options.view) {
        view.context || (view.context = this);
        return view.ready(function() {
          return Batman.DOM.contentFor('main', view.get('node'));
        });
      }
    };
    return Controller;
  })();
  Batman.Model = (function() {
    var k, _i, _len, _ref;
    __extends(Model, Batman.Object);
    Model.persist = function() {
      var m, mechanisms, storage, _base, _i, _len;
      mechanisms = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      Batman._initializeObject(this.prototype);
      storage = (_base = this.prototype._batman).storage || (_base.storage = []);
      for (_i = 0, _len = mechanisms.length; _i < _len; _i++) {
        m = mechanisms[_i];
        storage.push(new m(this));
      }
      return this;
    };
    Model.accessor('all', {
      get: function() {
        return this.all || (this.all = new Batman.Set);
      }
    });
    Model.accessor('first', {
      get: function() {
        return this.first = this.get('all')[0];
      }
    });
    Model.accessor('last', {
      get: function() {
        return this.last = this.get('all')[this.all.length - 1];
      }
    });
    Model.prototype.mixin(Batman.StateMachine);
    _ref = ['empty', 'dirty', 'loading', 'loaded', 'saving'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      k = _ref[_i];
      Model.prototype.state(k);
    }
    Model.prototype.state('saved', function() {
      return this.dirtyKeys.clear();
    });
    function Model(id) {
      this.dirtyKeys = new Batman.Hash;
      this.errors = new Batman.Set;
      Model.__super__.constructor.apply(this, arguments);
      if (!this.state()) {
        this.empty();
      }
      if ($typeOf(id) === 'String') {
        this.id = id;
        this.constructor.get('all').add(this);
      }
    }
    Model.find = function(id) {
      var record;
      if ((record = this.get('all').get(id))) {
        return record;
      }
      record = new this('' + id);
      setTimeout((function() {
        return record.load();
      }), 0);
      return record;
    };
    Model.prototype.set = function(key, value) {
      var oldValue;
      oldValue = this[key];
      if (oldValue === value) {
        return;
      }
      Model.__super__.set.apply(this, arguments);
      this.dirtyKeys.set(key, oldValue);
      if (this.state() !== 'dirty') {
        return this.dirty();
      }
    };
    Model.prototype.accessor('dirtyKeys', {
      get: function() {
        return this.dirtyKeys;
      }
    });
    Model.prototype.toJSON = function() {
      var encoder, encoders, key, obj, _j, _len2, _ref2;
      obj = {};
      _ref2 = Batman._lookupAllBatmanKeys(this, 'encoders');
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        encoders = _ref2[_j];
        for (key in encoders) {
          encoder = encoders[key];
          obj[key] = encoder(this[key]);
        }
      }
      return obj;
    };
    Model.prototype.fromJSON = function(data) {
      var allDecoders, decoder, decoders, key, obj, value, _j, _len2;
      obj = {};
      allDecoders = Batman._lookupAllBatmanKeys(this, 'decoders');
      if (!allDecoders.length) {
        for (key in data) {
          value = data[key];
          obj[helpers.camelize(key, true)] = value;
        }
      } else {
        for (_j = 0, _len2 = allDecoders.length; _j < _len2; _j++) {
          decoders = allDecoders[_j];
          for (key in decoders) {
            decoder = decoders[key];
            obj[key] = decoder(data[key]);
          }
        }
      }
      return this.mixin(obj);
    };
    Model.encode = function() {
      var key, keys, _base, _base2, _j, _len2, _results;
      keys = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      Batman._initializeObject(this.prototype);
      (_base = this.prototype._batman).encoders || (_base.encoders = {});
      (_base2 = this.prototype._batman).decoders || (_base2.decoders = {});
      _results = [];
      for (_j = 0, _len2 = keys.length; _j < _len2; _j++) {
        key = keys[_j];
        this.prototype._batman.encoders[key] = function(value) {
          return '' + value;
        };
        _results.push(this.prototype._batman.decoders[key] = function(value) {
          return value;
        });
      }
      return _results;
    };
    Model.beforeLoad = Model.event(function() {
      return this.get('all').clear();
    });
    Model.afterLoad = Model.event(function() {});
    Model.load = function(callback) {
      var afterLoad, allMechanisms, fireImmediately, m, mechanisms, _j, _k, _len2, _len3;
      this.beforeLoad();
      afterLoad = __bind(function() {
        if (callback != null) {
          callback.call(this);
        }
        return this.afterLoad();
      }, this);
      allMechanisms = Batman._lookupAllBatmanKeys(this.prototype, 'storage');
      fireImmediately = !allMechanisms.length;
      if (!fireImmediately) {
        allMechanisms.shift();
      }
      for (_j = 0, _len2 = allMechanisms.length; _j < _len2; _j++) {
        mechanisms = allMechanisms[_j];
        fireImmediately = fireImmediately || !mechanisms.length;
        for (_k = 0, _len3 = mechanisms.length; _k < _len3; _k++) {
          m = mechanisms[_k];
          m.readAllFromStorage(this, afterLoad);
        }
      }
      if (fireImmediately) {
        return afterLoad();
      }
    };
    Model.prototype.beforeLoad = Model.event(function() {
      this.loading();
      return true;
    });
    Model.prototype.afterLoad = Model.event(function() {
      this.loaded();
      return true;
    });
    Model.prototype.load = function(callback) {
      var afterLoad, allMechanisms, fireImmediately, m, mechanisms, _j, _k, _len2, _len3;
      this.beforeLoad();
      afterLoad = __bind(function() {
        if (callback != null) {
          callback.call(this);
        }
        return this.afterLoad();
      }, this);
      allMechanisms = Batman._lookupAllBatmanKeys(this, 'storage');
      fireImmediately = !allMechanisms.length;
      for (_j = 0, _len2 = allMechanisms.length; _j < _len2; _j++) {
        mechanisms = allMechanisms[_j];
        fireImmediately = fireImmediately || !mechanisms.length;
        for (_k = 0, _len3 = mechanisms.length; _k < _len3; _k++) {
          m = mechanisms[_k];
          m.readFromStorage(this, afterLoad);
        }
      }
      if (fireImmediately) {
        return afterLoad();
      }
    };
    Model.prototype.beforeCreate = Model.event(function() {});
    Model.prototype.afterCreate = Model.event(function() {});
    Model.prototype.beforeSave = Model.event(function() {
      this.saving();
      return true;
    });
    Model.prototype.afterSave = Model.event(function() {
      this.saved();
      return true;
    });
    Model.prototype.save = function(callback) {
      var afterSave, allMechanisms, creating, fireImmediately, m, mechanisms, _j, _k, _len2, _len3;
      if (!this.isValid()) {
        return;
      }
      this.beforeSave();
      creating = !this.id;
      if (creating) {
        this.beforeCreate();
      }
      afterSave = __bind(function() {
        if (callback != null) {
          callback.call(this);
        }
        if (creating) {
          this.afterCreate();
        }
        return this.afterSave();
      }, this);
      allMechanisms = Batman._lookupAllBatmanKeys(this, 'storage');
      fireImmediately = !allMechanisms.length;
      for (_j = 0, _len2 = allMechanisms.length; _j < _len2; _j++) {
        mechanisms = allMechanisms[_j];
        fireImmediately = fireImmediately || !mechanisms.length;
        for (_k = 0, _len3 = mechanisms.length; _k < _len3; _k++) {
          m = mechanisms[_k];
          m.writeToStorage(this, afterSave);
        }
      }
      if (fireImmediately) {
        return afterSave();
      }
    };
    Model.prototype.beforeValidation = Model.event(function() {});
    Model.prototype.afterValidation = Model.event(function() {});
    Model.prototype.validate = function() {
      var allValidators, async, key, promise, v, validator, _j, _k, _l, _len2, _len3, _len4, _ref2, _ref3;
      this.beforeValidation();
      async = false;
      _ref2 = Batman._lookupAllBatmanKeys(this, 'validators');
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        allValidators = _ref2[_j];
        for (_k = 0, _len3 = allValidators.length; _k < _len3; _k++) {
          validator = allValidators[_k];
          v = validator.validator;
          _ref3 = validator.keys;
          for (_l = 0, _len4 = _ref3.length; _l < _len4; _l++) {
            key = _ref3[_l];
            promise = new Batman.ValidatorPromise(this);
            if (v) {
              v.validateEach(promise, this, key, this.get(key));
            } else {
              validator.callback(promise, this, key, this.get(key));
            }
            if (promise.paused) {
              this.prevent('afterValidation');
              promise.resume(__bind(function() {
                this.allow('afterValidation');
                return this.afterValidation();
              }, this));
              async = true;
            } else {
              if (promise.canSucceed) {
                promise.success();
              }
            }
          }
        }
      }
      if (async) {
        return false;
      } else {
        return this.afterValidation();
      }
    };
    Model.prototype.accessor({
      isValid: function() {
        this.errors.clear();
        if (this.validate() === false) {
          return false;
        }
        return this.errors.isEmpty();
      }
    });
    Model.validate = function() {
      var keys, match, matches, myValidators, options, validator, _base, _j, _k, _len2, _results;
      keys = 2 <= arguments.length ? __slice.call(arguments, 0, _j = arguments.length - 1) : (_j = 0, []), options = arguments[_j++];
      Batman._initializeObject(this.prototype);
      myValidators = (_base = this.prototype._batman).validators || (_base.validators = []);
      if (typeof options === 'function') {
        return myValidators.push({
          keys: keys,
          callback: options
        });
      } else {
        _results = [];
        for (_k = 0, _len2 = validators.length; _k < _len2; _k++) {
          validator = validators[_k];
          _results.push((function() {
            if ((matches = validator.matches(options))) {
              for (match in matches) {
                delete options[match];
              }
              return myValidators.push({
                keys: keys,
                validator: new validator(matches)
              });
            }
          })());
        }
        return _results;
      }
    };
    return Model;
  })();
  Batman.ValidatorPromise = (function() {
    __extends(ValidatorPromise, Batman.Object);
    function ValidatorPromise(record) {
      this.record = record;
      this.canSucceed = true;
    }
    ValidatorPromise.prototype.error = function(err) {
      this.record.errors.add(err);
      return this.canSucceed = false;
    };
    ValidatorPromise.prototype.wait = function() {
      this.paused = true;
      return this.canSucceed = false;
    };
    ValidatorPromise.prototype.resume = ValidatorPromise.event(function() {
      this.paused = false;
      return true;
    });
    ValidatorPromise.prototype.success = function() {
      return this.canSucceed = false;
    };
    return ValidatorPromise;
  })();
  Batman.Validator = (function() {
    __extends(Validator, Batman.Object);
    function Validator() {
      var mixins, options;
      options = arguments[0], mixins = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      this.options = options;
      Validator.__super__.constructor.apply(this, mixins);
    }
    Validator.prototype.validate = function(record) {
      throw "You must override -validate in Batman.Validator subclasses.";
    };
    Validator.kind = function() {
      return helpers.underscore(this.name).replace('_validator', '');
    };
    Validator.prototype.kind = function() {
      return this.constructor.kind();
    };
    Validator.options = function() {
      var options;
      options = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      Batman._initializeObject(this);
      if (this._batman.options) {
        return this._batman.options.concat(options);
      } else {
        return this._batman.options = options;
      }
    };
    Validator.matches = function(options) {
      var key, results, shouldReturn, value, _ref, _ref2;
      results = {};
      shouldReturn = false;
      for (key in options) {
        value = options[key];
        if (~((_ref = this._batman) != null ? (_ref2 = _ref.options) != null ? _ref2.indexOf(key) : void 0 : void 0)) {
          results[key] = value;
          shouldReturn = true;
        }
      }
      if (shouldReturn) {
        return results;
      }
    };
    return Validator;
  })();
  validators = Batman.validators = [
    Batman.LengthValidator = (function() {
      __extends(LengthValidator, Batman.Validator);
      LengthValidator.options('minLength', 'maxLength', 'length', 'lengthWithin', 'lengthIn');
      function LengthValidator(options) {
        var range;
        if (range = options.lengthIn || options.lengthWithin) {
          options.minLength = range[0];
          options.maxLength = range[1] || -1;
          delete options.lengthWithin;
          delete options.lengthIn;
        }
        LengthValidator.__super__.constructor.apply(this, arguments);
      }
      LengthValidator.prototype.validateEach = function(validator, record, key, value) {
        var options;
        options = this.options;
        if (options.minLength && value.length < options.minLength) {
          validator.error("" + key + " must be at least " + options.minLength + " characters");
        }
        if (options.maxLength && value.length > options.maxLength) {
          validator.error("" + key + " must be less than " + options.maxLength + " characters");
        }
        if (options.length && value.length !== options.length) {
          return validator.error("" + key + " must be " + options.length + " characters");
        }
      };
      return LengthValidator;
    })(), Batman.PresenceValidator = (function() {
      __extends(PresenceValidator, Batman.Validator);
      function PresenceValidator() {
        PresenceValidator.__super__.constructor.apply(this, arguments);
      }
      PresenceValidator.options('presence');
      PresenceValidator.prototype.validateEach = function(validator, record, key, value) {
        var options;
        options = this.options;
        if (options.presence && !(value != null)) {
          return validator.error("" + key + " must be present");
        }
      };
      return PresenceValidator;
    })()
  ];
  Batman.StorageMechanism = (function() {
    function StorageMechanism(model) {
      this.model = model;
      this.modelKey = helpers.pluralize(helpers.underscore(this.model.name));
    }
    return StorageMechanism;
  })();
  Batman.LocalStorage = (function() {
    __extends(LocalStorage, Batman.StorageMechanism);
    function LocalStorage() {
      var _ref;
      if (_ref = !'localStorage', __indexOf.call(window, _ref) >= 0) {
        return null;
      }
      this.id = 0;
      LocalStorage.__super__.constructor.apply(this, arguments);
    }
    LocalStorage.prototype.writeToStorage = function(record, callback) {
      var id, key;
      key = this.modelKey;
      id = record.id || (record.id = ++this.id);
      if (key && id) {
        localStorage[key + id] = JSON.stringify(record);
      }
      return callback();
    };
    LocalStorage.prototype.readFromStorage = function(record, callback) {
      var id, json, key;
      key = this.modelKey;
      id = record.id;
      if (key && id) {
        json = localStorage[key + id];
      }
      record.fromJSON(JSON.parse(json));
      return callback();
    };
    return LocalStorage;
  })();
  Batman.RestStorage = (function() {
    __extends(RestStorage, Batman.StorageMechanism);
    function RestStorage() {
      RestStorage.__super__.constructor.apply(this, arguments);
    }
    RestStorage.prototype.writeToStorage = function(record, callback) {
      var id, key;
      key = this.modelKey;
      id = record.id;
      return new Batman.Request({
        url: "/" + key + "/" + id,
        method: id ? 'put' : 'post',
        data: JSON.stringify(record),
        success: function() {
          return callback();
        },
        error: function(error) {
          return callback(error);
        }
      });
    };
    RestStorage.prototype.readFromStorage = function(record, callback) {
      var id;
      id = record.id;
      if (!id) {
        return;
      }
      return new Batman.Request({
        url: (this.model.url || ("/" + this.modelKey)) + ("/" + id),
        type: 'json',
        success: function(data) {
          var key;
          if (typeof data === 'string') {
            data = JSON.parse(data);
          }
          for (key in data) {
            data = data[key];
            break;
          }
          record.fromJSON(data);
          return callback();
        }
      });
    };
    RestStorage.prototype.readAllFromStorage = function(model, callback) {
      var key, r;
      key = this.modelKey;
      return r = new Batman.Request({
        url: model.url || ("/" + key),
        type: 'json',
        success: function(data) {
          var key, obj, record, _i, _len;
          if (typeof data === 'string') {
            data = JSON.parse(data);
          }
          if (!Array.isArray(data)) {
            for (key in data) {
              data = data[key];
              break;
            }
          }
          for (_i = 0, _len = data.length; _i < _len; _i++) {
            obj = data[_i];
            record = new model('' + obj.id);
            record.fromJSON(obj);
          }
          callback();
        }
      });
    };
    return RestStorage;
  })();
  Batman.View = (function() {
    var viewSources;
    __extends(View, Batman.Object);
    function View() {
      View.__super__.constructor.apply(this, arguments);
    }
    viewSources = {};
    View.prototype.source = '';
    View.prototype.html = '';
    View.prototype.node = null;
    View.prototype.context = null;
    View.prototype.contexts = null;
    View.prototype.contentFor = null;
    View.prototype.ready = View.eventOneShot(function() {});
    View.prototype.prefix = 'views';
    View.prototype.observe('source', function() {
      return setTimeout((__bind(function() {
        return this.reloadSource();
      }, this)), 0);
    });
    View.prototype.reloadSource = function() {
      var source;
      source = this.get('source');
      if (!source) {
        return;
      }
      if (viewSources[source]) {
        return this.set('html', viewSources[source]);
      } else {
        return new Batman.Request({
          url: "views/" + this.source,
          type: 'html',
          success: __bind(function(response) {
            viewSources[source] = response;
            return this.set('html', response);
          }, this),
          error: function(response) {
            throw "Could not load view from " + url;
          }
        });
      }
    };
    View.prototype.observe('html', function(html) {
      var node;
      node = this.node || document.createElement('div');
      node.innerHTML = html;
      if (this.node !== node) {
        return this.set('node', node);
      }
    });
    View.prototype.observe('node', function(node) {
      if (!node) {
        return;
      }
      this.ready.fired = false;
      if (this._renderer) {
        this._renderer.forgetAll();
      }
      if (node) {
        this._renderer = new Batman.Renderer(node, __bind(function() {
          var content, _ref;
          content = this.contentFor;
          if (typeof content === 'string') {
            this.contentFor = (_ref = Batman.DOM._yields) != null ? _ref[content] : void 0;
          }
          if (this.contentFor && node) {
            this.contentFor.innerHTML = '';
            this.contentFor.appendChild(node);
          }
          return this.ready(node);
        }, this), this.contexts);
        if (this.context) {
          this._renderer.contexts.push(this.context);
        }
        return this._renderer.contextObject.view = this;
      }
    });
    return View;
  })();
  Batman.Renderer = (function() {
    var regexp;
    __extends(Renderer, Batman.Object);
    function Renderer(node, callback, contexts) {
      this.node = node;
      this.callback = callback;
      this.resume = __bind(this.resume, this);
      this.start = __bind(this.start, this);
      Renderer.__super__.constructor.apply(this, arguments);
      this.contexts = contexts || [Batman.currentApp, new Batman.Object];
      this.contextObject = this.contexts[1];
      setTimeout(this.start, 0);
    }
    Renderer.prototype.start = function() {
      this.startTime = new Date;
      return this.parseNode(this.node);
    };
    Renderer.prototype.resume = function() {
      this.startTime = new Date;
      return this.parseNode(this.resumeNode);
    };
    Renderer.prototype.finish = function() {
      this.startTime = null;
      return typeof this.callback === "function" ? this.callback() : void 0;
    };
    Renderer.prototype.forgetAll = function() {};
    regexp = /data\-(.*)/;
    Renderer.prototype.parseNode = function(node) {
      var attr, contexts, index, name, nextNode, result, skipChildren, _base, _base2, _i, _len, _name, _ref, _ref2;
      if (new Date - this.startTime > 50) {
        this.resumeNode = node;
        setTimeout(this.resume, 0);
        return;
      }
      if (node.getAttribute) {
        this.contextObject.node = node;
        contexts = this.contexts;
        _ref = node.attributes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          attr = _ref[_i];
          name = (_ref2 = attr.nodeName.match(regexp)) != null ? _ref2[1] : void 0;
          if (!name) {
            continue;
          }
          result = (index = name.indexOf('-')) === -1 ? typeof (_base = Batman.DOM.readers)[name] === "function" ? _base[name](node, attr.value, contexts, this) : void 0 : typeof (_base2 = Batman.DOM.attrReaders)[_name = name.substr(0, index)] === "function" ? _base2[_name](node, name.substr(index + 1), attr.value, contexts, this) : void 0;
          if (result === false) {
            skipChildren = true;
            break;
          }
        }
      }
      if ((nextNode = this.nextNode(node, skipChildren))) {
        return this.parseNode(nextNode);
      } else {
        return this.finish();
      }
    };
    Renderer.prototype.nextNode = function(node, skipChildren) {
      var children, nextParent, parentSibling, sibling;
      if (!skipChildren) {
        children = node.childNodes;
        if (children != null ? children.length : void 0) {
          return children[0];
        }
      }
      if (typeof node.onParseExit === "function") {
        node.onParseExit();
      }
      sibling = node.nextSibling;
      if (sibling) {
        return sibling;
      }
      nextParent = node;
      while (nextParent = nextParent.parentNode) {
        if (typeof nextParent.onParseExit === "function") {
          nextParent.onParseExit();
        }
        parentSibling = nextParent.nextSibling;
        if (parentSibling) {
          return parentSibling;
        }
      }
    };
    return Renderer;
  })();
  matchContext = function(contexts, key) {
    var base, context, i;
    base = key.split('.')[0];
    i = contexts.length;
    while (i--) {
      context = contexts[i];
      if (((context.get != null) && (context.get(base) != null)) || (context[base] != null)) {
        return context;
      }
    }
    return container;
  };
  Batman.DOM = {
    readers: {
      bind: function(node, key, contexts) {
        var context, shouldSet;
        context = matchContext(contexts, key);
        shouldSet = true;
        if (Batman.DOM.nodeIsEditable(node)) {
          Batman.DOM.events.change(node, function() {
            shouldSet = false;
            context.set(key, node.value);
            return shouldSet = true;
          });
        }
        return context.observe(key, true, function(value) {
          if (shouldSet) {
            return Batman.DOM.valueForNode(node, value);
          }
        });
      },
      context: function(node, key, contexts) {
        var context;
        context = matchContext(contexts, key).get(key);
        contexts.push(context);
        return node.onParseExit = function() {
          var index;
          index = contexts.indexOf(context);
          return contexts.splice(index, contexts.length - index);
        };
      },
      mixin: function(node, key, contexts) {
        var context, mixin;
        contexts.push(Batman.mixins);
        context = matchContext(contexts, key);
        mixin = context.get(key);
        contexts.pop();
        return $mixin(node, mixin);
      },
      showif: function(node, key, contexts, renderer, invert) {
        var context, originalDisplay;
        originalDisplay = node.style.display;
        if (!originalDisplay || originalDisplay === 'none') {
          originalDisplay = 'block';
        }
        context = matchContext(contexts, key);
        return context.observe(key, true, function(value) {
          if (!!value === !invert) {
            if (typeof node.show === 'function') {
              return node.show();
            } else {
              return node.style.display = originalDisplay;
            }
          } else {
            if (typeof node.hide === 'function') {
              return node.hide();
            } else {
              return node.style.display = 'none';
            }
          }
        });
      },
      hideif: function() {
        var args, _ref;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return (_ref = Batman.DOM.readers).showif.apply(_ref, __slice.call(args).concat([true]));
      },
      route: function(node, key, contexts) {
        var context, controller, controllerName, id, index, route, routeName, _ref;
        if (key.substr(0, 1) === '/') {
          route = Batman.redirect.bind(Batman, key);
          routeName = key;
        } else if ((index = key.indexOf('#')) !== -1) {
          controllerName = helpers.camelize(key.substr(0, index)) + 'Controller';
          context = matchContext(contexts, controllerName);
          controller = context[controllerName];
          route = controller != null ? controller.sharedInstance()[key.substr(index + 1)] : void 0;
          routeName = route != null ? route.pattern : void 0;
        } else {
          context = matchContext(contexts, key);
          route = context.get(key);
          if (route instanceof Batman.Model) {
            controllerName = helpers.camelize(helpers.pluralize(key)) + 'Controller';
            context = matchContext(contexts, controllerName);
            controller = context[controllerName].sharedInstance();
            id = route.id;
            route = (_ref = controller.show) != null ? _ref.bind(controller, {
              id: id
            }) : void 0;
            routeName = '/' + helpers.pluralize(key) + '/' + id;
          } else {
            routeName = route != null ? route.pattern : void 0;
          }
        }
        if (node.nodeName.toUpperCase() === 'A') {
          node.href = Batman.HASH_PATTERN + (routeName || '');
        }
        return Batman.DOM.events.click(node, (function() {
          return route();
        }));
      },
      partial: function(node, path, contexts) {
        var view;
        return view = new Batman.View({
          source: path + '.html',
          contentFor: node,
          contexts: Array.prototype.slice.call(contexts)
        });
      },
      yield: function(node, key) {
        return setTimeout((function() {
          return Batman.DOM.yield(key, node);
        }), 0);
      },
      contentfor: function(node, key) {
        return setTimeout((function() {
          return Batman.DOM.contentFor(key, node);
        }), 0);
      }
    },
    attrReaders: {
      bind: function(node, attr, key, contexts) {
        var args, context, filter, filterName, filters, value, _results;
        filters = key.split(/\s*\|\s*/);
        key = filters.shift();
        if (filters.length) {
          _results = [];
          while (filterName = filters.shift()) {
            args = filterName.split(' ');
            filterName = args.shift();
            filter = Batman.filters[filterName] || Batman.helpers[filterName];
            if (!filter) {
              continue;
            }
            if (key.substr(0, 1) === '@') {
              key = key.substr(1);
              context = matchContext(contexts, key);
              key = context.get(key);
            }
            value = filter.apply(null, [key].concat(__slice.call(args), [node]));
            _results.push(node.setAttribute(attr, value));
          }
          return _results;
        } else {
          context = matchContext(contexts, key);
          context.observe(key, true, function(value) {
            if (attr === 'value') {
              return node.value = value;
            } else {
              return node.setAttribute(attr, value);
            }
          });
          if (attr === 'value') {
            return Batman.DOM.events.change(node, function() {
              value = node.value;
              if (value === 'false') {
                value = false;
              }
              if (value === 'true') {
                value = true;
              }
              return context.set(key, value);
            });
          }
        }
      },
      context: function(node, contextName, key, contexts) {
        var context, object;
        context = matchContext(contexts, key).get(key);
        object = new Batman.Object;
        object[contextName] = context;
        contexts.push(object);
        return node.onParseExit = function() {
          var index;
          index = contexts.indexOf(context);
          return contexts.splice(index, contexts.length - index);
        };
      },
      event: function(node, eventName, key, contexts) {
        var callback, context;
        if (key.substr(0, 1) === '@') {
          callback = new Function(key.substr(1));
        } else {
          context = matchContext(contexts, key);
          callback = context.get(key);
        }
        return Batman.DOM.events[eventName](node, function() {
          var confirmText;
          confirmText = node.getAttribute('data-confirm');
          if (confirmText && !confirm(confirmText)) {
            return;
          }
          return callback != null ? callback.apply(context, arguments) : void 0;
        });
      },
      addclass: function(node, className, key, contexts, parentRenderer, invert) {
        var context;
        className = className.replace(/\|/g, ' ');
        context = matchContext(contexts, key);
        return context.observe(key, true, function(value) {
          var currentName, includesClassName;
          currentName = node.className;
          includesClassName = currentName.indexOf(className) !== -1;
          if (!!value === !invert) {
            if (!includesClassName) {
              return node.className = "" + currentName + " " + className;
            }
          } else {
            if (includesClassName) {
              return node.className = currentName.replace(className, '');
            }
          }
        });
      },
      removeclass: function() {
        var args, _ref;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return (_ref = Batman.DOM.attrReaders).addclass.apply(_ref, __slice.call(args).concat([true]));
      },
      foreach: function(node, iteratorName, key, contexts, parentRenderer) {
        var add, collection, context, contextsClone, nodeMap, parent, prototype, remove;
        prototype = node.cloneNode(true);
        prototype.removeAttribute("data-foreach-" + iteratorName);
        parent = node.parentNode;
        parent.removeChild(node);
        nodeMap = new Batman.Hash;
        contextsClone = Array.prototype.slice.call(contexts);
        context = matchContext(contexts, key);
        collection = context.get(key);
        if (collection != null ? collection.observe : void 0) {
          collection.observe('add', add = function(item) {
            var iteratorContext, localClone, newNode, renderer;
            newNode = prototype.cloneNode(true);
            nodeMap.set(item, newNode);
            renderer = new Batman.Renderer(newNode, function() {
              parent.appendChild(newNode);
              return parentRenderer.allow('ready');
            });
            renderer.contexts = localClone = Array.prototype.slice.call(contextsClone);
            renderer.contextObject = Batman(localClone[1]);
            iteratorContext = new Batman.Object;
            iteratorContext[iteratorName] = item;
            localClone.push(iteratorContext);
            return localClone.push(item);
          });
          collection.observe('remove', remove = function(item) {
            var oldNode, _ref;
            oldNode = nodeMap.get(item);
            return oldNode != null ? (_ref = oldNode.parentNode) != null ? _ref.removeChild(oldNode) : void 0 : void 0;
          });
          collection.observe('sort', function() {
            collection.each(remove);
            return setTimeout((function() {
              return collection.each(add);
            }), 0);
          });
          collection.each(function(item) {
            parentRenderer.prevent('ready');
            return add(item);
          });
        }
        return false;
      }
    },
    events: {
      click: function(node, callback) {
        Batman.DOM.addEventListener(node, 'click', function(e) {
          if (callback != null) {
            callback.apply(this, arguments);
          }
          return e.preventDefault();
        });
        if (node.nodeName.toUpperCase() === 'A' && !node.href) {
          return node.href = '#';
        }
      },
      change: function(node, callback) {
        var eventName;
        eventName = (function() {
          switch (node.nodeName.toUpperCase()) {
            case 'TEXTAREA':
              return 'keyup';
            case 'INPUT':
              if (node.type.toUpperCase() === 'TEXT') {
                return 'keyup';
              } else {
                return 'change';
              }
              break;
            default:
              return 'change';
          }
        })();
        return Batman.DOM.addEventListener(node, eventName, callback);
      },
      submit: function(node, callback) {
        if (Batman.DOM.nodeIsEditable(node)) {
          return Batman.DOM.addEventListener(node, 'keyup', function(e) {
            if (e.keyCode === 13) {
              callback.apply(this, arguments);
              return e.preventDefault();
            }
          });
        } else {
          return Batman.DOM.addEventListener(node, 'submit', function(e) {
            callback.apply(this, arguments);
            return e.preventDefault();
          });
        }
      }
    },
    yield: function(name, node) {
      var content, yields, _base, _ref;
      yields = (_base = Batman.DOM)._yields || (_base._yields = {});
      yields[name] = node;
      if ((content = (_ref = Batman.DOM._yieldContents) != null ? _ref[name] : void 0)) {
        node.innerHTML = '';
        if (content) {
          return node.appendChild(content);
        }
      }
    },
    contentFor: function(name, node) {
      var contents, yield, _base, _ref;
      contents = (_base = Batman.DOM)._yieldContents || (_base._yieldContents = {});
      contents[name] = node;
      if ((yield = (_ref = Batman.DOM._yields) != null ? _ref[name] : void 0)) {
        yield.innerHTML = '';
        if (node) {
          return yield.appendChild(node);
        }
      }
    },
    valueForNode: function(node, value) {
      var isSetting;
      isSetting = arguments.length > 1;
      switch (node.nodeName.toUpperCase()) {
        case 'INPUT':
          if (isSetting) {
            return node.value = value;
          } else {
            return node.value;
          }
          break;
        default:
          if (isSetting) {
            return node.innerHTML = value;
          } else {
            return node.innerHTML;
          }
      }
    },
    nodeIsEditable: function(node) {
      var _ref;
      return (_ref = node.nodeName.toUpperCase()) === 'INPUT' || _ref === 'TEXTAREA';
    },
    addEventListener: function(node, eventName, callback) {
      if (node.addEventListener) {
        return node.addEventListener(eventName, callback, false);
      } else {
        return node.attachEvent("on" + eventName, callback);
      }
    }
  };
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
  filters = Batman.filters = {};
  mixins = Batman.mixins = new Batman.Object;
  container = typeof exports !== "undefined" && exports !== null ? (exports.Batman = Batman, global) : (window.Batman = Batman, window);
  $mixin(container, Batman.Observable);
  Batman.exportHelpers = function(onto) {
    onto.$typeOf = $typeOf;
    onto.$mixin = $mixin;
    onto.$unmixin = $unmixin;
    onto.$route = $route;
    onto.$redirect = $redirect;
    onto.$event = $event;
    return onto.$eventOneShot = $eventOneShot;
  };
  Batman.exportGlobals = function() {
    return Batman.exportHelpers(container);
  };
}).call(this);

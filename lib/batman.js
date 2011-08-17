(function() {
  var $block, $event, $eventOneShot, $findName, $get, $mixin, $redirect, $route, $typeOf, $undef, $unmixin, Batman, Binding, RenderContext, Validators, buntUndefined, camelize_rx, capitalize_rx, container, escapeRegExp, filters, helpers, k, mixins, namedOrSplat, namedParam, queryParam, splatParam, underscore_rx1, underscore_rx2, _Batman, _class, _fn, _i, _j, _len, _len2, _objectToString, _ref, _ref2, _stateMachine_setState;
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
  Batman.undef = $undef = function(object) {
    return typeof object === 'undefined';
  };
  Batman.mixin = $mixin = function() {
    var hasSet, key, mixin, mixins, to, value, _i, _len;
    to = arguments[0], mixins = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    hasSet = typeof to.set === 'function';
    for (_i = 0, _len = mixins.length; _i < _len; _i++) {
      mixin = mixins[_i];
      if ($typeOf(mixin) !== 'Object') {
        continue;
      }
      for (key in mixin) {
        if (!__hasProp.call(mixin, key)) continue;
        value = mixin[key];
        if (key === 'initialize' || key === 'uninitialize' || key === 'prototype') {
          continue;
        }
        if (hasSet) {
          to.set(key, value);
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
        delete from[key];
      }
      if (typeof mixin.deinitialize === 'function') {
        mixin.deinitialize.call(from);
      }
    }
    return from;
  };
  Batman._block = $block = function(lengthOrFunction, fn) {
    var argsLength, callbackEater;
    if (fn != null) {
      argsLength = lengthOrFunction;
    } else {
      fn = lengthOrFunction;
    }
    return callbackEater = function() {
      var args, ctx, f;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      ctx = this;
      f = function(callback) {
        args.push(callback);
        return fn.apply(ctx, args);
      };
      if ((typeof args[args.length - 1] === 'function') || (argsLength && (args.length >= argsLength))) {
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
        var x;
        x = this[key];
        delete this[key];
        return x;
      }
    };
    Property.triggerTracker = null;
    Property["for"] = function(base, key) {
      var properties, _base;
      if (base._batman) {
        Batman.initializeObject(base);
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
      var accessors, val, _ref, _ref2;
      accessors = (_ref = this.base._batman) != null ? _ref.get('keyAccessors') : void 0;
      if (accessors && (val = accessors.get(this.key))) {
        return val;
      } else {
        return ((_ref2 = this.base._batman) != null ? _ref2.getFirst('defaultAccessor') : void 0) || Batman.Property.defaultAccessor;
      }
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
      if (this.observers.length > 0) {
        return true;
      }
      if (this.base._batman != null) {
        return this.base._batman.ancestors().some(__bind(function(ancestor) {
          var _ref, _ref2;
          return (typeof ancestor.property === "function" ? (_ref = ancestor.property(this.key)) != null ? (_ref2 = _ref.observers) != null ? _ref2.length : void 0 : void 0 : void 0) > 0;
        }, this));
      } else {
        return false;
      }
    };
    ObservableProperty.prototype.prevent = function() {
      return this._preventCount++;
    };
    ObservableProperty.prototype.allow = function() {
      if (this._preventCount > 0) {
        return this._preventCount--;
      }
    };
    ObservableProperty.prototype.isAllowedToFire = function() {
      return this._preventCount <= 0;
    };
    ObservableProperty.prototype.fire = function() {
      var args, base, key, observers;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      if (!this.hasObserversToFire()) {
        return;
      }
      key = this.key;
      base = this.base;
      observers = [this.observers].concat(this.base._batman.ancestors(function(ancestor) {
        return typeof ancestor.property === "function" ? ancestor.property(key).observers : void 0;
      })).reduce(function(a, b) {
        return a.merge(b);
      });
      observers.each(function(callback) {
        return callback != null ? callback.apply(base, args) : void 0;
      });
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
      return delete Batman.Property.triggerTracker;
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
      Batman.initializeObject(this);
      return Batman.Keypath["for"](this, key);
    },
    get: function(key) {
      if ($undef(key)) {
        return;
      }
      return this.property(key).getValue();
    },
    set: function(key, val) {
      if ($undef(key)) {
        return;
      }
      return this.property(key).setValue(val);
    },
    unset: function(key) {
      if ($undef(key)) {
        return;
      }
      return this.property(key).unsetValue();
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
    allowed: function(key) {
      return this.property(key).isAllowedToFire();
    }
  };
  _ref = ['observe', 'prevent', 'allow', 'fire'];
  _fn = function(k) {
    return Batman.Observable[k] = function() {
      var args, key, _ref2;
      key = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      (_ref2 = this.property(key))[k].apply(_ref2, args);
      return this;
    };
  };
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    k = _ref[_i];
    _fn(k);
  }
  $get = Batman.get = function(object, key) {
    if (object.get) {
      return object.get(key);
    } else {
      return Batman.Observable.get.call(object, key);
    }
  };
  Batman.EventEmitter = {
    event: $block(function(key, context, callback) {
      var f;
      if (!callback && !$undef(context)) {
        callback = context;
        context = null;
      }
      if (!callback && $typeOf(key) !== 'String') {
        callback = key;
        key = null;
      }
      f = function(observer) {
        var args, fired, firings, value, _base, _ref2, _ref3;
        if (!this.observe) {
          throw "EventEmitter requires Observable";
        }
        Batman.initializeObject(this);
        key || (key = $findName(f, this));
        fired = (_ref2 = this._batman._oneShotFired) != null ? _ref2[key] : void 0;
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
            f._firedArgs = !$undef(value) ? (_ref3 = [value]).concat.apply(_ref3, arguments) : arguments.length === 0 ? [] : Array.prototype.slice.call(arguments);
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
  Batman.event = $event = function(callback) {
    var context;
    context = new Batman.Object;
    return context.event('_event', context, callback);
  };
  Batman.eventOneShot = $eventOneShot = function(callback) {
    var context;
    context = new Batman.Object;
    return context.eventOneShot('_event', context, callback);
  };
  /*
  # Batman.StateMachine
  */
  Batman.StateMachine = {
    initialize: function() {
      Batman.initializeObject(this);
      if (!this._batman.states) {
        this._batman.states = new Batman.SimpleHash;
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
        return this._batman.getFirst('state');
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
      event = transitions.get(name) || transitions.set(name, $event(function() {}));
      if (callback) {
        event(callback);
      }
      return event;
    }
  };
  _stateMachine_setState = function(newState) {
    var event, name, oldState, _base, _j, _len2, _ref2, _ref3;
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
      _ref2 = this._batman.getAll(function(ancestor) {
        var _ref2, _ref3;
        return (_ref2 = ancestor._batman) != null ? (_ref3 = _ref2.get('states')) != null ? _ref3.get(name) : void 0 : void 0;
      });
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        event = _ref2[_j];
        if (event) {
          event(newState, oldState);
        }
      }
    }
    if (newState) {
      this.fire(newState, newState, oldState);
    }
    this._batman.isTransitioning = false;
    if ((_ref3 = this._batman.nextState) != null ? _ref3.length : void 0) {
      this[this._batman.nextState.shift()]();
    }
    return newState;
  };
  Batman.initializeObject = function(object) {
    if (object._batman != null) {
      return object._batman.check(object);
    } else {
      return object._batman = new _Batman(object);
    }
  };
  Batman._Batman = _Batman = (function() {
    function _Batman() {
      var mixins, object;
      object = arguments[0], mixins = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      this.object = object;
      if (mixins.length > 0) {
        $mixin.apply(null, [this].concat(__slice.call(mixins)));
      }
    }
    _Batman.prototype.check = function(object) {
      if (object !== this.object) {
        return object._batman = new _Batman(object);
      }
    };
    _Batman.prototype.get = function(key) {
      var results;
      results = this.getAll(key);
      switch (results.length) {
        case 0:
          return;
        case 1:
          return results[0];
        default:
          if (results[0].concat != null) {
            results = results.reduceRight(function(a, b) {
              return a.concat(b);
            });
          } else if (results[0].merge != null) {
            results = results.reduceRight(function(a, b) {
              return a.merge(b);
            });
          }
          return results;
      }
    };
    _Batman.prototype.getFirst = function(key) {
      var results;
      results = this.getAll(key);
      return results[0];
    };
    _Batman.prototype.getAll = function(keyOrGetter) {
      var getter, results, val;
      if (typeof keyOrGetter === 'function') {
        getter = keyOrGetter;
      } else {
        getter = function(ancestor) {
          var _ref2;
          return (_ref2 = ancestor._batman) != null ? _ref2[keyOrGetter] : void 0;
        };
      }
      results = this.ancestors(getter);
      if (val = getter(this.object)) {
        results.unshift(val);
      }
      return results;
    };
    _Batman.prototype.ancestors = function(getter) {
      var cons, isClass, parent, results, val, _ref2;
      if (getter == null) {
        getter = function(x) {
          return x;
        };
      }
      results = [];
      isClass = !!this.object.prototype;
      parent = isClass ? (_ref2 = this.object.__super__) != null ? _ref2.constructor : void 0 : (cons = this.object.constructor).prototype === this.object ? cons.__super__ : cons.prototype;
      if (parent != null) {
        val = getter(parent);
        if (val != null) {
          results.push(val);
        }
        if (parent._batman != null) {
          results = results.concat(parent._batman.ancestors(getter));
        }
      }
      return results;
    };
    _Batman.prototype.set = function(key, value) {
      return this[key] = value;
    };
    return _Batman;
  })();
  Batman.Object = (function() {
    Object.global = function(isGlobal) {
      if (isGlobal === false) {
        return;
      }
      return container[this.name] = this;
    };
    Object.classMixin = function() {
      return $mixin.apply(null, [this].concat(__slice.call(arguments)));
    };
    Object.mixin = function() {
      return this.classMixin.apply(this.prototype, arguments);
    };
    Object.prototype.mixin = Object.classMixin;
    Object.classAccessor = function() {
      var accessor, key, keys, value, _base, _base2, _j, _k, _len2, _results, _results2;
      keys = 2 <= arguments.length ? __slice.call(arguments, 0, _j = arguments.length - 1) : (_j = 0, []), accessor = arguments[_j++];
      Batman.initializeObject(this);
      if (keys.length === 0) {
        if (accessor.get || accessor.set) {
          return this._batman.defaultAccessor = accessor;
        } else if ($typeOf(accessor) === 'Function') {
          return this._batman.defaultAccessor = {
            get: accessor
          };
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
        if (!accessor.get && !accessor.set && !accessor.unset) {
          accessor = {
            get: accessor
          };
        }
        _results2 = [];
        for (_k = 0, _len2 = keys.length; _k < _len2; _k++) {
          key = keys[_k];
          _results2.push(this._batman.keyAccessors.set(key, accessor));
        }
        return _results2;
      }
    };
    Object.accessor = function() {
      return this.classAccessor.apply(this.prototype, arguments);
    };
    Object.prototype.accessor = Object.classAccessor;
    function Object() {
      var mixins;
      mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this._batman = new _Batman(this);
      this.mixin.apply(this, mixins);
    }
    Object.classMixin(Batman.Observable, Batman.EventEmitter);
    Object.mixin(Batman.Observable, Batman.EventEmitter);
    Object.observeAll = function() {
      return this.prototype.observe.apply(this.prototype, arguments);
    };
    Object.becomeStateMachine = function(includeInstanceMethods) {
      if (includeInstanceMethods == null) {
        includeInstanceMethods = true;
      }
      Batman.StateMachine.initialize.call(this);
      Batman.StateMachine.initialize.call(this.prototype);
      this.classState = function() {
        return Batman.StateMachine.state.apply(this, arguments);
      };
      this.state = function() {
        return this.classState.apply(this.prototype, arguments);
      };
      if (includeInstanceMethods) {
        this.prototype.state = this.classState;
      }
      this.classTransition = function() {
        return Batman.StateMachine.transition.apply(this, arguments);
      };
      this.transition = function() {
        return this.classTransition.apply(this.prototype, arguments);
      };
      if (includeInstanceMethods) {
        return this.prototype.transition = this.classTransition;
      }
    };
    return Object;
  })();
  Batman.SimpleHash = (function() {
    function SimpleHash() {
      this._storage = {};
      this.length = 0;
    }
    SimpleHash.prototype.hasKey = function(key) {
      return !$undef(this.get(key));
    };
    SimpleHash.prototype.get = function(key) {
      var matches, obj, v, _j, _len2, _ref2;
      if ($undef(key)) {
        return;
      }
      if (matches = this._storage[key]) {
        for (_j = 0, _len2 = matches.length; _j < _len2; _j++) {
          _ref2 = matches[_j], obj = _ref2[0], v = _ref2[1];
          if (this.equality(obj, key)) {
            return v;
          }
        }
      }
    };
    SimpleHash.prototype.set = function(key, val) {
      var match, matches, pair, _base, _j, _len2;
      if ($undef(key)) {
        return;
      }
      if ($undef(val)) {
        return this.unset(key);
      }
      matches = (_base = this._storage)[key] || (_base[key] = []);
      for (_j = 0, _len2 = matches.length; _j < _len2; _j++) {
        match = matches[_j];
        if (this.equality(match[0], key)) {
          pair = match;
          break;
        }
      }
      if (!pair) {
        pair = [key];
        matches.push(pair);
        this.length++;
      }
      return pair[1] = val;
    };
    SimpleHash.prototype.unset = function(key) {
      var index, matches, obj, v, _len2, _ref2;
      if (matches = this._storage[key]) {
        for (index = 0, _len2 = matches.length; index < _len2; index++) {
          _ref2 = matches[index], obj = _ref2[0], v = _ref2[1];
          if (this.equality(obj, key)) {
            matches.splice(index, 1);
            this.length--;
            return;
          }
        }
      }
    };
    SimpleHash.prototype.equality = function(lhs, rhs) {
      if ($undef(lhs) || $undef(rhs)) {
        return false;
      }
      if (typeof lhs.isEqual === 'function') {
        return lhs.isEqual(rhs);
      } else if (typeof rhs.isEqual === 'function') {
        return rhs.isEqual(lhs);
      } else {
        return lhs === rhs;
      }
    };
    SimpleHash.prototype.each = function(iterator) {
      var key, obj, value, values, _ref2, _results;
      _ref2 = this._storage;
      _results = [];
      for (key in _ref2) {
        values = _ref2[key];
        _results.push((function() {
          var _j, _len2, _ref3, _results2;
          _results2 = [];
          for (_j = 0, _len2 = values.length; _j < _len2; _j++) {
            _ref3 = values[_j], obj = _ref3[0], value = _ref3[1];
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
      this._storage = {};
      return this.length = 0;
    };
    SimpleHash.prototype.isEmpty = function() {
      return this.length === 0;
    };
    SimpleHash.prototype.merge = function() {
      var hash, merged, others, _j, _len2;
      others = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      merged = new this.constructor;
      others.unshift(this);
      for (_j = 0, _len2 = others.length; _j < _len2; _j++) {
        hash = others[_j];
        hash.each(function(obj, value) {
          return merged.set(obj, value);
        });
      }
      return merged;
    };
    return SimpleHash;
  })();
  Batman.Hash = (function() {
    var k, _j, _len2, _ref2;
    __extends(Hash, Batman.Object);
    function Hash() {
      Batman.SimpleHash.apply(this, arguments);
      Hash.__super__.constructor.apply(this, arguments);
    }
    Hash.accessor({
      get: Batman.SimpleHash.prototype.get,
      set: Batman.SimpleHash.prototype.set,
      unset: Batman.SimpleHash.prototype.unset
    });
    Hash.accessor('isEmpty', function() {
      return this.isEmpty();
    });
    _ref2 = ['hasKey', 'equality', 'each', 'keys', 'merge', 'clear', 'isEmpty'];
    for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
      k = _ref2[_j];
      Hash.prototype[k] = Batman.SimpleHash.prototype[k];
    }
    return Hash;
  })();
  Batman.SimpleSet = (function() {
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
    SimpleSet.prototype.add = function() {
      var addedItems, item, items, _j, _len2;
      items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      addedItems = [];
      for (_j = 0, _len2 = items.length; _j < _len2; _j++) {
        item = items[_j];
        if (!this._storage.hasKey(item)) {
          this._storage.set(item, true);
          addedItems.push(item);
          this.length++;
        }
      }
      if (addedItems.length !== 0) {
        this.itemsWereAdded.apply(this, addedItems);
      }
      return addedItems;
    };
    SimpleSet.prototype.remove = function() {
      var item, items, removedItems, _j, _len2;
      items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      removedItems = [];
      for (_j = 0, _len2 = items.length; _j < _len2; _j++) {
        item = items[_j];
        if (this._storage.hasKey(item)) {
          this._storage.unset(item);
          removedItems.push(item);
          this.length--;
        }
      }
      if (removedItems.length !== 0) {
        this.itemsWereRemoved.apply(this, removedItems);
      }
      return removedItems;
    };
    SimpleSet.prototype.each = function(iterator) {
      return this._storage.each(function(key, value) {
        return iterator(key);
      });
    };
    SimpleSet.prototype.isEmpty = function() {
      return this.length === 0;
    };
    SimpleSet.prototype.clear = function() {
      return this.remove(this.toArray());
    };
    SimpleSet.prototype.toArray = function() {
      return this._storage.keys();
    };
    SimpleSet.prototype.merge = function() {
      var merged, others, set, _j, _len2;
      others = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      merged = new this.constructor;
      others.unshift(this);
      for (_j = 0, _len2 = others.length; _j < _len2; _j++) {
        set = others[_j];
        set.each(function(v) {
          return merged.add(v);
        });
      }
      return merged;
    };
    SimpleSet.prototype.itemsWereAdded = function() {};
    SimpleSet.prototype.itemsWereRemoved = function() {};
    return SimpleSet;
  })();
  Batman.Set = (function() {
    var k, _j, _len2, _ref2;
    __extends(Set, Batman.Object);
    function Set() {
      Set.__super__.constructor.apply(this, arguments);
      _class.apply(this, arguments);
    }
    _class = Batman.SimpleSet;
    Set.prototype.itemsWereAdded = Set.event(function() {});
    Set.prototype.itemsWereRemoved = Set.event(function() {});
    _ref2 = ['add', 'remove', 'has', 'each', 'isEmpty', 'toArray', 'clear', 'merge'];
    for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
      k = _ref2[_j];
      Set.prototype[k] = Batman.SimpleSet.prototype[k];
    }
    Set.accessor('isEmpty', function() {
      return this.isEmpty();
    });
    return Set;
  })();
  Batman.SortableSet = (function() {
    __extends(SortableSet, Batman.Set);
    function SortableSet() {
      SortableSet.__super__.constructor.apply(this, arguments);
      this._indexes = {};
      this.observe('activeIndex', __bind(function() {
        return this.setWasSorted(this);
      }, this));
    }
    SortableSet.prototype.setWasSorted = SortableSet.event(function() {
      if (this.length === 0) {
        return false;
      }
    });
    SortableSet.prototype.add = function() {
      var results;
      results = Batman.SimpleSet.prototype.add.apply(this, arguments);
      this._reIndex();
      return results;
    };
    SortableSet.prototype.remove = function() {
      var results;
      results = Batman.SimpleSet.prototype.remove.apply(this, arguments);
      this._reIndex();
      return results;
    };
    SortableSet.prototype.addIndex = function(index) {
      return this._reIndex(index);
    };
    SortableSet.prototype.removeIndex = function(index) {
      this._indexes[index] = null;
      delete this._indexes[index];
      if (this.activeIndex === index) {
        this.unset('activeIndex');
      }
      return index;
    };
    SortableSet.prototype.each = function(iterator) {
      var el, _j, _len2, _ref2, _results;
      _ref2 = this.toArray();
      _results = [];
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        el = _ref2[_j];
        _results.push(iterator(el));
      }
      return _results;
    };
    SortableSet.prototype.sortBy = function(index) {
      if (!this._indexes[index]) {
        this.addIndex(index);
      }
      if (this.activeIndex !== index) {
        this.set('activeIndex', index);
      }
      return this;
    };
    SortableSet.prototype.toArray = function() {
      var _ref2;
      return (_ref2 = this._indexes[this.get('activeIndex')]) != null ? _ref2 : SortableSet.__super__.toArray.apply(this, arguments);
    };
    SortableSet.prototype._reIndex = function(index) {
      var ary, keypath, ordering, _ref2;
      if (index) {
        _ref2 = index.split(' '), keypath = _ref2[0], ordering = _ref2[1];
        ary = Batman.Set.prototype.toArray.call(this);
        this._indexes[index] = ary.sort(function(a, b) {
          var valueA, valueB, _ref3, _ref4, _ref5;
          valueA = (_ref3 = (Batman.Observable.property.call(a, keypath)).getValue()) != null ? _ref3.valueOf() : void 0;
          valueB = (_ref4 = (Batman.Observable.property.call(b, keypath)).getValue()) != null ? _ref4.valueOf() : void 0;
          if ((ordering != null ? ordering.toLowerCase() : void 0) === 'desc') {
            _ref5 = [valueB, valueA], valueA = _ref5[0], valueB = _ref5[1];
          }
          if (valueA < valueB) {
            return -1;
          } else if (valueA > valueB) {
            return 1;
          } else {
            return 0;
          }
        });
        if (this.activeIndex === index) {
          this.setWasSorted(this);
        }
      } else {
        for (index in this._indexes) {
          this._reIndex(index);
        }
        this.setWasSorted(this);
      }
      return this;
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
    Request.observeAll('url', function() {
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
      var base, name, names, path, _j, _len2;
      path = arguments[0], names = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      base = this.requirePath + path;
      for (_j = 0, _len2 = names.length; _j < _len2; _j++) {
        name = names[_j];
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
      if ($undef(this.layout)) {
        this.set('layout', new Batman.View({
          node: document,
          contexts: [this]
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
    route: $block(2, function(pattern, callback) {
      var array, f, match, namedArguments, regexp;
      f = function(params) {
        var components, context, controller, key, value;
        if ($typeOf(f.action) === 'String') {
          components = f.action.split('#');
          controller = Batman.currentApp[helpers.camelize(components[0]) + 'Controller'];
          if (controller) {
            f.context = controller;
            f.action = controller.prototype[components[1]];
          }
        }
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
      if ($undef(window)) {
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
      var route, _j, _len2, _ref2;
      _ref2 = Batman._routes;
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        route = _ref2[_j];
        if (route.regexp.test(url)) {
          return route;
        }
      }
      return null;
    },
    _extractParams: function(url, route) {
      var array, index, param, params, query, s, v, _j, _len2, _len3, _ref2, _ref3, _ref4;
      _ref2 = url.split('?'), url = _ref2[0], query = _ref2[1];
      array = route.regexp.exec(url).slice(1);
      params = {
        url: url
      };
      for (index = 0, _len2 = array.length; index < _len2; index++) {
        param = array[index];
        params[route.namedArguments[index]] = param;
      }
      if (query != null) {
        _ref3 = query.split('&');
        for (_j = 0, _len3 = _ref3.length; _j < _len3; _j++) {
          s = _ref3[_j];
          _ref4 = s.split('='), k = _ref4[0], v = _ref4[1];
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
      var filter, filters, key, params, result, route, _j, _len2;
      route = arguments[0], params = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      key = $findName(route, this);
      this._actedDuringAction = false;
      this._currentAction = key;
      filters = this.constructor._beforeFilters;
      if (filters) {
        for (_j = 0, _len2 = filters.length; _j < _len2; _j++) {
          filter = filters[_j];
          filter.call(this);
        }
      }
      result = route.fire(params, this);
      if (!this._actedDuringAction && result !== false) {
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
    var k, _j, _len2, _ref2;
    __extends(Model, Batman.Object);
    Model.persist = function() {
      var mechanism, mechanisms, storage, _base, _j, _len2;
      mechanisms = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      Batman.initializeObject(this.prototype);
      storage = (_base = this.prototype._batman).storage || (_base.storage = []);
      for (_j = 0, _len2 = mechanisms.length; _j < _len2; _j++) {
        mechanism = mechanisms[_j];
        storage.push(mechanism.isStorageAdapter ? mechanism : new mechanism(this));
      }
      return this;
    };
    Model.classAccessor('all', {
      get: function() {
        if (!this.all) {
          this.load();
        }
        return this.all;
      }
    });
    Model.classAccessor('first', {
      get: function() {
        return this.first = this.get('all')[0];
      }
    });
    Model.classAccessor('last', {
      get: function() {
        return this.last = this.get('all')[this.all.length - 1];
      }
    });
    Model.find = function(id) {
      var record, _j, _len2, _ref2;
      id = "" + id;
      _ref2 = this.get('all').toArray();
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        record = _ref2[_j];
        if (record._id() === id) {
          return record;
        }
      }
      record = new this(id);
      setTimeout((function() {
        return record.load();
      }), 0);
      return record;
    };
    Model.id = 'id';
    Model.prototype._id = function(id) {
      var all, key, model, record, records, _base;
      model = this.constructor;
      key = (typeof model.id === "function" ? model.id() : void 0) || model.id || 'id';
      if (arguments.length > 0) {
        id = "" + id;
        Batman.initializeObject(model);
        records = (_base = model._batman).records || (_base.records = {});
        record = records[id];
        all = model.get('all');
        if (record) {
          all.remove(record);
        }
        records[id] = this;
        all.add(this);
      }
      return this[key];
    };
    Model.beforeLoad = Model.event(function() {
      return this.get('all').clear();
    });
    Model.afterLoad = Model.event(function() {});
    Model.load = function(callback) {
      var afterLoad, allMechanisms, fireImmediately, m, mechanisms, _j, _k, _len2, _len3;
      this.all || (this.all = new Batman.Set);
      this.beforeLoad();
      afterLoad = __bind(function() {
        if (callback != null) {
          callback.call(this);
        }
        return this.afterLoad();
      }, this);
      allMechanisms = this.prototype._batman.getAll('storage');
      fireImmediately = !allMechanisms.length;
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
    Model.encode = function() {
      var decoder, encoder, encoderOrLastKey, key, keys, _base, _base2, _j, _k, _len2, _results;
      keys = 2 <= arguments.length ? __slice.call(arguments, 0, _j = arguments.length - 1) : (_j = 0, []), encoderOrLastKey = arguments[_j++];
      Batman.initializeObject(this.prototype);
      (_base = this.prototype._batman).encoders || (_base.encoders = new Batman.SimpleHash);
      (_base2 = this.prototype._batman).decoders || (_base2.decoders = new Batman.SimpleHash);
      switch ($typeOf(encoderOrLastKey)) {
        case 'String':
          keys.push(encoderOrLastKey);
          break;
        case 'Function':
          encoder = encoderOrLastKey;
          break;
        default:
          encoder = encoderOrLastKey.encode;
          decoder = encoderOrLastKey.decode;
      }
      _results = [];
      for (_k = 0, _len2 = keys.length; _k < _len2; _k++) {
        key = keys[_k];
        this.prototype._batman.encoders.set(key, encoder || this.defaultEncoder);
        _results.push(this.prototype._batman.decoders.set(key, decoder || this.defaultDecoder));
      }
      return _results;
    };
    Model.defaultEncoder = Model.defaultDecoder = function(x) {
      return x;
    };
    Model.validate = function() {
      var keys, match, matches, options, optionsOrFunction, validator, validators, _base, _j, _k, _len2, _results;
      keys = 2 <= arguments.length ? __slice.call(arguments, 0, _j = arguments.length - 1) : (_j = 0, []), optionsOrFunction = arguments[_j++];
      Batman.initializeObject(this.prototype);
      validators = (_base = this.prototype._batman).validators || (_base.validators = []);
      if (typeof optionsOrFunction === 'function') {
        return validators.push({
          keys: keys,
          callback: optionsOrFunction
        });
      } else {
        options = optionsOrFunction;
        _results = [];
        for (_k = 0, _len2 = Validators.length; _k < _len2; _k++) {
          validator = Validators[_k];
          _results.push((function() {
            var _l, _len3;
            if ((matches = validator.matches(options))) {
              for (_l = 0, _len3 = matches.length; _l < _len3; _l++) {
                match = matches[_l];
                delete options[match];
              }
              return validators.push({
                keys: keys,
                validator: new validator(matches)
              });
            }
          })());
        }
        return _results;
      }
    };
    Model.mixin(Batman.StateMachine);
    _ref2 = ['empty', 'dirty', 'loading', 'loaded', 'saving'];
    for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
      k = _ref2[_j];
      Model.prototype.state(k);
    }
    Model.prototype.state('saved', function() {
      return this.dirtyKeys.clear();
    });
    function Model(idOrAttributes) {
      var id;
      if (idOrAttributes == null) {
        idOrAttributes = {};
      }
      this.save = __bind(this.save, this);
      this.dirtyKeys = new Batman.Hash;
      this.errors = new Batman.Set;
      Model.__super__.constructor.apply(this, arguments);
      if (!this.state()) {
        this.empty();
      }
      id = $typeOf(idOrAttributes) === 'Object' ? idOrAttributes.id : idOrAttributes;
      if (id != null) {
        this._id(id);
      }
    }
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
    Model.accessor('dirtyKeys', function() {
      return this.dirtyKeys;
    });
    Model.prototype.toString = function() {
      return "" + this.constructor.name + ": " + (this._id());
    };
    Model.prototype.toJSON = function() {
      var encoders, obj;
      obj = {};
      encoders = this._batman.get('encoders');
      if (!(!encoders || encoders.isEmpty())) {
        encoders.each(__bind(function(key, encoder) {
          var encodedVal, val;
          val = this.get(key);
          if (!$undef(val)) {
            encodedVal = encoder(this.get(key));
            if (!$undef(encodedVal)) {
              return obj[key] = encodedVal;
            }
          }
        }, this));
      }
      return obj;
    };
    Model.prototype.fromJSON = function(data) {
      var decoders, key, obj, value;
      obj = {};
      decoders = this._batman.get('decoders');
      if (!decoders || decoders.isEmpty()) {
        for (key in data) {
          value = data[key];
          obj[helpers.camelize(key, true)] = value;
        }
      } else {
        decoders.each(function(key, decoder) {
          return obj[key] = decoder(data[key]);
        });
      }
      return this.mixin(obj);
    };
    Model.prototype.beforeLoad = Model.event(function() {
      this.loading();
      return true;
    });
    Model.prototype.afterLoad = Model.event(function() {
      this.loaded();
      return true;
    });
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
    Model.prototype.beforeValidation = Model.event(function() {});
    Model.prototype.afterValidation = Model.event(function() {});
    Model.prototype.load = function(callback) {
      var afterLoad, allMechanisms, fireImmediately, m, mechanisms, _k, _l, _len3, _len4;
      this.beforeLoad();
      afterLoad = __bind(function() {
        if (callback != null) {
          callback.call(this);
        }
        return this.afterLoad();
      }, this);
      allMechanisms = this._batman.getAll('storage');
      fireImmediately = !allMechanisms.length;
      for (_k = 0, _len3 = allMechanisms.length; _k < _len3; _k++) {
        mechanisms = allMechanisms[_k];
        fireImmediately = fireImmediately || !mechanisms.length;
        for (_l = 0, _len4 = mechanisms.length; _l < _len4; _l++) {
          m = mechanisms[_l];
          m.readFromStorage(this, afterLoad);
        }
      }
      if (fireImmediately) {
        return afterLoad();
      }
    };
    Model.prototype.save = function(callback) {
      var afterSave, allMechanisms, creating, fireImmediately, m, mechanisms, _k, _l, _len3, _len4;
      if (!this.isValid()) {
        return;
      }
      this.beforeSave();
      creating = this.isNew();
      if (creating) {
        this.beforeCreate();
      }
      afterSave = __bind(function() {
        this.dirtyKeys.clear();
        if ((callback != null) && (callback.call != null)) {
          if (callback != null) {
            callback.call(this);
          }
        }
        if (creating) {
          this.afterCreate();
        }
        return this.afterSave();
      }, this);
      allMechanisms = this._batman.getAll('storage');
      fireImmediately = !allMechanisms.length;
      for (_k = 0, _len3 = allMechanisms.length; _k < _len3; _k++) {
        mechanisms = allMechanisms[_k];
        fireImmediately = fireImmediately || !mechanisms.length;
        for (_l = 0, _len4 = mechanisms.length; _l < _len4; _l++) {
          m = mechanisms[_l];
          m.writeToStorage(this, afterSave);
        }
      }
      if (fireImmediately) {
        return afterSave();
      }
    };
    Model.prototype.validate = function() {
      var async, key, promise, v, validator, _k, _l, _len3, _len4, _ref3, _ref4;
      this.beforeValidation();
      async = false;
      _ref3 = this._batman.get('validators') || [];
      for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
        validator = _ref3[_k];
        v = validator.validator;
        _ref4 = validator.keys;
        for (_l = 0, _len4 = _ref4.length; _l < _len4; _l++) {
          key = _ref4[_l];
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
      if (async) {
        return false;
      } else {
        return this.afterValidation();
      }
    };
    Model.prototype.isNew = function() {
      return !this._id();
    };
    Model.prototype.isValid = function() {
      this.errors.clear();
      if (this.validate() === false) {
        return false;
      }
      return this.errors.isEmpty();
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
      throw "You must override validate in Batman.Validator subclasses.";
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
      Batman.initializeObject(this);
      if (this._batman.options) {
        return this._batman.options.concat(options);
      } else {
        return this._batman.options = options;
      }
    };
    Validator.matches = function(options) {
      var key, results, shouldReturn, value, _ref2, _ref3;
      results = {};
      shouldReturn = false;
      for (key in options) {
        value = options[key];
        if (~((_ref2 = this._batman) != null ? (_ref3 = _ref2.options) != null ? _ref3.indexOf(key) : void 0 : void 0)) {
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
  Validators = Batman.Validators = [
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
    StorageMechanism.prototype.isStorageAdapter = true;
    return StorageMechanism;
  })();
  Batman.LocalStorage = (function() {
    __extends(LocalStorage, Batman.StorageMechanism);
    function LocalStorage() {
      var _ref2;
      if (_ref2 = !'localStorage', __indexOf.call(window, _ref2) >= 0) {
        return null;
      }
      this.id = 0;
      LocalStorage.__super__.constructor.apply(this, arguments);
    }
    LocalStorage.prototype.writeToStorage = function(record, callback) {
      var id, key;
      key = this.modelKey;
      id = record._id() || record._id(++this.id);
      if (key && id) {
        localStorage[key + id] = JSON.stringify(record);
      }
      return callback();
    };
    LocalStorage.prototype.readFromStorage = function(record, callback) {
      var id, json, key;
      key = this.modelKey;
      id = record._id();
      if (key && id) {
        json = localStorage[key + id];
      }
      record.fromJSON(JSON.parse(json));
      return callback();
    };
    LocalStorage.prototype.readAllFromStorage = function(model, callback) {
      var data, k, re, record, v;
      re = new RegExp("$" + this.modelKey);
      for (k in localStorage) {
        v = localStorage[k];
        if (re.test(k)) {
          data = JSON.parse(v);
          record = new model(-1);
          record.fromJSON(data);
        }
      }
      callback();
    };
    return LocalStorage;
  })();
  Batman.RestStorage = (function() {
    __extends(RestStorage, Batman.StorageMechanism);
    function RestStorage() {
      RestStorage.__super__.constructor.apply(this, arguments);
    }
    RestStorage.prototype.optionsForRecord = function(record) {
      var options, _base;
      options = {
        type: 'json'
      };
      options.url = (record != null ? typeof record.url === "function" ? record.url() : void 0 : void 0) || (record != null ? record.url : void 0) || (typeof (_base = this.model).url === "function" ? _base.url() : void 0) || this.model.url || this.modelKey;
      if (record && !record.url) {
        options.url += "/" + (record._id());
      }
      return options;
    };
    RestStorage.prototype.writeToStorage = function(record, callback) {
      var options;
      options = $mixin(this.optionsForRecord(record), {
        method: record._id() ? 'put' : 'post',
        data: JSON.stringify(record),
        success: function() {
          return callback();
        },
        error: function(error) {
          return callback(error);
        }
      });
      return new Batman.Request(options);
    };
    RestStorage.prototype.readFromStorage = function(record, callback) {
      var options;
      options = $mixin(this.optionsForRecord(record), {
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
      return new Batman.Request(options);
    };
    RestStorage.prototype.readAllFromStorage = function(model, callback) {
      var options;
      options = $mixin(this.optionsForRecord(), {
        success: function(data) {
          var key, obj, record, _j, _len2;
          if (typeof data === 'string') {
            data = JSON.parse(data);
          }
          if (!Array.isArray(data)) {
            for (key in data) {
              data = data[key];
              break;
            }
          }
          for (_j = 0, _len2 = data.length; _j < _len2; _j++) {
            obj = data[_j];
            record = new model('' + obj[model.id]);
            record.fromJSON(obj);
          }
          callback();
        }
      });
      return new Batman.Request(options);
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
    View.observeAll('source', function() {
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
    View.observeAll('html', function(html) {
      var node;
      node = this.node || document.createElement('div');
      node.innerHTML = html;
      if (this.node !== node) {
        return this.set('node', node);
      }
    });
    View.observeAll('node', function(node) {
      if (!node) {
        return;
      }
      this.ready.fired = false;
      if (this._renderer) {
        this._renderer.forgetAll();
      }
      if (node) {
        this._renderer = new Batman.Renderer(node, __bind(function() {
          var content, _ref2;
          content = this.contentFor;
          if (typeof content === 'string') {
            this.contentFor = (_ref2 = Batman.DOM._yields) != null ? _ref2[content] : void 0;
          }
          if (this.contentFor && node) {
            this.contentFor.innerHTML = '';
            this.contentFor.appendChild(node);
          }
          return this.ready(node);
        }, this), this.contexts);
        if (this.context) {
          this._renderer.context.push(this.context);
        }
        return this._renderer.context.set('view', this);
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
      if (contexts == null) {
        contexts = [];
      }
      this.resume = __bind(this.resume, this);
      this.start = __bind(this.start, this);
      Renderer.__super__.constructor.apply(this, arguments);
      this.context = contexts instanceof RenderContext ? contexts : (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return typeof result === "object" ? result : child;
      })(RenderContext, contexts, function() {});
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
      var attr, index, name, nextNode, result, skipChildren, _base, _base2, _j, _len2, _name, _ref2, _ref3;
      if (new Date - this.startTime > 50) {
        this.resumeNode = node;
        setTimeout(this.resume, 0);
        return;
      }
      if (node.getAttribute) {
        this.context.set('node', node);
        _ref2 = node.attributes;
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          attr = _ref2[_j];
          name = (_ref3 = attr.nodeName.match(regexp)) != null ? _ref3[1] : void 0;
          if (!name) {
            continue;
          }
          result = (index = name.indexOf('-')) === -1 ? typeof (_base = Batman.DOM.readers)[name] === "function" ? _base[name](node, attr.value, this.context, this) : void 0 : typeof (_base2 = Batman.DOM.attrReaders)[_name = name.substr(0, index)] === "function" ? _base2[_name](node, name.substr(index + 1), attr.value, this.context, this) : void 0;
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
        if (this.node.isSameNode(nextParent)) {
          return;
        }
        parentSibling = nextParent.nextSibling;
        if (parentSibling) {
          return parentSibling;
        }
      }
    };
    return Renderer;
  })();
  Binding = (function() {
    var get_rx, keypath_rx;
    __extends(Binding, Batman.Object);
    keypath_rx = /(?:^|,)\s*(?!(?:true|false)\s*(?:$|,))([a-zA-Z][\w\.]*)\s*(?:$|,)/;
    get_rx = /(\w)\[(.+?)\]/;
    Binding.accessor('filteredValue', function() {
      var value;
      value = this.get('unfilteredValue');
      if (this.filterFunctions.length > 0) {
        return this.filterFunctions.reduce(__bind(function(value, fn, i) {
          var args;
          args = this.filterArguments[i].map(function(argument) {
            if (argument._keypath) {
              return argument.context.get(argument._keypath);
            } else {
              return argument;
            }
          });
          return fn.apply(null, [value].concat(__slice.call(args)));
        }, this), value);
      } else {
        return value;
      }
    });
    Binding.accessor('unfilteredValue', function() {
      if (this.get('key')) {
        return this.get("keyContext." + (this.get('key')));
      } else {
        return this.get('value');
      }
    });
    Binding.accessor('keyContext', function() {
      var unfilteredValue, _ref2;
      if (!this._keyContext) {
        _ref2 = this.renderContext.findKey(this.key), unfilteredValue = _ref2[0], this._keyContext = _ref2[1];
      }
      return this._keyContext;
    });
    function Binding() {
      var shouldSet;
      Binding.__super__.constructor.apply(this, arguments);
      this.parseFilter();
      shouldSet = true;
      if (Batman.DOM.nodeIsEditable(this.node)) {
        Batman.DOM.events.change(this.node, __bind(function() {
          shouldSet = false;
          if (this.nodeChange) {
            this.nodeChange(this.node, this._keyContext || this.value, this);
          } else {
            if (this.key) {
              this.get('keyContext').set(this.key, this.node.value);
            }
          }
          return shouldSet = true;
        }, this));
      }
      this.observe('filteredValue', true, __bind(function(value) {
        if (shouldSet) {
          if (this.dataChange) {
            return this.dataChange(value, this.node, this);
          } else {
            return Batman.DOM.valueForNode(this.node, value);
          }
        }
      }, this));
      this;
    }
    Binding.prototype.parseFilter = function() {
      var args, filter, filterName, filterString, filters, key, orig, split;
      this.filterFunctions = [];
      this.filterArguments = [];
      filters = this.keyPath.replace(get_rx, "$1 | get $2 ").replace(/'/g, '"').split(/(?!")\s+\|\s+(?!")/);
      try {
        key = this.parseSegment(orig = filters.shift())[0];
      } catch (e) {
        throw "Bad binding keypath \"" + orig + "\"!";
      }
      if (key._keypath) {
        this.key = key._keypath;
      } else {
        this.value = key;
      }
      if (filters.length) {
        while (filterString = filters.shift()) {
          split = filterString.indexOf(' ');
          if (~split) {
            filterName = filterString.substr(0, split);
            args = filterString.substr(split);
          } else {
            filterName = filterString;
          }
          if (filter = Batman.Filters[filterName]) {
            this.filterFunctions.push(filter);
            if (args) {
              try {
                this.filterArguments.push(this.parseSegment(args));
              } catch (e) {
                throw new Error("Bad filter arguments \"" + args + "\"!");
              }
            } else {
              this.filterArguments.push([]);
            }
          } else {
            throw new Error("Unrecognized filter " + filter + " in key \"" + this.keyPath + "\"!");
          }
        }
        return this.filterArguments = this.filterArguments.map(__bind(function(argumentList) {
          return argumentList.map(__bind(function(argument) {
            var _, _ref2;
            if (argument._keypath) {
              _ref2 = this.renderContext.findKey(argument._keypath), _ = _ref2[0], argument.context = _ref2[1];
            }
            return argument;
          }, this));
        }, this));
      }
    };
    Binding.prototype.parseSegment = function(segment) {
      return JSON.parse("[" + segment.replace(keypath_rx, "{\"_keypath\": \"$1\"}") + "]");
    };
    return Binding;
  })();
  RenderContext = (function() {
    var BindingProxy;
    function RenderContext() {
      var contexts;
      contexts = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this.contexts = contexts;
      this.storage = new Batman.Object;
      this.contexts.push(this.storage);
    }
    RenderContext.prototype.findKey = function(key) {
      var base, context, i, val;
      base = key.split('.')[0].split('|')[0].trim();
      i = this.contexts.length;
      while (i--) {
        context = this.contexts[i];
        if (context.get != null) {
          val = context.get(base);
        } else {
          val = context[base];
        }
        if (!$undef(val)) {
          return [$get(context, key), context];
        }
      }
      return [container.get(key), container];
    };
    RenderContext.prototype.set = function() {
      var args, _ref2;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return (_ref2 = this.storage).set.apply(_ref2, args);
    };
    RenderContext.prototype.push = function(x) {
      return this.contexts.push(x);
    };
    RenderContext.prototype.pop = function() {
      return this.contexts.pop();
    };
    RenderContext.prototype.clone = function() {
      var context;
      context = (function(func, args, ctor) {
        ctor.prototype = func.prototype;
        var child = new ctor, result = func.apply(child, args);
        return typeof result === "object" ? result : child;
      })(this.constructor, this.contexts, function() {});
      context.setStorage(this.storage);
      return context;
    };
    RenderContext.prototype.setStorage = function(storage) {
      this.contexts.splice(this.contexts.indexOf(this.storage), 1);
      this.push(storage);
      return storage;
    };
    BindingProxy = (function() {
      __extends(BindingProxy, Batman.Object);
      BindingProxy.prototype.isBindingProxy = true;
      function BindingProxy(binding, localKey) {
        this.binding = binding;
        this.localKey = localKey;
        if (this.localKey) {
          this.accessor(this.localKey, function() {
            return this.binding.get('filteredValue');
          });
        } else {
          this.accessor(function(key) {
            return this.binding.get("filteredValue." + key);
          });
        }
      }
      return BindingProxy;
    })();
    RenderContext.prototype.addKeyToScopeForNode = function(node, key, localName) {
      this.bind(node, key, __bind(function(value, node, binding) {
        return this.push(new BindingProxy(binding, localName));
      }, this), function() {
        return true;
      });
      return node.onParseExit = __bind(function() {
        return this.pop();
      }, this);
    };
    RenderContext.prototype.bind = function(node, key, dataChange, nodeChange) {
      return new Binding({
        renderContext: this,
        keyPath: key,
        node: node,
        dataChange: dataChange,
        nodeChange: nodeChange
      });
    };
    return RenderContext;
  })();
  Batman.DOM = {
    readers: {
      bind: function(node, key, context) {
        if (node.nodeName.toLowerCase() === 'input' && node.getAttribute('type') === 'checkbox') {
          return Batman.DOM.attrReaders.bind(node, 'checked', key, context);
        } else {
          return context.bind(node, key);
        }
      },
      context: function(node, key, context) {
        return context.addKeyToScopeForNode(node, key);
      },
      mixin: function(node, key, context) {
        context.push(Batman.mixins);
        context.bind(node, key, function(mixin) {
          return $mixin(node, mixin);
        }, function() {});
        return context.pop();
      },
      showif: function(node, key, context, renderer, invert) {
        var originalDisplay;
        originalDisplay = node.style.display;
        if (!originalDisplay || originalDisplay === 'none') {
          originalDisplay = 'block';
        }
        return context.bind(node, key, function(value) {
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
        }, function() {});
      },
      hideif: function() {
        var args, _ref2;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return (_ref2 = Batman.DOM.readers).showif.apply(_ref2, __slice.call(args).concat([true]));
      },
      route: function(node, key, context) {
        var controller, controllerName, id, index, route, routeName, _ref2;
        if (key.substr(0, 1) === '/') {
          route = Batman.redirect.bind(Batman, key);
          routeName = key;
        } else if ((index = key.indexOf('#')) !== -1) {
          controllerName = helpers.camelize(key.substr(0, index)) + 'Controller';
          controller = context.get(controllerName);
          route = controller != null ? controller.sharedInstance()[key.substr(index + 1)] : void 0;
          routeName = route != null ? route.pattern : void 0;
        } else {
          route = context.get(key);
          if (route instanceof Batman.Model) {
            controllerName = helpers.camelize(helpers.pluralize(key)) + 'Controller';
            controller = context.get(controllerName).sharedInstance();
            id = route._id();
            route = (_ref2 = controller.show) != null ? _ref2.bind(controller, {
              id: id
            }) : void 0;
            routeName = '/' + helpers.pluralize(key) + '/' + id;
          } else {
            routeName = route.pattern;
          }
        }
        if (node.nodeName.toUpperCase() === 'A') {
          node.href = Batman.HASH_PATTERN + (routeName || '');
        }
        return Batman.DOM.events.click(node, (function() {
          return typeof route === "function" ? route() : void 0;
        }));
      },
      partial: function(node, path, context) {
        var view;
        return view = new Batman.View({
          source: path + '.html',
          contentFor: node,
          contexts: Array.prototype.slice.call(context.contexts)
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
      _parseAttribute: function(value) {
        if (value === 'false') {
          value = false;
        }
        if (value === 'true') {
          value = true;
        }
        return value;
      },
      bind: function(node, attr, key, context) {
        var contextChange, nodeChange;
        switch (attr) {
          case 'checked':
            contextChange = function(value) {
              return node.checked = !!value;
            };
            nodeChange = function(node, subContext) {
              return subContext.set(key, Batman.DOM.attrReaders._parseAttribute(node.checked));
            };
            break;
          case 'value':
            contextChange = function(value) {
              return node.value = value;
            };
            nodeChange = function(node, subContext) {
              return subContext.set(key, Batman.DOM.attrReaders._parseAttribute(node.value));
            };
            break;
          default:
            contextChange = function(value) {
              return node.setAttribute(attr, value);
            };
            nodeChange = function(node, subContext) {
              return subContext.set(key, Batman.DOM.attrReaders._parseAttribute(node.getAttribute(attr)));
            };
        }
        return context.bind(node, key, contextChange, nodeChange);
      },
      context: function(node, contextName, key, context) {
        return context.addKeyToScopeForNode(node, key, contextName);
      },
      event: function(node, eventName, key, context) {
        var callback, subContext, _ref2;
        if (key.substr(0, 1) === '@') {
          callback = new Function(key.substr(1));
        } else {
          _ref2 = context.findKey(key), callback = _ref2[0], subContext = _ref2[1];
        }
        return Batman.DOM.events[eventName](node, function() {
          var confirmText;
          confirmText = node.getAttribute('data-confirm');
          if (confirmText && !confirm(confirmText)) {
            return;
          }
          return callback != null ? callback.apply(subContext, arguments) : void 0;
        });
      },
      addclass: function(node, className, key, context, parentRenderer, invert) {
        className = className.replace(/\|/g, ' ');
        return context.bind(node, key, function(value) {
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
        }, function() {});
      },
      removeclass: function() {
        var args, _ref2;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return (_ref2 = Batman.DOM.attrReaders).addclass.apply(_ref2, __slice.call(args).concat([true]));
      },
      foreach: function(node, iteratorName, key, context, parentRenderer) {
        var add, nodeMap, parent, prototype, remove, reorder, sibling;
        prototype = node.cloneNode(true);
        prototype.removeAttribute("data-foreach-" + iteratorName);
        parent = node.parentNode;
        sibling = node.nextSibling;
        setTimeout(function() {
          if (node.nextSibling != null) {
            return parent.removeChild(node);
          }
        }, 0);
        nodeMap = new Batman.Hash;
        add = function() {
          var item, items, iteratorContext, localClone, newNode, _j, _len2, _results;
          items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          _results = [];
          for (_j = 0, _len2 = items.length; _j < _len2; _j++) {
            item = items[_j];
            newNode = prototype.cloneNode(true);
            nodeMap.set(item, newNode);
            localClone = context.clone();
            iteratorContext = new Batman.Object;
            iteratorContext[iteratorName] = item;
            localClone.push(iteratorContext);
            localClone.push(item);
            _results.push(new Batman.Renderer(newNode, (function(newNode) {
              return function() {
                parent.insertBefore(newNode, sibling);
                return parentRenderer.allow('ready');
              };
            })(newNode), localClone));
          }
          return _results;
        };
        remove = function() {
          var item, items, oldNode, _j, _len2, _ref2, _results;
          items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          _results = [];
          for (_j = 0, _len2 = items.length; _j < _len2; _j++) {
            item = items[_j];
            oldNode = nodeMap.get(item);
            nodeMap.unset(item);
            _results.push(oldNode != null ? (_ref2 = oldNode.parentNode) != null ? _ref2.removeChild(oldNode) : void 0 : void 0);
          }
          return _results;
        };
        reorder = function(set) {
          var item, _j, _len2, _ref2, _results;
          _ref2 = set.toArray();
          _results = [];
          for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
            item = _ref2[_j];
            _results.push(parent.insertBefore(nodeMap.get(item), sibling));
          }
          return _results;
        };
        context.bind(node, key, function(collection) {
          var k, v, _results;
          if (collection != null ? collection.observe : void 0) {
            collection.observe('itemsWereAdded', add);
            collection.observe('itemsWereRemoved', remove);
            collection.observe('setWasSorted', reorder);
          }
          if (collection.each) {
            return collection.each(function(korv, v) {
              return add(v != null ? v : korv);
            });
          } else if (collection.forEach) {
            return collection.forEach(function(x) {
              return add(x);
            });
          } else {
            _results = [];
            for (k in collection) {
              v = collection[k];
              _results.push(add(v));
            }
            return _results;
          }
        }, function() {});
        return false;
      },
      formfor: function(node, localName, key, context) {
        var binding;
        binding = context.addKeyToScopeForNode(node, key, localName);
        return Batman.DOM.events.submit(node, function(e) {
          return e.preventDefault();
        });
      }
    },
    events: {
      click: function(node, callback) {
        Batman.DOM.addEventListener(node, 'click', function(e) {
          callback(node, e);
          return e.preventDefault();
        });
        if (node.nodeName.toUpperCase() === 'A' && !node.href) {
          node.href = '#';
        }
        return node;
      },
      change: function(node, callback) {
        var eventName, eventNames, oldCallback, _j, _len2;
        eventNames = (function() {
          switch (node.nodeName.toUpperCase()) {
            case 'TEXTAREA':
              return ['keyup', 'change'];
            case 'INPUT':
              if (node.type.toUpperCase() === 'TEXT') {
                oldCallback = callback;
                callback = function(e) {
                  var _ref2;
                  if (e.type === 'keyup' && (13 <= (_ref2 = e.keyCode) && _ref2 <= 14)) {
                    return;
                  }
                  return oldCallback.apply(null, arguments);
                };
                return ['keyup', 'change'];
              } else {
                return ['change'];
              }
              break;
            default:
              return ['change'];
          }
        })();
        for (_j = 0, _len2 = eventNames.length; _j < _len2; _j++) {
          eventName = eventNames[_j];
          Batman.DOM.addEventListener(node, eventName, function(e) {
            return callback(node, e);
          });
        }
        return node;
      },
      submit: function(node, callback) {
        if (Batman.DOM.nodeIsEditable(node)) {
          Batman.DOM.addEventListener(node, 'keyup', function(e) {
            if (e.keyCode === 13) {
              callback(node, e);
              return e.preventDefault();
            }
          });
        } else {
          Batman.DOM.addEventListener(node, 'submit', function(e) {
            callback(node, e);
            return e.preventDefault();
          });
        }
        return node;
      }
    },
    yield: function(name, node) {
      var content, yields, _base, _ref2;
      yields = (_base = Batman.DOM)._yields || (_base._yields = {});
      yields[name] = node;
      if ((content = (_ref2 = Batman.DOM._yieldContents) != null ? _ref2[name] : void 0)) {
        node.innerHTML = '';
        if (content) {
          return node.appendChild(content);
        }
      }
    },
    contentFor: function(name, node) {
      var contents, yield, _base, _ref2;
      contents = (_base = Batman.DOM)._yieldContents || (_base._yieldContents = {});
      contents[name] = node;
      if ((yield = (_ref2 = Batman.DOM._yields) != null ? _ref2[name] : void 0)) {
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
      var _ref2;
      return (_ref2 = node.nodeName.toUpperCase()) === 'INPUT' || _ref2 === 'TEXTAREA';
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
  capitalize_rx = /(^|\s)([a-z])/g;
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
      if (string.substr(-3) === 'ies') {
        return string.substr(0, string.length - 3) + 'y';
      } else if (string.substr(-1) === 's') {
        return string.substr(0, string.length - 1);
      } else {
        return string;
      }
    },
    pluralize: function(count, string) {
      var lastLetter;
      if (string) {
        if (count === 1) {
          return string;
        }
      } else {
        string = count;
      }
      lastLetter = string.substr(-1);
      if (lastLetter === 'y') {
        return "" + (string.substr(0, string.length - 1)) + "ies";
      } else if (lastLetter === 's') {
        return string;
      } else {
        return "" + string + "s";
      }
    },
    capitalize: function(string) {
      return string.replace(capitalize_rx, function(m, p1, p2) {
        return p1 + p2.toUpperCase();
      });
    }
  };
  buntUndefined = function(f) {
    return function(value) {
      if ($undef(value)) {
        return;
      } else {
        return f.apply(this, arguments);
      }
    };
  };
  filters = Batman.Filters = {
    get: buntUndefined(function(value, key) {
      if (value.get != null) {
        return value.get(key);
      } else {
        return value[key];
      }
    }),
    truncate: buntUndefined(function(value, length, end) {
      if (end == null) {
        end = "...";
      }
      if (value.length > length) {
        value = value.substr(0, length - end.length) + end;
      }
      return value;
    }),
    "default": function(value, string) {
      return value || string;
    },
    prepend: function(value, string) {
      return string + value;
    },
    append: function(value, string) {
      return value + string;
    },
    downcase: buntUndefined(function(value) {
      return value.toLowerCase();
    }),
    upcase: buntUndefined(function(value) {
      return value.toUpperCase();
    }),
    pluralize: buntUndefined(function(string, count) {
      return helpers.pluralize(count, string);
    }),
    join: buntUndefined(function(value, byWhat) {
      if (byWhat == null) {
        byWhat = '';
      }
      return value.join(byWhat);
    }),
    sort: buntUndefined(function(value) {
      return value.sort();
    }),
    map: buntUndefined(function(value, key) {
      return value.map(function(x) {
        return x[key];
      });
    }),
    first: buntUndefined(function(value) {
      return value[0];
    })
  };
  _ref2 = ['capitalize', 'singularize', 'underscore', 'camelize'];
  for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
    k = _ref2[_j];
    filters[k] = buntUndefined(helpers[k]);
  }
  mixins = Batman.mixins = new Batman.Object;
  container = typeof exports !== "undefined" && exports !== null ? (module.exports = Batman, global) : (window.Batman = Batman, window);
  $mixin(container, Batman.Observable);
  Batman.exportHelpers = function(onto) {
    var k, _k, _len3, _ref3;
    _ref3 = ['mixin', 'unmixin', 'route', 'redirect', 'event', 'eventOneShot', 'typeOf'];
    for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
      k = _ref3[_k];
      onto["$" + k] = Batman[k];
    }
    return onto;
  };
  Batman.exportGlobals = function() {
    return Batman.exportHelpers(container);
  };
}).call(this);

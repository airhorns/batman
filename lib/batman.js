(function() {
  /*
  # batman.js
  # batman.coffee
  */  var $event, $eventOneShot, $mixin, $redirect, $route, $typeOf, $unmixin, Batman, camelize_rx, escapeRegExp, filters, global, helpers, namedOrSplat, namedParam, splatParam, underscore_rx1, underscore_rx2, _objectToString;
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
  Batman.Hash = (function() {
    function Hash() {
      this._storage = {};
    }
    Hash.prototype.hasKey = function(key) {
      return typeof this.get(key) !== 'undefined';
    };
    Hash.prototype.get = function(key) {
      var matches, obj, v, _i, _len, _ref;
      if (matches = this._storage[key]) {
        for (_i = 0, _len = matches.length; _i < _len; _i++) {
          _ref = matches[_i], obj = _ref[0], v = _ref[1];
          if (this.equality(obj, key)) {
            return v;
          }
        }
      }
    };
    Hash.prototype.set = function(key, val) {
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
    Hash.prototype.remove = function(key) {
      var index, matches, obj, v, _len, _ref;
      if (matches = this._storage[key]) {
        for (index = 0, _len = matches.length; index < _len; index++) {
          _ref = matches[index], obj = _ref[0], v = _ref[1];
          if (this.equality(obj, key)) {
            matches.splice(index, 1);
            return obj;
          }
        }
      }
    };
    Hash.prototype.equality = function(lhs, rhs) {
      if (typeof lhs.isEqual === 'function') {
        return lhs.isEqual(rhs);
      } else if (typeof rhs.isEqual === 'function') {
        return rhs.isEqual(lhs);
      } else {
        return lhs === rhs;
      }
    };
    Hash.prototype.keys = function() {
      var key, obj, result, value, values, _i, _len, _ref, _ref2;
      result = [];
      _ref = this._storage;
      for (key in _ref) {
        values = _ref[key];
        for (_i = 0, _len = values.length; _i < _len; _i++) {
          _ref2 = values[_i], obj = _ref2[0], value = _ref2[1];
          result.push(obj);
        }
      }
      return result;
    };
    return Hash;
  })();
  Batman.Set = (function() {
    function Set() {
      this._storage = new Batman.Hash;
    }
    Set.prototype.has = function(item) {
      return this._storage.hasKey(item);
    };
    Set.prototype.add = function(item) {
      this._storage.set(item, true);
      return item;
    };
    Set.prototype.remove = function(item) {
      return this._storage.remove(item);
    };
    Set.prototype.toArray = function() {
      return this._storage.keys();
    };
    return Set;
  })();
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
  Batman.Trigger = (function() {
    Trigger.populateKeypath = function(keypath, callback) {
      return keypath.eachPair(function(minimalKeypath, index) {
        if (!minimalKeypath.base.observe) {
          return;
        }
        Batman.Observable.initialize.call(minimalKeypath.base);
        return new Batman.Trigger(minimalKeypath.base, minimalKeypath.segments[0], keypath, callback);
      });
    };
    function Trigger(base, key, targetKeypath, callback) {
      var _base, _base2, _i, _len, _name, _name2, _ref;
      this.base = base;
      this.key = key;
      this.targetKeypath = targetKeypath;
      this.callback = callback;
      _ref = [this.base, this.targetKeypath.base];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        base = _ref[_i];
        if (!base.observe) {
          return;
        }
        Batman.Observable.initialize.call(base);
      }
      ((_base = this.base._batman.outboundTriggers)[_name = this.key] || (_base[_name] = new Batman.TriggerSet())).add(this);
      ((_base2 = this.targetKeypath.base._batman.inboundTriggers)[_name2 = this.targetKeypath.path()] || (_base2[_name2] = new Batman.TriggerSet())).add(this);
    }
    Trigger.prototype.isEqual = function(other) {
      return other instanceof Batman.Trigger && this.base === other.base && this.key === other.key && this.targetKeypath.isEqual(other.targetKeypath) && this.callback === other.callback;
    };
    Trigger.prototype.isInKeypath = function() {
      var segment, targetBase, _i, _len, _ref;
      targetBase = this.targetKeypath.base;
      _ref = this.targetKeypath.segments;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        segment = _ref[_i];
        if (targetBase === this.base && segment === this.key) {
          return true;
        }
        targetBase = targetBase != null ? targetBase[segment] : void 0;
        if (!targetBase) {
          return false;
        }
      }
    };
    Trigger.prototype.hasActiveObserver = function() {
      return this.targetKeypath.base.observesKeyWithObserver(this.targetKeypath.path(), this.callback);
    };
    Trigger.prototype.remove = function() {
      var inboundSet, outboundSet, _ref, _ref2;
      if (outboundSet = (_ref = this.base._batman) != null ? _ref.outboundTriggers[this.key] : void 0) {
        outboundSet.remove(this);
      }
      if (inboundSet = (_ref2 = this.targetKeypath.base._batman) != null ? _ref2.inboundTriggers[this.targetKeypath.path()] : void 0) {
        return inboundSet.remove(this);
      }
    };
    return Trigger;
  })();
  Batman.TriggerSet = (function() {
    function TriggerSet() {
      this.triggers = [];
      this.keypaths = [];
      this.oldValues = [];
    }
    TriggerSet.prototype.add = function(trigger) {
      this._add(trigger, this.triggers);
      this._add(trigger.targetKeypath, this.keypaths);
      return trigger;
    };
    TriggerSet.prototype.remove = function(trigger) {
      var result, t, _i, _len, _ref;
      if (!(result = this._remove(trigger, this.triggers))) {
        return;
      }
      _ref = this.triggers;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        t = _ref[_i];
        if (t.targetKeypath.isEqual(trigger.targetKeypath)) {
          return result;
        }
      }
      this._remove(trigger.targetKeypath, this.keypaths);
      return result;
    };
    TriggerSet.prototype._add = function(item, set) {
      var existingItem, _i, _len;
      for (_i = 0, _len = set.length; _i < _len; _i++) {
        existingItem = set[_i];
        if (item.isEqual(existingItem)) {
          return existingItem;
        }
      }
      return set.push(item);
    };
    TriggerSet.prototype._remove = function(item, set) {
      var existingItem, index, _len;
      for (index = 0, _len = set.length; index < _len; index++) {
        existingItem = set[index];
        if (item.isEqual(existingItem)) {
          set.splice(index, 1);
          return existingItem;
        }
      }
    };
    TriggerSet.prototype.rememberOldValues = function() {
      var keypath, _i, _len, _ref, _results;
      this.oldValues = [];
      _ref = this.keypaths;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        keypath = _ref[_i];
        _results.push(this.oldValues.push(keypath.resolve()));
      }
      return _results;
    };
    TriggerSet.prototype.forgetOldValues = function() {
      return this.oldValues = [];
    };
    TriggerSet.prototype.fireAll = function() {
      var index, keypath, _len, _ref, _results;
      _ref = this.keypaths;
      _results = [];
      for (index = 0, _len = _ref.length; index < _len; index++) {
        keypath = _ref[index];
        _results.push(keypath.base.fire(keypath.path(), keypath.resolve(), this.oldValues[index]));
      }
      return _results;
    };
    TriggerSet.prototype.refreshKeypathsWithTriggers = function() {
      var trigger, _i, _len, _ref, _results;
      _ref = this.triggers;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        trigger = _ref[_i];
        _results.push(Batman.Trigger.populateKeypath(trigger.targetKeypath, trigger.callback));
      }
      return _results;
    };
    TriggerSet.prototype.removeTriggersNotInKeypath = function() {
      var trigger, _i, _len, _ref, _results;
      _ref = this.triggers.slice();
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        trigger = _ref[_i];
        _results.push(!trigger.isInKeypath() ? trigger.remove() : void 0);
      }
      return _results;
    };
    TriggerSet.prototype.removeTriggersWithInactiveObservers = function() {
      var trigger, _i, _len, _ref, _results;
      _ref = this.triggers.slice();
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        trigger = _ref[_i];
        _results.push(!trigger.hasActiveObserver() ? trigger.remove() : void 0);
      }
      return _results;
    };
    return TriggerSet;
  })();
  /*
  # Batman.Observable
  */
  Batman.Observable = {
    initialize: function() {
      var _base, _base2, _base3, _base4;
      Batman._initializeObject(this);
      (_base = this._batman).observers || (_base.observers = {});
      (_base2 = this._batman).outboundTriggers || (_base2.outboundTriggers = {});
      (_base3 = this._batman).inboundTriggers || (_base3.inboundTriggers = {});
      return (_base4 = this._batman).preventCounts || (_base4.preventCounts = {});
    },
    rememberingOutboundTriggerValues: function(key, callback) {
      var triggers;
      Batman.Observable.initialize.call(this);
      if (triggers = this._batman.outboundTriggers[key]) {
        triggers.rememberOldValues();
      }
      callback();
      if (triggers) {
        return triggers.forgetOldValues();
      }
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
      minimalKeypath.base.rememberingOutboundTriggerValues(minimalKeypath.segments[0], function() {
        minimalKeypath.assign(val);
        return minimalKeypath.base.fire(minimalKeypath.segments[0], val, oldValue);
      });
      return val;
    },
    unset: function(key) {
      var minimalKeypath, oldValue;
      minimalKeypath = this.keypath(key).finalPair();
      oldValue = minimalKeypath.resolve();
      minimalKeypath.base.rememberingOutboundTriggerValues(minimalKeypath.segments[0], function() {
        minimalKeypath.remove();
        return minimalKeypath.base.fire(minimalKeypath.segments[0], void 0, oldValue);
      });
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
        Batman.Trigger.populateKeypath(keypath, callback);
      }
      if (fireImmediately) {
        callback.call(this, currentVal, currentVal);
      }
      return this;
    },
    fire: function(key, value, oldValue) {
      var args, callback, observers, outboundTriggers, _i, _j, _len, _len2, _ref, _ref2, _ref3, _ref4;
      if (!this.allowed(key)) {
        return;
      }
      Batman.Observable.initialize.call(this);
      args = [value];
      if (typeof oldValue !== 'undefined') {
        args.push(oldValue);
      }
      _ref3 = [this._batman.observers[key], (_ref = this.constructor.prototype._batman) != null ? (_ref2 = _ref.observers) != null ? _ref2[key] : void 0 : void 0];
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        observers = _ref3[_i];
        if (!observers) {
          continue;
        }
        for (_j = 0, _len2 = observers.length; _j < _len2; _j++) {
          callback = observers[_j];
          callback.apply(this, args);
        }
      }
      if (outboundTriggers = this._batman.outboundTriggers[key]) {
        outboundTriggers.fireAll();
        outboundTriggers.refreshKeypathsWithTriggers();
      }
      if ((_ref4 = this._batman.inboundTriggers[key]) != null) {
        _ref4.removeTriggersNotInKeypath();
      }
      return this;
    },
    observesKeyWithObserver: function(key, observer) {
      var o, _i, _len, _ref, _ref2, _ref3;
      if (!((_ref = this._batman) != null ? (_ref2 = _ref.observers) != null ? _ref2[key] : void 0 : void 0)) {
        return false;
      }
      _ref3 = this._batman.observers[key];
      for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
        o = _ref3[_i];
        if (o === observer) {
          return true;
        }
      }
      return false;
    },
    forget: function(key, callback) {
      var callbackIndex, k, keyObservers, o, triggersForKey, _i, _len, _ref;
      Batman.Observable.initialize.call(this);
      if (key) {
        if (callback) {
          if (keyObservers = this._batman.observers[key]) {
            callbackIndex = keyObservers.indexOf(callback);
            if (callbackIndex !== -1) {
              keyObservers.splice(callbackIndex, 1);
            }
          }
          if (triggersForKey = this._batman.inboundTriggers[key]) {
            triggersForKey.removeTriggersWithInactiveObservers();
          }
        } else {
          _ref = this._batman.observers[key];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            o = _ref[_i];
            this.forget(key, o);
          }
        }
      } else {
        for (k in this._batman.observers) {
          this.forget(k);
        }
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
    event: function(key, callback) {
      var callbackEater;
      if (!callback && $typeOf(key) !== 'String') {
        callback = key;
        key = null;
      }
      callbackEater = function(callback, context) {
        var f;
        f = function(observer) {
          var args, value, _ref;
          if (!this.observe) {
            throw "EventEmitter object needs to be observable.";
          }
          key || (key = Batman._findName(f, this));
          if (typeof observer === 'function') {
            this.observe(key, observer);
            if (f.isOneShot && f.fired) {
              return observer.apply(this, f._firedArgs);
            }
          } else if (this.allowed(key)) {
            if (f.isOneShot && f.fired) {
              return false;
            }
            value = callback != null ? callback.apply(this, arguments) : void 0;
            if (value !== false) {
              if (typeof value === 'undefined') {
                value = arguments[0];
              }
              if (typeof value === 'undefined') {
                value = null;
              }
              f._firedArgs = (_ref = [value]).concat.apply(_ref, arguments);
              args = Array.prototype.slice.call(f._firedArgs);
              args.unshift(key);
              this.fire.apply(this, args);
              if (f.isOneShot) {
                f.fired = true;
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
        if ($typeOf(key) === 'String') {
          this[key] = f;
        }
        return $mixin(f, {
          isEvent: true,
          action: callback,
          isOneShot: callbackEater.isOneShot
        });
      };
      if (typeof callback === 'function') {
        return callbackEater.call(this, callback);
      } else {
        return callbackEater;
      }
    },
    eventOneShot: function(callback) {
      return $mixin(Batman.EventEmitter.event.apply(this, arguments), {
        isOneShot: true
      });
    }
  };
  $event = function(callback) {
    var context;
    context = new Batman.Object;
    return context.event('_event')(callback, context);
  };
  $eventOneShot = function(callback) {
    var context;
    context = new Batman.Object;
    return context.eventOneShot('_event')(callback, context);
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
    Object.prototype.mixin(Batman.Observable, Batman.EventEmitter);
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
      if (typeof callback === 'function') {
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
    global.$redirect = $redirect;
    global.$event = $event;
    return global.$eventOneShot = $eventOneShot;
  };
}).call(this);

(function() {
  /*
  # batman.coffee
  # batman.js
  # 
  # Created by Nicholas Small
  # Copyright 2011, JadedPixel Technologies, Inc.
  */  var $event, $eventOneShot, $mixin, $redirect, $route, $typeOf, $unmixin, Batman, camelize_rx, escapeRegExp, filters, global, helpers, matchContext, mixins, namedOrSplat, namedParam, splatParam, underscore_rx1, underscore_rx2, _objectToString;
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
    var _ref;
    if (object.prototype && ((_ref = object._batman) != null ? _ref.__initClass__ : void 0) !== this) {
      return object._batman = {
        __initClass__: this
      };
    } else if (!object.hasOwnProperty('_batman')) {
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
    Hash.prototype.each = function(iterator) {
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
    Hash.prototype.keys = function() {
      var result;
      result = [];
      this.each(function(obj) {
        return result.push(obj);
      });
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
    Set.prototype.each = function(iterator) {
      return this._storage.each(function(key, value) {
        return iterator(key);
      });
    };
    Set.prototype.toArray = function() {
      return this._storage.keys();
    };
    return Set;
  })();
  Batman.SortableSet = (function() {
    function SortableSet(index) {
      SortableSet.__super__.constructor.apply(this, arguments);
      this._indexes = {};
      this.addIndex(index);
    }
    __extends(SortableSet, Batman.Set);
    SortableSet.prototype.add = function(item) {
      SortableSet.__super__.add.apply(this, arguments);
      this._reIndex();
      return item;
    };
    SortableSet.prototype.remove = function(item) {
      SortableSet.__super__.remove.apply(this, arguments);
      this._reIndex();
      return item;
    };
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
          valueA = (_ref2 = (new Batman.Keypath(a, keypath)).resolve()) != null ? _ref2.valueOf() : void 0;
          valueB = (_ref3 = (new Batman.Keypath(b, keypath)).resolve()) != null ? _ref3.valueOf() : void 0;
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
  /*
  # Batman.Keypath
  # A keypath has a base object and one or more key segments
  # which represent a path to a target value.
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
      var base, segment, _i, _len, _ref;
      base = this.base;
      _ref = this.segments.slice(0, begin);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        segment = _ref[_i];
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
      this.triggers = new Batman.Set;
      this.oldValues = new Batman.Hash;
    }
    TriggerSet.prototype.add = function(trigger) {
      return this.triggers.add(trigger);
    };
    TriggerSet.prototype.remove = function(trigger) {
      return this.triggers.remove(trigger);
    };
    TriggerSet.prototype.keypaths = function() {
      var result;
      result = new Batman.Set;
      this.triggers.each(function(trigger) {
        return result.add(trigger.targetKeypath);
      });
      return result;
    };
    TriggerSet.prototype.rememberOldValues = function() {
      var oldValues;
      oldValues = this.oldValues = new Batman.Hash;
      return this.keypaths().each(function(keypath) {
        return oldValues.set(keypath, keypath.resolve());
      });
    };
    TriggerSet.prototype.fireAll = function() {
      return this.oldValues.each(function(keypath, oldValue) {
        return keypath.base.fire(keypath.path(), keypath.resolve(), oldValue);
      });
    };
    TriggerSet.prototype.refreshKeypathsWithTriggers = function() {
      return this.triggers.each(function(trigger) {
        return Batman.Trigger.populateKeypath(trigger.targetKeypath, trigger.callback);
      });
    };
    TriggerSet.prototype.removeTriggersNotInKeypath = function() {
      var trigger, _i, _len, _ref, _results;
      _ref = this.triggers.toArray();
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        trigger = _ref[_i];
        _results.push(!trigger.isInKeypath() ? trigger.remove() : void 0);
      }
      return _results;
    };
    TriggerSet.prototype.removeTriggersWithInactiveObservers = function() {
      var trigger, _i, _len, _ref, _results;
      _ref = this.triggers.toArray();
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
  # Batman.Observable is a generic mixin that can be applied to any object in
  # order to make that object bindable. It is applied by default to every
  # instance of Batman.Object and subclasses.
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
      return callback();
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
  # Another generic mixin that simply allows an object to emit events. All events
  # require an object that is observable. If you don't want to use an emitter,
  # you can use the $event functions to create ephemeral objects internally.
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
  # The base class for all other Batman objects. It is not abstract. 
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
  # Batman.Request
  # A normalizer for XHR requests.
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
      return this._autosendTimeout = setTimeout((__bind(function() {
        return this.send();
      }, this)), 0);
    });
    Request.prototype.loading = Request.event(function() {});
    Request.prototype.loaded = Request.event(function() {});
    Request.prototype.success = Request.event(function() {});
    Request.prototype.error = Request.event(function() {});
    Request.prototype.send = function(data) {};
    Request.prototype.cancel = function() {
      if (this._autosendTimeout) {
        return clearTimeout(this._autosendTimeout);
      }
    };
    return Request;
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
  /*
  # Routing
  */
  namedParam = /:([\w\d]+)/g;
  splatParam = /\*([\w\d]+)/g;
  namedOrSplat = /[:|\*]([\w\d]+)/g;
  escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g;
  Batman.Route = {
    isRoute: true,
    pattern: null,
    regexp: null,
    namedArguments: null,
    action: null,
    context: null,
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
        var array, f, match, namedArguments, regexp;
        f = function() {
          var args, context;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          context = f.context || this;
          if (context && context.sharedInstance) {
            context = context.sharedInstance();
          }
          if (context && context.dispatch) {
            return context.dispatch.apply(context, [f].concat(__slice.call(args)));
          } else {
            return f.action.apply(context, arguments);
          }
        };
        match = pattern.replace(escapeRegExp, '\\$&');
        regexp = new RegExp('^' + match.replace(namedParam, '([^\/]*)').replace(splatParam, '(.*?)') + '$');
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
  Batman.Object.route = Batman.App.route = $route = Batman.route;
  Batman.Object.redirect = Batman.App.redirect = $redirect = Batman.redirect;
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
        return this._routeHandler = setInterval(parseUrl, 100);
      }
    },
    stopRouting: function() {
      if (!this._routeHandler) {
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
        if (url !== '/404') {
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
      var array, index, param, params, _len;
      array = route.regexp.exec(url).slice(1);
      params = {
        url: url
      };
      for (index = 0, _len = array.length; index < _len; index++) {
        param = array[index];
        params[route.namedArguments[index]] = param;
      }
      return params;
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
    Controller.resources = function(base_url) {};
    Controller.prototype.dispatch = function() {
      var filter, filters, key, params, result, route, _i, _len, _ref;
      route = arguments[0], params = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      key = Batman._findName(route, this);
      this._actedDuringAction = false;
      this._currentAction = key;
      filters = this.constructor._beforeFilters;
      if (filters) {
        for (_i = 0, _len = filters.length; _i < _len; _i++) {
          filter = filters[_i];
          filter.call(this);
        }
      }
      result = (_ref = route.action).call.apply(_ref, [this].concat(__slice.call(params)));
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
        return view.ready(function() {
          return Batman.DOM.contentFor('main', view.get('node'));
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
  # A few can function two ways: a mechanism to load and/or parse html files
  # or a root of a subclass hierarchy to create rich UI classes, like in Cocoa.
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
    View.prototype.ready = View.eventOneShot(function() {});
    View.prototype.prefix = 'views';
    View.prototype.observe('source', function() {
      return setTimeout(this.reloadSource, 0);
    });
    View.prototype.reloadSource = function() {
      var url;
      if (this.get('source') == null) {
        return;
      }
      url = "" + (this.get('prefix')) + "/" + (this.get('source'));
      return new Batman.Request({
        url: url,
        type: 'html',
        success: __bind(function(response) {
          return this.set('html', response);
        }, this),
        error: __bind(function(response) {
          return console.error("Error loading view from " + url + "!");
        }, this)
      });
    };
    View.prototype.observe('html', function(html) {
      var node;
      if (this.contentFor) {
        ;
      } else {
        node = this.get('node') || document.createElement('div');
        node.innerHTML = html;
        if (this.node !== node) {
          return this.set('node', node);
        }
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
        return this._renderer = new Batman.Renderer(node, __bind(function() {
          return this.ready();
        }, this));
      }
    });
    return View;
  })();
  /*
  # DOM Helpers
  */
  Batman.Renderer = (function() {
    var regexp;
    function Renderer(node, callback) {
      this.node = node;
      this.callback = callback;
      this.resume = __bind(this.resume, this);;
      this.start = __bind(this.start, this);;
      Renderer.__super__.constructor.apply(this, arguments);
      this.contexts = [window, Batman.currentApp, this.contextObject = new Batman.Object];
      setTimeout(this.start, 0);
    }
    __extends(Renderer, Batman.Object);
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
      return this.callback();
    };
    Renderer.prototype.forgetAll = function() {};
    regexp = /data\-(.*)/;
    Renderer.prototype.parseNode = function(node) {
      var attr, contexts, index, name, nextNode, _base, _base2, _i, _len, _name, _ref, _ref2;
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
          if ((index = name.indexOf('-')) === -1) {
            if (typeof (_base = Batman.DOM.readers)[name] === "function") {
              _base[name](node, attr.value, contexts);
            }
          } else {
            if (typeof (_base2 = Batman.DOM.attrReaders)[_name = name.substr(0, index)] === "function") {
              _base2[_name](node, name.substr(index + 1), attr.value, contexts);
            }
          }
        }
      }
      if ((nextNode = this.nextNode(node))) {
        return this.parseNode(nextNode);
      } else {
        return this.finish();
      }
    };
    Renderer.prototype.nextNode = function(node) {
      var children, nextParent, parentSibling, sibling;
      children = node.childNodes;
      if (children != null ? children.length : void 0) {
        return children[0];
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
      if (context.get(base) != null) {
        return context;
      }
    }
    return null;
  };
  Batman.DOM = {
    readers: {
      bind: function(node, key, contexts) {
        var context, observer, shouldSet;
        context = matchContext(contexts, key);
        shouldSet = true;
        if (Batman.DOM.nodeIsEditable(node)) {
          Batman.DOM.events.change(node, function() {
            shouldSet = false;
            context.set(key, node.value);
            return shouldSet = true;
          });
        }
        return context != null ? context.observe(key, true, observer = function(value) {
          if (shouldSet) {
            return Batman.DOM.valueForNode(node, value);
          }
        }) : void 0;
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
      showif: function(node, key, contexts, invert) {
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
        var route, routeName;
        if (key.substr(0, 1) === '/') {
          route = Batman.redirect.bind(Batman, key);
          routeName = key;
        } else {
          route = matchContext(contexts, key);
          routeName = route.path;
        }
        switch (node.nodeName.toUpperCase()) {
          case 'A':
            node.href = Batman.HASH_PATTERN + routeName;
        }
        return Batman.DOM.events.click(node, route);
      },
      yield: function(node, key, contexts) {
        return Batman.DOM.yield(key, node);
      },
      contentfor: function(node, key, contexts) {
        return Batman.DOM.contentFor(key, node);
      }
    },
    attrReaders: {
      bind: function(node, attr, key, contexts) {
        var context;
        context = matchContext(contexts, key);
        return context != null ? context.observe(key, true, function(value) {
          return node[attr] = value;
        }) : void 0;
      },
      event: function(node, eventName, key, contexts) {
        var callback, context;
        context = matchContext(contexts, key);
        callback = context.get(key);
        return Batman.DOM.events[eventName](node, callback);
      },
      addclass: function(node, className, key, contexts, invert) {
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
      foreach: function(node, iteratorName, key, contexts) {
        var context;
        context = matchContext(contexts, key);
        return context;
      }
    },
    events: {
      click: function(node, callback) {
        return Batman.DOM.addEventListener(node, 'click', function(e) {
          callback(this, arguments);
          return e.preventDefault();
        });
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
  /*
  # Helpers
  # Just a few random Rails-style string helpers. You can add more
  # to the Batman.helpers object.
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
  # Mixins
  */
  mixins = Batman.mixins = {};
  global = typeof exports !== "undefined" && exports !== null ? exports : this;
  global.Batman = Batman;
  $mixin(global, Batman.Observable);
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

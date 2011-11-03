(function() {
  var $addEventListener, $appendChild, $block, $clearImmediate, $extendsEnumerable, $findName, $functionName, $get, $hasAddEventListener, $isChildOf, $mixin, $onParseExit, $passError, $preventDefault, $redirect, $removeEventListener, $removeNode, $setImmediate, $setInnerHTML, $trackBinding, $typeOf, $unbindNode, $unbindTree, $unmixin, Batman, BatmanObject, Validators, buntUndefined, camelize_rx, capitalize_rx, container, developer, div, filters, helpers, isEmptyDataObject, k, mixins, t, underscore_rx1, underscore_rx2, _Batman, _i, _implementImmediates, _len, _objectToString, _ref;
  var __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty, __indexOf = Array.prototype.indexOf || function(item) {
    for (var i = 0, l = this.length; i < l; i++) {
      if (this[i] === item) return i;
    }
    return -1;
  }, __extends = function(child, parent) {
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
  Batman.config = {
    pathPrefix: '/',
    usePushState: false
  };
  Batman.typeOf = $typeOf = function(object) {
    if (typeof object === 'undefined') {
      return "Undefined";
    }
    return _objectToString.call(object).slice(8, -1);
  };
  _objectToString = Object.prototype.toString;
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
        } else if (to.nodeName != null) {
          Batman.data(to, key, value);
        } else {
          to[key] = value;
        }
      }
      if (typeof mixin.initialize === 'function') {
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
        if (key === 'initialize' || key === 'uninitialize') {
          continue;
        }
        delete from[key];
      }
      if (typeof mixin.uninitialize === 'function') {
        mixin.uninitialize.call(from);
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
  Batman._functionName = $functionName = function(f) {
    var _ref;
    if (f.__name__) {
      return f.__name__;
    }
    if (f.name) {
      return f.name;
    }
    return (_ref = f.toString().match(/\W*function\s+([\w\$]+)\(/)) != null ? _ref[1] : void 0;
  };
  Batman._preventDefault = $preventDefault = function(e) {
    if (typeof e.preventDefault === "function") {
      return e.preventDefault();
    } else {
      return e.returnValue = false;
    }
  };
  Batman._isChildOf = $isChildOf = function(parentNode, childNode) {
    var node;
    node = childNode.parentNode;
    while (node) {
      if (node === parentNode) {
        return true;
      }
      node = node.parentNode;
    }
    return false;
  };
  _implementImmediates = function() {
    var $clearImmediate, $setImmediate, canUsePostMessage, count, functions, getHandle, handler, prefix, tasks;
    canUsePostMessage = function() {
      var async, oldMessage;
      if (!container.postMessage) {
        return false;
      }
      async = true;
      oldMessage = container.onmessage;
      container.onmessage = function() {
        return async = false;
      };
      container.postMessage("", "*");
      container.onmessage = oldMessage;
      return async;
    };
    tasks = new Batman.SimpleHash;
    count = 0;
    getHandle = function() {
      return "go" + (++count);
    };
    if (container.setImmediate) {
      $setImmediate = container.setImmediate;
      $clearImmediate = container.clearImmediate;
    } else if (container.msSetImmediate) {
      $setImmediate = msSetImmediate;
      $clearImmediate = msClearImmediate;
    } else if (canUsePostMessage()) {
      prefix = 'com.batman.';
      functions = new Batman.SimpleHash;
      handler = function(e) {
        var handle, _base;
        if (!~e.data.search(prefix)) {
          return;
        }
        handle = e.data.substring(prefix.length);
        return typeof (_base = tasks.unset(handle)) === "function" ? _base() : void 0;
      };
      if (container.addEventListener) {
        container.addEventListener('message', handler, false);
      } else {
        container.attachEvent('onmessage', handler);
      }
      $setImmediate = function(f) {
        var handle;
        tasks.set(handle = getHandle(), f);
        container.postMessage(prefix + handle, "*");
        return handle;
      };
      $clearImmediate = function(handle) {
        return tasks.unset(handle);
      };
    } else if (typeof document !== 'undefined' && __indexOf.call(document.createElement("script"), "onreadystatechange") >= 0) {
      $setImmediate = function(f) {
        var handle, script;
        handle = getHandle();
        script = document.createElement("script");
        script.onreadystatechange = function() {
          var _base;
          if (typeof (_base = tasks.get(handle)) === "function") {
            _base();
          }
          script.onreadystatechange = null;
          script.parentNode.removeChild(script);
          return script = null;
        };
        document.documentElement.appendChild(script);
        return handle;
      };
      $clearImmediate = function(handle) {
        return tasks.unset(handle);
      };
    } else {
      $setImmediate = function(f) {
        return setTimeout(f, 0);
      };
      $clearImmediate = function(handle) {
        return clearTimeout(handle);
      };
    }
    Batman.setImmediate = $setImmediate;
    return Batman.clearImmediate = $clearImmediate;
  };
  Batman.setImmediate = $setImmediate = function() {
    _implementImmediates();
    return Batman.setImmediate.apply(this, arguments);
  };
  Batman.clearImmediate = $clearImmediate = function() {
    _implementImmediates();
    return Batman.clearImmediate.apply(this, arguments);
  };
  Batman.translate = function(x, values) {
    if (values == null) {
      values = {};
    }
    return helpers.interpolate($get(Batman.translate.messages, x), values);
  };
  Batman.translate.messages = {};
  t = function() {
    return Batman.translate.apply(Batman, arguments);
  };
  developer = {
    suppressed: false,
    DevelopmentError: (function() {
      var DevelopmentError;
      DevelopmentError = function(message) {
        this.message = message;
        return this.name = "DevelopmentError";
      };
      DevelopmentError.prototype = Error.prototype;
      return DevelopmentError;
    })(),
    _ie_console: function(f, args) {
      var arg, _i, _len, _results;
      if (args.length !== 1) {
        if (typeof console !== "undefined" && console !== null) {
          console[f]("..." + f + " of " + args.length + " items...");
        }
      }
      _results = [];
      for (_i = 0, _len = args.length; _i < _len; _i++) {
        arg = args[_i];
        _results.push(typeof console !== "undefined" && console !== null ? console[f](arg) : void 0);
      }
      return _results;
    },
    suppress: function(f) {
      developer.suppressed = true;
      if (f) {
        f();
        return developer.suppressed = false;
      }
    },
    unsuppress: function() {
      return developer.suppressed = false;
    },
    log: function() {
      if (developer.suppressed || !((typeof console !== "undefined" && console !== null ? console.log : void 0) != null)) {
        return;
      }
      if (console.log.apply) {
        return console.log.apply(console, arguments);
      } else {
        return developer._ie_console("log", arguments);
      }
    },
    warn: function() {
      if (developer.suppressed || !((typeof console !== "undefined" && console !== null ? console.warn : void 0) != null)) {
        return;
      }
      if (console.warn.apply) {
        return console.warn.apply(console, arguments);
      } else {
        return developer._ie_console("warn", arguments);
      }
    },
    error: function(message) {
      throw new developer.DevelopmentError(message);
    },
    assert: function(result, message) {
      if (!result) {
        return developer.error(message);
      }
    },
    "do": function(f) {
      return f();
    },
    addFilters: function() {
      return $mixin(Batman.Filters, {
        log: function(value, key) {
          if (typeof console !== "undefined" && console !== null) {
            if (typeof console.log === "function") {
              console.log(arguments);
            }
          }
          return value;
        },
        logStack: function(value) {
          if (typeof console !== "undefined" && console !== null) {
            if (typeof console.log === "function") {
              console.log(developer.currentFilterStack);
            }
          }
          return value;
        }
      });
    }
  };
  Batman.developer = developer;
  developer.assert((function() {}).bind, "Error! Batman needs Function.bind to work! Please shim it using something like es5-shim or augmentjs!");
  camelize_rx = /(?:^|_|\-)(.)/g;
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
      var len;
      len = string.length;
      if (string.substr(len - 3) === 'ies') {
        return string.substr(0, len - 3) + 'y';
      } else if (string.substr(len - 1) === 's') {
        return string.substr(0, len - 1);
      } else {
        return string;
      }
    },
    pluralize: function(count, string) {
      var lastLetter, len;
      if (string) {
        if (count === 1) {
          return string;
        }
      } else {
        string = count;
      }
      len = string.length;
      lastLetter = string.substr(len - 1);
      if (lastLetter === 'y') {
        return "" + (string.substr(0, len - 1)) + "ies";
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
    },
    trim: function(string) {
      if (string) {
        return string.trim();
      } else {
        return "";
      }
    },
    interpolate: function(stringOrObject, keys) {
      var key, string, value;
      if (typeof stringOrObject === 'object') {
        string = stringOrObject[keys.count];
        if (!string) {
          string = stringOrObject['other'];
        }
      } else {
        string = stringOrObject;
      }
      for (key in keys) {
        value = keys[key];
        string = string.replace(new RegExp("%\\{" + key + "\\}", "g"), value);
      }
      return string;
    }
  };
  Batman.Event = (function() {
    Event.forBaseAndKey = function(base, key) {
      if (base.isEventEmitter) {
        return base.event(key);
      } else {
        return new Batman.Event(base, key);
      }
    };
    function Event(base, key) {
      this.base = base;
      this.key = key;
      this.handlers = new Batman.SimpleSet;
      this._preventCount = 0;
    }
    Event.prototype.isEvent = true;
    Event.prototype.isEqual = function(other) {
      return this.constructor === other.constructor && this.base === other.base && this.key === other.key;
    };
    Event.prototype.hashKey = function() {
      var key;
      this.hashKey = function() {
        return key;
      };
      return key = "<Batman.Event base: " + (Batman.Hash.prototype.hashKeyFor(this.base)) + ", key: \"" + (Batman.Hash.prototype.hashKeyFor(this.key)) + "\">";
    };
    Event.prototype.addHandler = function(handler) {
      this.handlers.add(handler);
      if (this.oneShot) {
        this.autofireHandler(handler);
      }
      return this;
    };
    Event.prototype.removeHandler = function(handler) {
      this.handlers.remove(handler);
      return this;
    };
    Event.prototype.eachHandler = function(iterator) {
      var key, _ref;
      this.handlers.forEach(iterator);
      if ((_ref = this.base) != null ? _ref.isEventEmitter : void 0) {
        key = this.key;
        return this.base._batman.ancestors(function(ancestor) {
          var handlers;
          if (ancestor.isEventEmitter && ancestor.hasEvent(key)) {
            handlers = ancestor.event(key).handlers;
            return handlers.forEach(iterator);
          }
        });
      }
    };
    Event.prototype.handlerContext = function() {
      return this.base;
    };
    Event.prototype.prevent = function() {
      return ++this._preventCount;
    };
    Event.prototype.allow = function() {
      if (this._preventCount) {
        --this._preventCount;
      }
      return this._preventCount;
    };
    Event.prototype.isPrevented = function() {
      return this._preventCount > 0;
    };
    Event.prototype.autofireHandler = function(handler) {
      if (this._oneShotFired && (this._oneShotArgs != null)) {
        return handler.apply(this.handlerContext(), this._oneShotArgs);
      }
    };
    Event.prototype.resetOneShot = function() {
      this._oneShotFired = false;
      return this._oneShotArgs = null;
    };
    Event.prototype.fire = function() {
      var args, context;
      if (this.isPrevented() || this._oneShotFired) {
        return false;
      }
      context = this.handlerContext();
      args = arguments;
      if (this.oneShot) {
        this._oneShotFired = true;
        this._oneShotArgs = arguments;
      }
      return this.eachHandler(function(handler) {
        return handler.apply(context, args);
      });
    };
    Event.prototype.allowAndFire = function() {
      this.allow();
      return this.fire.apply(this, arguments);
    };
    return Event;
  })();
  Batman.EventEmitter = {
    isEventEmitter: true,
    hasEvent: function(key) {
      var _ref, _ref2;
      return (_ref = this._batman) != null ? typeof _ref.get === "function" ? (_ref2 = _ref.get('events')) != null ? _ref2.hasKey(key) : void 0 : void 0 : void 0;
    },
    event: function(key) {
      var eventClass, events, existingEvent, existingEvents, newEvent, _base, _ref;
      Batman.initializeObject(this);
      eventClass = this.eventClass || Batman.Event;
      events = (_base = this._batman).events || (_base.events = new Batman.SimpleHash);
      if (events.hasKey(key)) {
        return existingEvent = events.get(key);
      } else {
        existingEvents = this._batman.get('events');
        newEvent = events.set(key, new eventClass(this, key));
        newEvent.oneShot = existingEvents != null ? (_ref = existingEvents.get(key)) != null ? _ref.oneShot : void 0 : void 0;
        return newEvent;
      }
    },
    on: function(key, handler) {
      return this.event(key).addHandler(handler);
    },
    registerAsMutableSource: function() {
      return Batman.Property.registerSource(this);
    },
    mutation: function(wrappedFunction) {
      return function() {
        var result;
        result = wrappedFunction.apply(this, arguments);
        this.event('change').fire(this, this);
        return result;
      };
    },
    prevent: function(key) {
      this.event(key).prevent();
      return this;
    },
    allow: function(key) {
      this.event(key).allow();
      return this;
    },
    isPrevented: function(key) {
      return this.event(key).isPrevented();
    },
    fire: function() {
      var args, key, _ref;
      key = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return (_ref = this.event(key)).fire.apply(_ref, args);
    },
    allowAndFire: function() {
      var args, key, _ref;
      key = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      return (_ref = this.event(key)).allowAndFire.apply(_ref, args);
    }
  };
  Batman.PropertyEvent = (function() {
    __extends(PropertyEvent, Batman.Event);
    function PropertyEvent() {
      PropertyEvent.__super__.constructor.apply(this, arguments);
    }
    PropertyEvent.prototype.eachHandler = function(iterator) {
      return this.base.eachObserver(iterator);
    };
    PropertyEvent.prototype.handlerContext = function() {
      return this.base.base;
    };
    return PropertyEvent;
  })();
  Batman.Property = (function() {
    $mixin(Property.prototype, Batman.EventEmitter);
    Property._sourceTrackerStack = [];
    Property.sourceTracker = function() {
      var stack;
      return (stack = this._sourceTrackerStack)[stack.length - 1];
    };
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
    Property.forBaseAndKey = function(base, key) {
      if (base.isObservable) {
        return base.property(key);
      } else {
        return new Batman.Keypath(base, key);
      }
    };
    Property.registerSource = function(obj) {
      var _ref;
      if (!obj.isEventEmitter) {
        return;
      }
      return (_ref = this.sourceTracker()) != null ? _ref.add(obj) : void 0;
    };
    function Property(base, key) {
      this.base = base;
      this.key = key;
    }
    Property.prototype._isolationCount = 0;
    Property.prototype.cached = false;
    Property.prototype.value = null;
    Property.prototype.sources = null;
    Property.prototype.isProperty = true;
    Property.prototype.eventClass = Batman.PropertyEvent;
    Property.prototype.isEqual = function(other) {
      return this.constructor === other.constructor && this.base === other.base && this.key === other.key;
    };
    Property.prototype.hashKey = function() {
      var key;
      this.hashKey = function() {
        return key;
      };
      return key = "<Batman.Property base: " + (Batman.Hash.prototype.hashKeyFor(this.base)) + ", key: \"" + (Batman.Hash.prototype.hashKeyFor(this.key)) + "\">";
    };
    Property.prototype.changeEvent = function() {
      var event;
      event = this.event('change');
      this.changeEvent = function() {
        return event;
      };
      return event;
    };
    Property.prototype.accessor = function() {
      var accessor, keyAccessors, val, _ref, _ref2;
      keyAccessors = (_ref = this.base._batman) != null ? _ref.get('keyAccessors') : void 0;
      accessor = keyAccessors && (val = keyAccessors.get(this.key)) ? val : ((_ref2 = this.base._batman) != null ? _ref2.getFirst('defaultAccessor') : void 0) || Batman.Property.defaultAccessor;
      this.accessor = function() {
        return accessor;
      };
      return accessor;
    };
    Property.prototype.eachObserver = function(iterator) {
      var key;
      key = this.key;
      this.changeEvent().handlers.forEach(iterator);
      if (this.base.isObservable) {
        return this.base._batman.ancestors(function(ancestor) {
          var handlers, property;
          if (ancestor.isObservable && ancestor.hasProperty(key)) {
            property = ancestor.property(key);
            handlers = property.event('change').handlers;
            return handlers.forEach(iterator);
          }
        });
      }
    };
    Property.prototype.pushSourceTracker = function() {
      return Batman.Property._sourceTrackerStack.push(new Batman.SimpleSet);
    };
    Property.prototype.pushDummySourceTracker = function() {
      return Batman.Property._sourceTrackerStack.push(null);
    };
    Property.prototype.popSourceTracker = function() {
      return Batman.Property._sourceTrackerStack.pop();
    };
    Property.prototype.updateSourcesFromTracker = function() {
      var handler, newSources;
      newSources = this.popSourceTracker();
      handler = this.sourceChangeHandler();
      this._eachSourceChangeEvent(function(e) {
        return e.removeHandler(handler);
      });
      this.sources = newSources;
      return this._eachSourceChangeEvent(function(e) {
        return e.addHandler(handler);
      });
    };
    Property.prototype._eachSourceChangeEvent = function(iterator) {
      if (this.sources == null) {
        return;
      }
      return this.sources.forEach(function(source) {
        return iterator(source.event('change'));
      });
    };
    Property.prototype.getValue = function() {
      this.registerAsMutableSource();
      if (!this.cached) {
        this.pushSourceTracker();
        this.value = this.valueFromAccessor();
        this.cached = true;
        this.updateSourcesFromTracker();
      }
      return this.value;
    };
    Property.prototype.refresh = function() {
      var previousValue, value;
      this.cached = false;
      previousValue = this.value;
      value = this.getValue();
      if (value !== previousValue && !this.isIsolated()) {
        return this.fire(value, previousValue);
      }
    };
    Property.prototype.sourceChangeHandler = function() {
      var handler;
      handler = __bind(function() {
        return this._handleSourceChange();
      }, this);
      this.sourceChangeHandler = function() {
        return handler;
      };
      return handler;
    };
    Property.prototype._handleSourceChange = function() {
      if (this.isIsolated()) {
        return this._needsRefresh = true;
      } else if (this.changeEvent().handlers.isEmpty()) {
        return this.cached = false;
      } else {
        return this.refresh();
      }
    };
    Property.prototype.valueFromAccessor = function() {
      var _ref;
      return (_ref = this.accessor().get) != null ? _ref.call(this.base, this.key) : void 0;
    };
    Property.prototype.setValue = function(val) {
      var result, _ref;
      this.pushDummySourceTracker();
      this.cached = false;
      result = (_ref = this.accessor().set) != null ? _ref.call(this.base, this.key, val) : void 0;
      this.refresh();
      this.popSourceTracker();
      return result;
    };
    Property.prototype.unsetValue = function() {
      var result, _ref, _ref2, _ref3, _ref4;
      this.pushDummySourceTracker();
      result = (_ref = this.accessor().unset) != null ? _ref.call(this.base, this.key) : void 0;
      this.refresh();
      this.popSourceTracker();
      if ((!(this.sources != null) || this.sources.length === 0) && ((_ref2 = this.changeEvent().handlers) != null ? _ref2.length : void 0) === 0) {
        if ((_ref3 = this.base._batman) != null) {
          if ((_ref4 = _ref3.properties) != null) {
            _ref4.unset(this.key);
          }
        }
      }
      return result;
    };
    Property.prototype.forget = function(handler) {
      if (handler != null) {
        return this.changeEvent().removeHandler(handler);
      } else {
        return this.changeEvent().handlers.clear();
      }
    };
    Property.prototype.observeAndFire = function(handler) {
      this.observe(handler);
      return handler.call(this.base, this.value, this.value);
    };
    Property.prototype.observe = function(handler) {
      this.changeEvent().addHandler(handler);
      this.getValue();
      return this;
    };
    Property.prototype.removeSourceHandlers = function() {
      var handler;
      handler = this.sourceChangeHandler();
      this._eachSourceChangeEvent(function(e) {
        return e.removeHandler(handler);
      });
      return this.forget();
    };
    Property.prototype.fire = function() {
      var _ref;
      return (_ref = this.changeEvent()).fire.apply(_ref, arguments);
    };
    Property.prototype.isolate = function() {
      if (this._isolationCount === 0) {
        this._preIsolationValue = this.getValue();
      }
      return this._isolationCount++;
    };
    Property.prototype.expose = function() {
      if (this._isolationCount === 1) {
        this._isolationCount--;
        if (this._needsRefresh) {
          this.value = this._preIsolationValue;
          this.refresh();
        } else if (this.value !== this._preIsolationValue) {
          this.fire(this.value, this._preIsolationValue);
        }
        return this._preIsolationValue = null;
      } else if (this._isolationCount > 0) {
        return this._isolationCount--;
      }
    };
    Property.prototype.isIsolated = function() {
      return this._isolationCount > 0;
    };
    return Property;
  })();
  Batman.Keypath = (function() {
    __extends(Keypath, Batman.Property);
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
      if (end == null) {
        end = this.depth;
      }
      base = this.base;
      _ref = this.segments.slice(0, begin);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        segment = _ref[_i];
        if (!((base != null) && (base = Batman.Property.forBaseAndKey(base, segment).getValue()))) {
          return;
        }
      }
      return Batman.Property.forBaseAndKey(base, this.segments.slice(begin, end).join('.'));
    };
    Keypath.prototype.terminalProperty = function() {
      return this.slice(-1);
    };
    Keypath.prototype.valueFromAccessor = function() {
      var _ref;
      if (this.depth === 1) {
        return Keypath.__super__.valueFromAccessor.apply(this, arguments);
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
    hasProperty: function(key) {
      var _ref, _ref2;
      return (_ref = this._batman) != null ? (_ref2 = _ref.properties) != null ? typeof _ref2.hasKey === "function" ? _ref2.hasKey(key) : void 0 : void 0 : void 0;
    },
    property: function(key) {
      var properties, propertyClass, _base;
      Batman.initializeObject(this);
      propertyClass = this.propertyClass || Batman.Keypath;
      properties = (_base = this._batman).properties || (_base.properties = new Batman.SimpleHash);
      return properties.get(key) || properties.set(key, new propertyClass(this, key));
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
    getOrSet: function(key, valueFunction) {
      var currentValue;
      currentValue = this.get(key);
      if (!currentValue) {
        currentValue = valueFunction();
        this.set(key, currentValue);
      }
      return currentValue;
    },
    forget: function(key, observer) {
      var _ref;
      if (key) {
        this.property(key).forget(observer);
      } else {
        if ((_ref = this._batman.properties) != null) {
          _ref.forEach(function(key, property) {
            return property.forget();
          });
        }
      }
      return this;
    },
    observe: function() {
      var args, key, _ref;
      key = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      (_ref = this.property(key)).observe.apply(_ref, args);
      return this;
    },
    observeAndFire: function() {
      var args, key, _ref;
      key = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      (_ref = this.property(key)).observeAndFire.apply(_ref, args);
      return this;
    }
  };
  $get = Batman.get = function(base, key) {
    if ((base.get != null) && typeof base.get === 'function') {
      return base.get(key);
    } else {
      return Batman.Property.forBaseAndKey(base, key).getValue();
    }
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
        object._batman = new _Batman(object);
        return false;
      }
      return true;
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
          var _ref;
          return (_ref = ancestor._batman) != null ? _ref[keyOrGetter] : void 0;
        };
      }
      results = this.ancestors(getter);
      if (val = getter(this.object)) {
        results.unshift(val);
      }
      return results;
    };
    _Batman.prototype.ancestors = function(getter) {
      var isClass, parent, proto, results, val, _ref;
      if (getter == null) {
        getter = function(x) {
          return x;
        };
      }
      results = [];
      isClass = !!this.object.prototype;
      parent = isClass ? (_ref = this.object.__super__) != null ? _ref.constructor : void 0 : (proto = Object.getPrototypeOf(this.object)) === this.object ? this.object.constructor.__super__ : proto;
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
  BatmanObject = (function() {
    var counter, getAccessorObject;
    Batman.initializeObject(BatmanObject);
    Batman.initializeObject(BatmanObject.prototype);
    BatmanObject.global = function(isGlobal) {
      if (isGlobal === false) {
        return;
      }
      return container[$functionName(this)] = this;
    };
    BatmanObject.classMixin = function() {
      return $mixin.apply(null, [this].concat(__slice.call(arguments)));
    };
    BatmanObject.mixin = function() {
      return this.classMixin.apply(this.prototype, arguments);
    };
    BatmanObject.prototype.mixin = BatmanObject.classMixin;
    counter = 0;
    BatmanObject.prototype._objectID = function() {
      var c;
      this._objectID = function() {
        return c;
      };
      return c = counter++;
    };
    BatmanObject.prototype.hashKey = function() {
      var key;
      if (typeof this.isEqual === 'function') {
        return;
      }
      this.hashKey = function() {
        return key;
      };
      return key = "<Batman.Object " + (this._objectID()) + ">";
    };
    BatmanObject.prototype.toJSON = function() {
      var key, obj, value;
      obj = {};
      for (key in this) {
        if (!__hasProp.call(this, key)) continue;
        value = this[key];
        if (key !== "_batman" && key !== "hashKey" && key !== "_objectID") {
          obj[key] = value.toJSON ? value.toJSON() : value;
        }
      }
      return obj;
    };
    getAccessorObject = function(accessor) {
      if (!accessor.get && !accessor.set && !accessor.unset) {
        accessor = {
          get: accessor
        };
      }
      return accessor;
    };
    BatmanObject.classAccessor = function() {
      var accessor, key, keys, _base, _i, _j, _len, _results;
      keys = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), accessor = arguments[_i++];
      Batman.initializeObject(this);
      if (keys.length === 0) {
        return this._batman.defaultAccessor = getAccessorObject(accessor);
      } else {
        (_base = this._batman).keyAccessors || (_base.keyAccessors = new Batman.SimpleHash);
        _results = [];
        for (_j = 0, _len = keys.length; _j < _len; _j++) {
          key = keys[_j];
          _results.push(this._batman.keyAccessors.set(key, getAccessorObject(accessor)));
        }
        return _results;
      }
    };
    BatmanObject.accessor = function() {
      return this.classAccessor.apply(this.prototype, arguments);
    };
    BatmanObject.prototype.accessor = BatmanObject.classAccessor;
    function BatmanObject() {
      var mixins;
      mixins = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      this._batman = new _Batman(this);
      this.mixin.apply(this, mixins);
    }
    BatmanObject.classMixin(Batman.EventEmitter, Batman.Observable);
    BatmanObject.mixin(Batman.EventEmitter, Batman.Observable);
    BatmanObject.observeAll = function() {
      return this.prototype.observe.apply(this.prototype, arguments);
    };
    BatmanObject.singleton = function(singletonMethodName) {
      if (singletonMethodName == null) {
        singletonMethodName = "sharedInstance";
      }
      return this.classAccessor(singletonMethodName, {
        get: function() {
          var _name;
          return this[_name = "_" + singletonMethodName] || (this[_name] = new this);
        }
      });
    };
    return BatmanObject;
  })();
  Batman.Object = BatmanObject;
  Batman.Accessible = (function() {
    __extends(Accessible, Batman.Object);
    function Accessible() {
      this.accessor.apply(this, arguments);
    }
    return Accessible;
  })();
  Batman.TerminalAccessible = (function() {
    __extends(TerminalAccessible, Batman.Accessible);
    function TerminalAccessible() {
      TerminalAccessible.__super__.constructor.apply(this, arguments);
    }
    TerminalAccessible.prototype.propertyClass = Batman.Property;
    return TerminalAccessible;
  })();
  Batman.Enumerable = {
    isEnumerable: true,
    map: function(f, ctx) {
      var r;
      if (ctx == null) {
        ctx = container;
      }
      r = [];
      this.forEach(function() {
        return r.push(f.apply(ctx, arguments));
      });
      return r;
    },
    every: function(f, ctx) {
      var r;
      if (ctx == null) {
        ctx = container;
      }
      r = true;
      this.forEach(function() {
        return r = r && f.apply(ctx, arguments);
      });
      return r;
    },
    some: function(f, ctx) {
      var r;
      if (ctx == null) {
        ctx = container;
      }
      r = false;
      this.forEach(function() {
        return r = r || f.apply(ctx, arguments);
      });
      return r;
    },
    reduce: function(f, r) {
      var count, self;
      count = 0;
      self = this;
      this.forEach(function() {
        if (r != null) {
          return r = f.apply(null, [r].concat(__slice.call(arguments), [count], [self]));
        } else {
          return r = arguments[0];
        }
      });
      return r;
    },
    filter: function(f) {
      var r, wrap;
      r = new this.constructor;
      if (r.add) {
        wrap = function(r, e) {
          if (f(e)) {
            r.add(e);
          }
          return r;
        };
      } else if (r.set) {
        wrap = function(r, k, v) {
          if (f(k, v)) {
            r.set(k, v);
          }
          return r;
        };
      } else {
        if (!r.push) {
          r = [];
        }
        wrap = function(r, e) {
          if (f(e)) {
            r.push(e);
          }
          return r;
        };
      }
      return this.reduce(wrap, r);
    }
  };
  $extendsEnumerable = function(onto) {
    var k, v, _ref, _results;
    _ref = Batman.Enumerable;
    _results = [];
    for (k in _ref) {
      v = _ref[k];
      _results.push(onto[k] = v);
    }
    return _results;
  };
  Batman.SimpleHash = (function() {
    function SimpleHash() {
      this._storage = {};
      this.length = 0;
    }
    $extendsEnumerable(SimpleHash.prototype);
    SimpleHash.prototype.propertyClass = Batman.Property;
    SimpleHash.prototype.hasKey = function(key) {
      var pair, pairs, _i, _len;
      if (pairs = this._storage[this.hashKeyFor(key)]) {
        for (_i = 0, _len = pairs.length; _i < _len; _i++) {
          pair = pairs[_i];
          if (this.equality(pair[0], key)) {
            return true;
          }
        }
      }
      return false;
    };
    SimpleHash.prototype.get = function(key) {
      var pair, pairs, _i, _len;
      if (pairs = this._storage[this.hashKeyFor(key)]) {
        for (_i = 0, _len = pairs.length; _i < _len; _i++) {
          pair = pairs[_i];
          if (this.equality(pair[0], key)) {
            return pair[1];
          }
        }
      }
    };
    SimpleHash.prototype.set = function(key, val) {
      var pair, pairs, _base, _i, _len, _name;
      pairs = (_base = this._storage)[_name = this.hashKeyFor(key)] || (_base[_name] = []);
      for (_i = 0, _len = pairs.length; _i < _len; _i++) {
        pair = pairs[_i];
        if (this.equality(pair[0], key)) {
          return pair[1] = val;
        }
      }
      this.length++;
      pairs.push([key, val]);
      return val;
    };
    SimpleHash.prototype.unset = function(key) {
      var hashKey, index, obj, pair, pairs, value, _len, _ref;
      hashKey = this.hashKeyFor(key);
      if (pairs = this._storage[hashKey]) {
        for (index = 0, _len = pairs.length; index < _len; index++) {
          _ref = pairs[index], obj = _ref[0], value = _ref[1];
          if (this.equality(obj, key)) {
            pair = pairs.splice(index, 1);
            if (!pairs.length) {
              delete this._storage[hashKey];
            }
            this.length--;
            return pair[0][1];
          }
        }
      }
    };
    SimpleHash.prototype.getOrSet = Batman.Observable.getOrSet;
    SimpleHash.prototype.hashKeyFor = function(obj) {
      return (obj != null ? typeof obj.hashKey === "function" ? obj.hashKey() : void 0 : void 0) || obj;
    };
    SimpleHash.prototype.equality = function(lhs, rhs) {
      if (lhs === rhs) {
        return true;
      }
      if (lhs !== lhs && rhs !== rhs) {
        return true;
      }
      if ((lhs != null ? typeof lhs.isEqual === "function" ? lhs.isEqual(rhs) : void 0 : void 0) && (rhs != null ? typeof rhs.isEqual === "function" ? rhs.isEqual(lhs) : void 0 : void 0)) {
        return true;
      }
      return false;
    };
    SimpleHash.prototype.forEach = function(iterator) {
      var key, obj, value, values, _ref, _results;
      _ref = this._storage;
      _results = [];
      for (key in _ref) {
        values = _ref[key];
        _results.push((function() {
          var _i, _len, _ref2, _ref3, _results2;
          _ref2 = values.slice();
          _results2 = [];
          for (_i = 0, _len = _ref2.length; _i < _len; _i++) {
            _ref3 = _ref2[_i], obj = _ref3[0], value = _ref3[1];
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
      Batman.SimpleHash.prototype.forEach.call(this, function(key) {
        return result.push(key);
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
      var hash, merged, others, _i, _len;
      others = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      merged = new this.constructor;
      others.unshift(this);
      for (_i = 0, _len = others.length; _i < _len; _i++) {
        hash = others[_i];
        hash.forEach(function(obj, value) {
          return merged.set(obj, value);
        });
      }
      return merged;
    };
    return SimpleHash;
  })();
  Batman.Hash = (function() {
    var k, proto, _fn, _i, _len, _ref;
    __extends(Hash, Batman.Object);
    function Hash() {
      var self;
      Batman.SimpleHash.apply(this, arguments);
      this.meta = new Batman.Object;
      self = this;
      this.meta.accessor('length', function() {
        self.registerAsMutableSource();
        return self.length;
      });
      this.meta.accessor('isEmpty', function() {
        return self.isEmpty();
      });
      this.meta.accessor('keys', function() {
        return self.keys();
      });
      Hash.__super__.constructor.apply(this, arguments);
    }
    $extendsEnumerable(Hash.prototype);
    Hash.prototype.propertyClass = Batman.Property;
    Hash.accessor({
      get: Batman.SimpleHash.prototype.get,
      set: Hash.mutation(function(key, value) {
        var result;
        result = Batman.SimpleHash.prototype.set.call(this, key, value);
        this.fire('itemsWereAdded', key);
        return result;
      }),
      unset: Hash.mutation(function(key) {
        var result;
        result = Batman.SimpleHash.prototype.unset.call(this, key);
        if (result != null) {
          this.fire('itemsWereRemoved', key);
        }
        return result;
      })
    });
    Hash.prototype.clear = Hash.mutation(function() {
      var keys, result;
      keys = this.meta.get('keys');
      this.forEach(__bind(function(k) {
        return this.unset(k);
      }, this));
      result = Batman.SimpleHash.prototype.clear.call(this);
      this.fire.apply(this, ['itemsWereRemoved'].concat(__slice.call(keys)));
      return result;
    });
    Hash.prototype.equality = Batman.SimpleHash.prototype.equality;
    Hash.prototype.hashKeyFor = Batman.SimpleHash.prototype.hashKeyFor;
    Hash.prototype.toJSON = function() {
      var obj;
      obj = {};
      this.keys().forEach(__bind(function(key) {
        var value;
        value = this.get(key);
        return obj[key] = value.toJSON ? value.toJSON() : value;
      }, this));
      return obj;
    };
    _ref = ['hasKey', 'forEach', 'isEmpty', 'keys', 'merge'];
    _fn = function(k) {
      return proto[k] = function() {
        this.registerAsMutableSource();
        return Batman.SimpleHash.prototype[k].apply(this, arguments);
      };
    };
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      k = _ref[_i];
      proto = Hash.prototype;
      _fn(k);
    }
    return Hash;
  })();
  Batman.SimpleSet = (function() {
    function SimpleSet() {
      this._storage = new Batman.SimpleHash;
      this._indexes = new Batman.SimpleHash;
      this._sorts = new Batman.SimpleHash;
      this.length = 0;
      if (arguments.length > 0) {
        this.add.apply(this, arguments);
      }
    }
    $extendsEnumerable(SimpleSet.prototype);
    SimpleSet.prototype.has = function(item) {
      return this._storage.hasKey(item);
    };
    SimpleSet.prototype.add = function() {
      var addedItems, item, items, _i, _len;
      items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      addedItems = [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        if (!this._storage.hasKey(item)) {
          this._storage.set(item, true);
          addedItems.push(item);
          this.length++;
        }
      }
      if (this.fire && addedItems.length !== 0) {
        this.fire('change', this, this);
        this.fire.apply(this, ['itemsWereAdded'].concat(__slice.call(addedItems)));
      }
      return addedItems;
    };
    SimpleSet.prototype.remove = function() {
      var item, items, removedItems, _i, _len;
      items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      removedItems = [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        if (this._storage.hasKey(item)) {
          this._storage.unset(item);
          removedItems.push(item);
          this.length--;
        }
      }
      if (this.fire && removedItems.length !== 0) {
        this.fire('change', this, this);
        this.fire.apply(this, ['itemsWereRemoved'].concat(__slice.call(removedItems)));
      }
      return removedItems;
    };
    SimpleSet.prototype.forEach = function(iterator) {
      return this._storage.forEach(function(key, value) {
        return iterator(key);
      });
    };
    SimpleSet.prototype.isEmpty = function() {
      return this.length === 0;
    };
    SimpleSet.prototype.clear = function() {
      var items;
      items = this.toArray();
      this._storage = new Batman.SimpleHash;
      this.length = 0;
      if (this.fire && items.length !== 0) {
        this.fire('change', this, this);
        this.fire.apply(this, ['itemsWereRemoved'].concat(__slice.call(items)));
      }
      return items;
    };
    SimpleSet.prototype.toArray = function() {
      return this._storage.keys();
    };
    SimpleSet.prototype.merge = function() {
      var merged, others, set, _i, _len;
      others = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      merged = new this.constructor;
      others.unshift(this);
      for (_i = 0, _len = others.length; _i < _len; _i++) {
        set = others[_i];
        set.forEach(function(v) {
          return merged.add(v);
        });
      }
      return merged;
    };
    SimpleSet.prototype.indexedBy = function(key) {
      return this._indexes.get(key) || this._indexes.set(key, new Batman.SetIndex(this, key));
    };
    SimpleSet.prototype.sortedBy = function(key, order) {
      var sortsForKey;
      if (order == null) {
        order = "asc";
      }
      order = order.toLowerCase() === "desc" ? "desc" : "asc";
      sortsForKey = this._sorts.get(key) || this._sorts.set(key, new Batman.Object);
      return sortsForKey.get(order) || sortsForKey.set(order, new Batman.SetSort(this, key, order));
    };
    return SimpleSet;
  })();
  Batman.Set = (function() {
    var k, proto, _fn, _i, _j, _len, _len2, _ref, _ref2;
    __extends(Set, Batman.Object);
    function Set() {
      Batman.SimpleSet.apply(this, arguments);
    }
    $extendsEnumerable(Set.prototype);
    _ref = ['add', 'remove', 'clear', 'indexedBy', 'sortedBy'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      k = _ref[_i];
      Set.prototype[k] = Batman.SimpleSet.prototype[k];
    }
    _ref2 = ['merge', 'forEach', 'toArray', 'isEmpty', 'has'];
    _fn = function(k) {
      return proto[k] = function() {
        this.registerAsMutableSource();
        return Batman.SimpleSet.prototype[k].apply(this, arguments);
      };
    };
    for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
      k = _ref2[_j];
      proto = Set.prototype;
      _fn(k);
    }
    Set.prototype.toJSON = Set.prototype.toArray;
    Set.accessor('indexedBy', function() {
      return new Batman.TerminalAccessible(__bind(function(key) {
        return this.indexedBy(key);
      }, this));
    });
    Set.accessor('sortedBy', function() {
      return new Batman.TerminalAccessible(__bind(function(key) {
        return this.sortedBy(key);
      }, this));
    });
    Set.accessor('sortedByDescending', function() {
      return new Batman.TerminalAccessible(__bind(function(key) {
        return this.sortedBy(key, 'desc');
      }, this));
    });
    Set.accessor('isEmpty', function() {
      return this.isEmpty();
    });
    Set.accessor('toArray', function() {
      return this.toArray();
    });
    Set.accessor('length', function() {
      this.registerAsMutableSource();
      return this.length;
    });
    return Set;
  })();
  Batman.SetObserver = (function() {
    __extends(SetObserver, Batman.Object);
    function SetObserver(base) {
      this.base = base;
      this._itemObservers = new Batman.SimpleHash;
      this._setObservers = new Batman.SimpleHash;
      this._setObservers.set("itemsWereAdded", __bind(function() {
        return this.fire.apply(this, ['itemsWereAdded'].concat(__slice.call(arguments)));
      }, this));
      this._setObservers.set("itemsWereRemoved", __bind(function() {
        return this.fire.apply(this, ['itemsWereRemoved'].concat(__slice.call(arguments)));
      }, this));
      this.on('itemsWereAdded', this.startObservingItems.bind(this));
      this.on('itemsWereRemoved', this.stopObservingItems.bind(this));
    }
    SetObserver.prototype.observedItemKeys = [];
    SetObserver.prototype.observerForItemAndKey = function(item, key) {};
    SetObserver.prototype._getOrSetObserverForItemAndKey = function(item, key) {
      return this._itemObservers.getOrSet(item, __bind(function() {
        var observersByKey;
        observersByKey = new Batman.SimpleHash;
        return observersByKey.getOrSet(key, __bind(function() {
          return this.observerForItemAndKey(item, key);
        }, this));
      }, this));
    };
    SetObserver.prototype.startObserving = function() {
      this._manageItemObservers("observe");
      return this._manageSetObservers("addHandler");
    };
    SetObserver.prototype.stopObserving = function() {
      this._manageItemObservers("forget");
      return this._manageSetObservers("removeHandler");
    };
    SetObserver.prototype.startObservingItems = function() {
      var item, items, _i, _len, _results;
      items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      _results = [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        _results.push(this._manageObserversForItem(item, "observe"));
      }
      return _results;
    };
    SetObserver.prototype.stopObservingItems = function() {
      var item, items, _i, _len, _results;
      items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      _results = [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        _results.push(this._manageObserversForItem(item, "forget"));
      }
      return _results;
    };
    SetObserver.prototype._manageObserversForItem = function(item, method) {
      var key, _i, _len, _ref;
      if (!item.isObservable) {
        return;
      }
      _ref = this.observedItemKeys;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        key = _ref[_i];
        item[method](key, this._getOrSetObserverForItemAndKey(item, key));
      }
      if (method === "forget") {
        return this._itemObservers.unset(item);
      }
    };
    SetObserver.prototype._manageItemObservers = function(method) {
      return this.base.forEach(__bind(function(item) {
        return this._manageObserversForItem(item, method);
      }, this));
    };
    SetObserver.prototype._manageSetObservers = function(method) {
      if (!this.base.isObservable) {
        return;
      }
      return this._setObservers.forEach(__bind(function(key, observer) {
        return this.base.event(key)[method](observer);
      }, this));
    };
    return SetObserver;
  })();
  Batman.SetProxy = (function() {
    var k, _fn, _fn2, _fn3, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3;
    __extends(SetProxy, Batman.Object);
    function SetProxy() {
      SetProxy.__super__.constructor.call(this);
      this.length = 0;
    }
    $extendsEnumerable(SetProxy.prototype);
    SetProxy.prototype.filter = function(f) {
      var r;
      r = new Batman.Set();
      return this.reduce((function(r, e) {
        if (f(e)) {
          r.add(e);
        }
        return r;
      }), r);
    };
    _ref = ['add', 'remove', 'clear'];
    _fn = __bind(function(k) {
      return this.prototype[k] = function() {
        var results, _ref2;
        results = (_ref2 = this.base)[k].apply(_ref2, arguments);
        this.length = this.set('length', this.base.get('length'));
        return results;
      };
    }, SetProxy);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      k = _ref[_i];
      _fn(k);
    }
    _ref2 = ['has', 'merge', 'toArray', 'isEmpty'];
    _fn2 = __bind(function(k) {
      return this.prototype[k] = function() {
        var _ref3;
        return (_ref3 = this.base)[k].apply(_ref3, arguments);
      };
    }, SetProxy);
    for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
      k = _ref2[_j];
      _fn2(k);
    }
    _ref3 = ['isEmpty', 'toArray'];
    _fn3 = __bind(function(k) {
      return this.accessor(k, function() {
        return this.base.get(k);
      });
    }, SetProxy);
    for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
      k = _ref3[_k];
      _fn3(k);
    }
    SetProxy.accessor('length', {
      get: function() {
        this.registerAsMutableSource();
        return this.length;
      },
      set: function(k, v) {
        return this.length = v;
      }
    });
    return SetProxy;
  }).call(this);
  Batman.SetSort = (function() {
    __extends(SetSort, Batman.SetProxy);
    function SetSort(base, key, order) {
      var boundReIndex;
      this.base = base;
      this.key = key;
      if (order == null) {
        order = "asc";
      }
      SetSort.__super__.constructor.call(this);
      this.descending = order.toLowerCase() === "desc";
      if (this.base.isObservable) {
        this._setObserver = new Batman.SetObserver(this.base);
        this._setObserver.observedItemKeys = [this.key];
        boundReIndex = this._reIndex.bind(this);
        this._setObserver.observerForItemAndKey = function() {
          return boundReIndex;
        };
        this._setObserver.on('itemsWereAdded', boundReIndex);
        this._setObserver.on('itemsWereRemoved', boundReIndex);
        this.startObserving();
      }
      this._reIndex();
    }
    SetSort.prototype.startObserving = function() {
      var _ref;
      return (_ref = this._setObserver) != null ? _ref.startObserving() : void 0;
    };
    SetSort.prototype.stopObserving = function() {
      var _ref;
      return (_ref = this._setObserver) != null ? _ref.stopObserving() : void 0;
    };
    SetSort.prototype.toArray = function() {
      return this.get('_storage');
    };
    SetSort.accessor('toArray', SetSort.prototype.toArray);
    SetSort.prototype.forEach = function(iterator) {
      var e, i, _len, _ref, _results;
      _ref = this.get('_storage');
      _results = [];
      for (i = 0, _len = _ref.length; i < _len; i++) {
        e = _ref[i];
        _results.push(iterator(e, i));
      }
      return _results;
    };
    SetSort.prototype.compare = function(a, b) {
      var typeComparison;
      if (a === b) {
        return 0;
      }
      if (a === void 0) {
        return 1;
      }
      if (b === void 0) {
        return -1;
      }
      if (a === null) {
        return 1;
      }
      if (b === null) {
        return -1;
      }
      if ((typeof a.isEqual === "function" ? a.isEqual(b) : void 0) && (typeof b.isEqual === "function" ? b.isEqual(a) : void 0)) {
        return 0;
      }
      typeComparison = Batman.SetSort.prototype.compare($typeOf(a), $typeOf(b));
      if (typeComparison !== 0) {
        return typeComparison;
      }
      if (a !== a) {
        return 1;
      }
      if (b !== b) {
        return -1;
      }
      if (a > b) {
        return 1;
      }
      if (a < b) {
        return -1;
      }
      return 0;
    };
    SetSort.prototype._reIndex = function() {
      var newOrder, _ref;
      newOrder = this.base.toArray().sort(__bind(function(a, b) {
        var multiple, valueA, valueB;
        valueA = $get(a, this.key);
        if (valueA != null) {
          valueA = valueA.valueOf();
        }
        valueB = $get(b, this.key);
        if (valueB != null) {
          valueB = valueB.valueOf();
        }
        multiple = this.descending ? -1 : 1;
        return this.compare.call(this, valueA, valueB) * multiple;
      }, this));
      if ((_ref = this._setObserver) != null) {
        _ref.startObservingItems.apply(_ref, newOrder);
      }
      return this.set('_storage', newOrder);
    };
    return SetSort;
  })();
  Batman.SetIndex = (function() {
    __extends(SetIndex, Batman.Object);
    function SetIndex(base, key) {
      this.base = base;
      this.key = key;
      SetIndex.__super__.constructor.call(this);
      this._storage = new Batman.SimpleHash;
      if (this.base.isEventEmitter) {
        this._setObserver = new Batman.SetObserver(this.base);
        this._setObserver.observedItemKeys = [this.key];
        this._setObserver.observerForItemAndKey = this.observerForItemAndKey.bind(this);
        this._setObserver.on('itemsWereAdded', __bind(function() {
          var item, items, _i, _len, _results;
          items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          _results = [];
          for (_i = 0, _len = items.length; _i < _len; _i++) {
            item = items[_i];
            _results.push(this._addItem(item));
          }
          return _results;
        }, this));
        this._setObserver.on('itemsWereRemoved', __bind(function() {
          var item, items, _i, _len, _results;
          items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          _results = [];
          for (_i = 0, _len = items.length; _i < _len; _i++) {
            item = items[_i];
            _results.push(this._removeItem(item));
          }
          return _results;
        }, this));
      }
      this.base.forEach(this._addItem.bind(this));
      this.startObserving();
    }
    SetIndex.accessor(function(key) {
      return this._resultSetForKey(key);
    });
    SetIndex.prototype.startObserving = function() {
      var _ref;
      return (_ref = this._setObserver) != null ? _ref.startObserving() : void 0;
    };
    SetIndex.prototype.stopObserving = function() {
      var _ref;
      return (_ref = this._setObserver) != null ? _ref.stopObserving() : void 0;
    };
    SetIndex.prototype.observerForItemAndKey = function(item, key) {
      return __bind(function(newValue, oldValue) {
        this._removeItemFromKey(item, oldValue);
        return this._addItemToKey(item, newValue);
      }, this);
    };
    SetIndex.prototype._addItem = function(item) {
      return this._addItemToKey(item, this._keyForItem(item));
    };
    SetIndex.prototype._addItemToKey = function(item, key) {
      return this._resultSetForKey(key).add(item);
    };
    SetIndex.prototype._removeItem = function(item) {
      return this._removeItemFromKey(item, this._keyForItem(item));
    };
    SetIndex.prototype._removeItemFromKey = function(item, key) {
      var results;
      results = this._resultSetForKey(key);
      results.remove(item);
      if (results.isEmpty()) {
        return this._storage.unset(key);
      }
    };
    SetIndex.prototype._resultSetForKey = function(key) {
      return this._storage.getOrSet(key, function() {
        return new Batman.Set;
      });
    };
    SetIndex.prototype._keyForItem = function(item) {
      return Batman.Keypath.forBaseAndKey(item, this.key).getValue();
    };
    return SetIndex;
  })();
  Batman.UniqueSetIndex = (function() {
    __extends(UniqueSetIndex, Batman.SetIndex);
    function UniqueSetIndex() {
      this._uniqueIndex = new Batman.Hash;
      UniqueSetIndex.__super__.constructor.apply(this, arguments);
    }
    UniqueSetIndex.accessor(function(key) {
      return this._uniqueIndex.get(key);
    });
    UniqueSetIndex.prototype._addItemToKey = function(item, key) {
      this._resultSetForKey(key).add(item);
      if (!this._uniqueIndex.hasKey(key)) {
        return this._uniqueIndex.set(key, item);
      }
    };
    UniqueSetIndex.prototype._removeItemFromKey = function(item, key) {
      var resultSet;
      resultSet = this._resultSetForKey(key);
      UniqueSetIndex.__super__._removeItemFromKey.apply(this, arguments);
      if (resultSet.isEmpty()) {
        return this._uniqueIndex.unset(key);
      } else {
        return this._uniqueIndex.set(key, resultSet.toArray()[0]);
      }
    };
    return UniqueSetIndex;
  })();
  Batman.StateMachine = (function() {
    __extends(StateMachine, Batman.Object);
    StateMachine.InvalidTransitionError = function(message) {
      this.message = message;
    };
    StateMachine.InvalidTransitionError.prototype = Error.prototype;
    StateMachine.transitions = function(table) {
      var k, transitions, _fn, _ref;
      this.prototype.transitionTable = $mixin({}, this.prototype.transitionTable, table);
      _ref = this.prototype.transitionTable;
      _fn = __bind(function(k) {
        return this.prototype[k] || (this.prototype[k] = function(suggestedNextState) {
          return this["do"](k, suggestedNextState);
        });
      }, this);
      for (k in _ref) {
        transitions = _ref[k];
        _fn(k);
      }
      return this;
    };
    function StateMachine(startState) {
      this.nextEvents = [];
      this.set('_state', startState);
    }
    StateMachine.accessor('state', function() {
      return this.get('_state');
    });
    StateMachine.prototype.isTransitioning = false;
    StateMachine.prototype.transitionTable = {};
    StateMachine.prototype.onTransition = function(from, into, callback) {
      return this.on("" + from + "->" + into, callback);
    };
    StateMachine.prototype.onEnter = function(into, callback) {
      return this.on("enter:" + into, callback);
    };
    StateMachine.prototype.onExit = function(from, callback) {
      return this.on("exit:" + from, callback);
    };
    StateMachine.prototype["do"] = function(event, suggestedNextState) {
      var nextState, previousState;
      if (this.isTransitioning) {
        this.nextEvents.push(event);
        return;
      }
      previousState = this.get('state');
      nextState = this.nextStateOnEvent(event);
      if (!nextState) {
        return false;
      }
      if (nextState.unshift) {
        developer.assert(~nextState.indexOf(suggestedNextState), "Warning, invalid transition for the multiple destination event " + event + "!");
        nextState = suggestedNextState;
      }
      this.isTransitioning = true;
      this.fire("exit:" + previousState);
      this.fire("" + previousState + "->" + nextState);
      this.set('_state', nextState);
      this.fire("enter:" + nextState);
      this.isTransitioning = false;
      if (this.nextEvents.length > 0) {
        this["do"](this.nextEvents.shift());
      }
      return true;
    };
    StateMachine.prototype.canDo = function(event, fromState) {
      if (fromState == null) {
        fromState = this.get('state');
      }
      return !!this.nextStateOnEvent(event, fromState);
    };
    StateMachine.prototype.nextStateOnEvent = function(event, fromState) {
      var _ref;
      if (fromState == null) {
        fromState = this.get('state');
      }
      return (_ref = this.transitionTable[event]) != null ? _ref[fromState] : void 0;
    };
    return StateMachine;
  })();
  Batman.Request = (function() {
    __extends(Request, Batman.Object);
    Request.objectToFormData = function(data) {
      var formData, key, pairForList, val, _i, _len, _ref, _ref2;
      pairForList = function(key, object, first) {
        var k, list, v;
        if (first == null) {
          first = false;
        }
        return list = (function() {
          switch (Batman.typeOf(object)) {
            case 'Object':
              list = (function() {
                var _results;
                _results = [];
                for (k in object) {
                  v = object[k];
                  _results.push(pairForList((first ? k : "" + key + "[" + k + "]"), v));
                }
                return _results;
              })();
              return list.reduce(function(acc, list) {
                return acc.concat(list);
              }, []);
            case 'Array':
              return object.reduce(function(acc, element) {
                return acc.concat(pairForList("" + key + "[]", element));
              }, []);
            default:
              return [[key, object]];
          }
        })();
      };
      formData = new FormData();
      _ref = pairForList("", data, true);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        _ref2 = _ref[_i], key = _ref2[0], val = _ref2[1];
        formData.append(key, val);
      }
      return formData;
    };
    Request.prototype.url = '';
    Request.prototype.data = '';
    Request.prototype.method = 'get';
    Request.prototype.formData = false;
    Request.prototype.response = null;
    Request.prototype.status = null;
    Request.prototype.contentType = 'application/x-www-form-urlencoded';
    function Request(options) {
      var handler, handlers, k;
      handlers = {};
      for (k in options) {
        handler = options[k];
        if (k === 'success' || k === 'error' || k === 'loading' || k === 'loaded') {
          handlers[k] = handler;
          delete options[k];
        }
      }
      Request.__super__.constructor.call(this, options);
      for (k in handlers) {
        handler = handlers[k];
        this.on(k, handler);
      }
    }
    Request.observeAll('url', function() {
      return this._autosendTimeout = $setImmediate(__bind(function() {
        return this.send();
      }, this));
    });
    Request.prototype.send = function() {
      return developer.error("Please source a dependency file for a request implementation");
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
    developer["do"](__bind(function() {
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
              if (!this.isPrevented('run')) {
                this.fire('loaded');
              }
              if (this.wantsToRun) {
                return this.run();
              }
            }, this)
          });
        }
        return this;
      };
      this.controller = function() {
        var names;
        names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        names = names.map(function(n) {
          return n + '_controller';
        });
        return this.require.apply(this, ['controllers'].concat(__slice.call(names)));
      };
      this.model = function() {
        return this.require.apply(this, ['models'].concat(__slice.call(arguments)));
      };
      return this.view = function() {
        return this.require.apply(this, ['views'].concat(__slice.call(arguments)));
      };
    }, App));
    App.layout = void 0;
    App.event('ready').oneShot = true;
    App.event('run').oneShot = true;
    App.run = function() {
      if (Batman.currentApp) {
        if (Batman.currentApp === this) {
          return;
        }
        Batman.currentApp.stop();
      }
      if (this.hasRun) {
        return false;
      }
      if (this.isPrevented('run')) {
        this.wantsToRun = true;
        return false;
      } else {
        delete this.wantsToRun;
      }
      Batman.currentApp = this;
      if (typeof this.dispatcher === 'undefined') {
        this.dispatcher || (this.dispatcher = new Batman.Dispatcher(this));
      }
      this.observe('layout', __bind(function(layout) {
        return layout != null ? layout.on('ready', __bind(function() {
          return this.fire('ready');
        }, this)) : void 0;
      }, this));
      if (typeof this.layout === 'undefined') {
        this.set('layout', new Batman.View({
          contexts: [this],
          node: document
        }));
      } else if (typeof this.layout === 'string') {
        this.set('layout', new this[helpers.camelize(this.layout) + 'View']);
      }
      if (typeof this.navigator === 'undefined' && this.dispatcher.routeMap) {
        this.on('run', __bind(function() {
          this.navigator = Batman.navigator = Batman.Navigator.forApp(this);
          return this.navigator.start();
        }, this));
      }
      this.hasRun = true;
      this.fire('run');
      return this;
    };
    App.event('ready').oneShot = true;
    App.event('stop').oneShot = true;
    App.stop = function() {
      var _ref;
      if ((_ref = this.navigator) != null) {
        _ref.stop();
      }
      Batman.navigator = null;
      this.hasRun = false;
      this.fire('stop');
      return this;
    };
    return App;
  }).call(this);
  Batman.Route = (function() {
    var escapeRegExp, namedOrSplat, namedParam, queryParam, splatParam;
    __extends(Route, Batman.Object);
    namedParam = /:([\w\d]+)/g;
    splatParam = /\*([\w\d]+)/g;
    queryParam = '(?:\\?.+)?';
    namedOrSplat = /[:|\*]([\w\d]+)/g;
    escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g;
    function Route() {
      var array;
      Route.__super__.constructor.apply(this, arguments);
      this.pattern = this.url.replace(escapeRegExp, '\\$&');
      this.regexp = new RegExp('^' + this.pattern.replace(namedParam, '([^\/]*)').replace(splatParam, '(.*?)') + queryParam + '$');
      this.namedArguments = [];
      while ((array = namedOrSplat.exec(this.pattern)) != null) {
        if (array[1]) {
          this.namedArguments.push(array[1]);
        }
      }
    }
    Route.accessor('action', {
      get: function() {
        var components, result, signature;
        if (this.action) {
          return this.action;
        }
        if (this.options) {
          result = $mixin({}, this.options);
          if (signature = result.signature) {
            components = signature.split('#');
            result.controller = components[0];
            result.action = components[1] || 'index';
          }
          result.target = this.dispatcher.get(result.controller);
          return this.set('action', result);
        }
      },
      set: function(key, action) {
        return this.action = action;
      }
    });
    Route.prototype.parameterize = function(url) {
      var action, array, index, key, param, params, query, s, value, _i, _len, _len2, _ref, _ref2, _ref3, _ref4;
      _ref = url.split('?'), url = _ref[0], query = _ref[1];
      array = (_ref2 = this.regexp.exec(url)) != null ? _ref2.slice(1) : void 0;
      params = {
        url: url
      };
      action = this.get('action');
      if (typeof action === 'function') {
        params.action = action;
      } else {
        $mixin(params, action);
      }
      if (array) {
        for (index = 0, _len = array.length; index < _len; index++) {
          param = array[index];
          params[this.namedArguments[index]] = param;
        }
      }
      if (query) {
        _ref3 = query.split('&');
        for (_i = 0, _len2 = _ref3.length; _i < _len2; _i++) {
          s = _ref3[_i];
          _ref4 = s.split('='), key = _ref4[0], value = _ref4[1];
          params[key] = value;
        }
      }
      return params;
    };
    Route.prototype.dispatch = function(url) {
      var action, params, _ref, _ref2;
      if ($typeOf(url) === 'String') {
        params = this.parameterize(url);
      }
      if (!(action = params.action) && url !== '/404') {
        $redirect('/404');
      }
      if (typeof action === 'function') {
        return action(params);
      }
      if ((_ref = params.target) != null ? _ref.dispatch : void 0) {
        return params.target.dispatch(action, params);
      }
      return (_ref2 = params.target) != null ? _ref2[action](params) : void 0;
    };
    return Route;
  })();
  Batman.Dispatcher = (function() {
    __extends(Dispatcher, Batman.Object);
    function Dispatcher(app) {
      var controller, key, _ref;
      this.app = app;
      this.app.route(this);
      this.app.controllers = new Batman.Object;
      _ref = this.app;
      for (key in _ref) {
        controller = _ref[key];
        if (!((controller != null ? controller.prototype : void 0) instanceof Batman.Controller)) {
          continue;
        }
        this.prepareController(controller);
      }
    }
    Dispatcher.prototype.prepareController = function(controller) {
      var getter, name;
      name = helpers.underscore($functionName(controller).replace('Controller', ''));
      if (!name) {
        return;
      }
      getter = function() {
        return this[name] = controller.get('sharedController');
      };
      this.accessor(name, getter);
      return this.app.controllers.accessor(name, getter);
    };
    Dispatcher.prototype.register = function(url, options) {
      var route;
      if (url.indexOf('/') !== 0) {
        url = "/" + url;
      }
      route = $typeOf(options) === 'Function' ? new Batman.Route({
        url: url,
        action: options,
        dispatcher: this
      }) : new Batman.Route({
        url: url,
        options: options,
        dispatcher: this
      });
      this.routeMap || (this.routeMap = {});
      return this.routeMap[url] = route;
    };
    Dispatcher.prototype.findRoute = function(url) {
      var route, routeUrl, _ref;
      if (url.indexOf('/') !== 0) {
        url = "/" + url;
      }
      if ((route = this.routeMap[url])) {
        return route;
      }
      _ref = this.routeMap;
      for (routeUrl in _ref) {
        route = _ref[routeUrl];
        if (route.regexp.test(url)) {
          return route;
        }
      }
    };
    Dispatcher.prototype.findUrl = function(params) {
      var action, controller, key, matches, options, paramsCopy, queryString, regex, route, url, value, _ref, _ref2;
      _ref = this.routeMap;
      for (url in _ref) {
        route = _ref[url];
        matches = false;
        options = route.options;
        if (params.resource) {
          matches = options.resource === params.resource && options.action === params.action;
        } else {
          action = route.get('action');
          if (typeof action === 'function') {
            matches = true;
          } else {
            _ref2 = action, controller = _ref2.controller, action = _ref2.action;
            if (controller === params.controller && action === (params.action || 'index')) {
              matches = true;
            }
          }
        }
        if (!matches) {
          continue;
        }
        $mixin(paramsCopy = {}, params);
        $unmixin(paramsCopy, {
          controller: null,
          action: null,
          resource: null,
          url: null,
          signature: null,
          target: null
        });
        for (key in params) {
          value = params[key];
          regex = new RegExp('[:|\*]' + key);
          if (!regex.test(url)) {
            continue;
          }
          url = url.replace(regex, value);
          paramsCopy[key] = null;
          delete paramsCopy[key];
        }
        queryString = '';
        for (key in paramsCopy) {
          value = paramsCopy[key];
          queryString += !queryString ? '?' : '&';
          queryString += key + '=' + value;
        }
        return url + queryString;
      }
    };
    Dispatcher.prototype.pathFromParams = function(params) {
      if ($typeOf(params) === 'String') {
        return Batman.Navigator.normalizePath(params);
      } else {
        return this.findUrl(params);
      }
    };
    Dispatcher.prototype.dispatch = function(params) {
      var route, url;
      url = this.pathFromParams(params);
      route = this.findRoute(url);
      if (route) {
        route.dispatch(url);
      } else if (url !== '/404') {
        $redirect('/404');
      }
      this.app.set('currentURL', url);
      this.app.set('currentRoute', route);
      this.app.set('currentParams', params);
      return url;
    };
    return Dispatcher;
  })();
  Batman.Navigator = (function() {
    Navigator.defaultClass = function() {
      if (Batman.config.usePushState && Batman.PushStateNavigator.isSupported()) {
        return Batman.PushStateNavigator;
      } else {
        return Batman.HashbangNavigator;
      }
    };
    Navigator.forApp = function(app) {
      return new (this.defaultClass())(app);
    };
    function Navigator(app) {
      this.app = app;
      this.handleCurrentLocation = __bind(this.handleCurrentLocation, this);
    }
    Navigator.prototype.start = function() {
      if (typeof window === 'undefined') {
        return;
      }
      if (this.started) {
        return;
      }
      this.started = true;
      this.startWatching();
      Batman.currentApp.prevent('ready');
      return $setImmediate(__bind(function() {
        this.handleCurrentLocation();
        return Batman.currentApp.allowAndFire('ready');
      }, this));
    };
    Navigator.prototype.stop = function() {
      this.stopWatching();
      return this.started = false;
    };
    Navigator.prototype.handleLocation = function(location) {
      var path;
      path = this.pathFromLocation(location);
      if (path === this.cachedPath) {
        return;
      }
      return this.dispatch(path);
    };
    Navigator.prototype.handleCurrentLocation = function() {
      return this.handleLocation(window.location);
    };
    Navigator.prototype.dispatch = function(params) {
      return this.cachedPath = this.app.dispatcher.dispatch(params);
    };
    Navigator.prototype.push = function(params) {
      var path;
      path = this.dispatch(params);
      this.pushState(null, '', path);
      return path;
    };
    Navigator.prototype.replace = function(params) {
      var path;
      path = this.dispatch(params);
      this.replaceState(null, '', path);
      return path;
    };
    Navigator.prototype.redirect = Navigator.prototype.push;
    Navigator.prototype.normalizePath = function() {
      var i, seg, segments;
      segments = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      segments = (function() {
        var _len, _results;
        _results = [];
        for (i = 0, _len = segments.length; i < _len; i++) {
          seg = segments[i];
          _results.push(("" + seg).replace(/^(?!\/)/, '/').replace(/\/+$/, ''));
        }
        return _results;
      })();
      return segments.join('') || '/';
    };
    Navigator.normalizePath = Navigator.prototype.normalizePath;
    return Navigator;
  })();
  Batman.PushStateNavigator = (function() {
    __extends(PushStateNavigator, Batman.Navigator);
    function PushStateNavigator() {
      PushStateNavigator.__super__.constructor.apply(this, arguments);
    }
    PushStateNavigator.isSupported = function() {
      var _ref;
      return (typeof window !== "undefined" && window !== null ? (_ref = window.history) != null ? _ref.pushState : void 0 : void 0) != null;
    };
    PushStateNavigator.prototype.startWatching = function() {
      return $addEventListener(window, 'popstate', this.handleCurrentLocation);
    };
    PushStateNavigator.prototype.stopWatching = function() {
      return $removeEventListener(window, 'popstate', this.handleCurrentLocation);
    };
    PushStateNavigator.prototype.pushState = function(stateObject, title, path) {
      return window.history.pushState(stateObject, title, this.linkTo(path));
    };
    PushStateNavigator.prototype.replaceState = function(stateObject, title, path) {
      return window.history.replaceState(stateObject, title, this.linkTo(path));
    };
    PushStateNavigator.prototype.linkTo = function(url) {
      return this.normalizePath(Batman.config.pathPrefix, url);
    };
    PushStateNavigator.prototype.pathFromLocation = function(location) {
      var fullPath, prefixPattern;
      fullPath = "" + (location.pathname || '') + (location.search || '');
      prefixPattern = new RegExp("^" + (this.normalizePath(Batman.config.pathPrefix)));
      return this.normalizePath(fullPath.replace(prefixPattern, ''));
    };
    PushStateNavigator.prototype.handleLocation = function(location) {
      var hashbangPath, path;
      path = this.pathFromLocation(location);
      if (path === '/' && (hashbangPath = Batman.HashbangNavigator.prototype.pathFromLocation(location)) !== '/') {
        return this.replace(hashbangPath);
      } else {
        return PushStateNavigator.__super__.handleLocation.apply(this, arguments);
      }
    };
    return PushStateNavigator;
  })();
  Batman.HashbangNavigator = (function() {
    __extends(HashbangNavigator, Batman.Navigator);
    function HashbangNavigator() {
      HashbangNavigator.__super__.constructor.apply(this, arguments);
    }
    HashbangNavigator.prototype.HASH_PREFIX = '#!';
    if ((typeof window !== "undefined" && window !== null) && 'onhashchange' in window) {
      HashbangNavigator.prototype.startWatching = function() {
        return $addEventListener(window, 'hashchange', this.handleCurrentLocation);
      };
      HashbangNavigator.prototype.stopWatching = function() {
        return $removeEventListener(window, 'hashchange', this.handleCurrentLocation);
      };
    } else {
      HashbangNavigator.prototype.startWatching = function() {
        return this.interval = setInterval(this.handleCurrentLocation, 100);
      };
      HashbangNavigator.prototype.stopWatching = function() {
        return this.interval = clearInterval(this.interval);
      };
    }
    HashbangNavigator.prototype.pushState = function(stateObject, title, path) {
      return window.location.hash = this.linkTo(path);
    };
    HashbangNavigator.prototype.replaceState = function(stateObject, title, path) {
      var loc;
      loc = window.location;
      return loc.replace("" + loc.pathname + loc.search + (this.linkTo(path)));
    };
    HashbangNavigator.prototype.linkTo = function(url) {
      return this.HASH_PREFIX + url;
    };
    HashbangNavigator.prototype.pathFromLocation = function(location) {
      var hash;
      hash = location.hash;
      if ((hash != null ? hash.substr(0, 2) : void 0) === this.HASH_PREFIX) {
        return this.normalizePath(hash.substr(2));
      } else {
        return '/';
      }
    };
    HashbangNavigator.prototype.handleLocation = function(location) {
      var realPath;
      if (!Batman.config.usePushState) {
        return HashbangNavigator.__super__.handleLocation.apply(this, arguments);
      }
      realPath = Batman.PushStateNavigator.prototype.pathFromLocation(location);
      if (realPath === '/') {
        return HashbangNavigator.__super__.handleLocation.apply(this, arguments);
      } else {
        return location.replace(this.normalizePath("" + Batman.config.pathPrefix + (this.linkTo(realPath))));
      }
    };
    return HashbangNavigator;
  })();
  Batman.redirect = $redirect = function(url) {
    var _ref;
    return (_ref = Batman.navigator) != null ? _ref.redirect(url) : void 0;
  };
  Batman.App.classMixin({
    route: function(url, signature, options) {
      var dispatcher, key, value, _ref;
      if (options == null) {
        options = {};
      }
      if (!url) {
        return;
      }
      if (url instanceof Batman.Dispatcher) {
        dispatcher = url;
        _ref = this._dispatcherCache;
        for (key in _ref) {
          value = _ref[key];
          dispatcher.register(key, value);
        }
        this._dispatcherCache = null;
        return dispatcher;
      }
      if ($typeOf(signature) === 'String') {
        options.signature = signature;
      } else if ($typeOf(signature) === 'Function') {
        options = signature;
      } else if (signature) {
        $mixin(options, signature);
      }
      this._dispatcherCache || (this._dispatcherCache = {});
      return this._dispatcherCache[url] = options;
    },
    root: function(signature, options) {
      return this.route('/', signature, options);
    },
    resources: function(resource, options, callback) {
      var app, controller, ops;
      if (options == null) {
        options = {};
      }
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      resource = helpers.pluralize(resource);
      controller = options.controller || resource;
      if (options.parentResource) {
        resource = "" + options.parentResource + "/:" + (helpers.singularize(options.parentResource)) + "Id/" + resource;
      }
      if (options.index !== false) {
        this.route(resource, "" + controller + "#index", {
          resource: controller,
          action: 'index'
        });
      }
      if (options["new"] !== false) {
        this.route("" + resource + "/new", "" + controller + "#new", {
          resource: controller,
          action: 'new'
        });
      }
      if (options.show !== false) {
        this.route("" + resource + "/:id", "" + controller + "#show", {
          resource: controller,
          action: 'show'
        });
      }
      if (options.edit !== false) {
        this.route("" + resource + "/:id/edit", "" + controller + "#edit", {
          resource: controller,
          action: 'edit'
        });
      }
      if (callback) {
        app = this;
        ops = {
          collection: function(collectionCallback) {
            return collectionCallback != null ? collectionCallback.call({
              route: function(url, methodName) {
                return app.route("" + resource + "/" + url, "" + controller + "#" + (methodName || url));
              }
            }) : void 0;
          },
          member: function(memberCallback) {
            return memberCallback != null ? memberCallback.call({
              route: function(url, methodName) {
                return app.route("" + resource + "/:id/" + url, "" + controller + "#" + (methodName || url));
              }
            }) : void 0;
          },
          resources: __bind(function(childResource, options, callback) {
            if (options == null) {
              options = {};
            }
            if (typeof options === 'function') {
              callback = options;
              options = {};
            }
            options.parentResource = resource;
            return this.resources(childResource, options, callback);
          }, this)
        };
        return callback.call(ops);
      }
    },
    redirect: $redirect
  });
  Batman.Controller = (function() {
    __extends(Controller, Batman.Object);
    function Controller() {
      this.redirect = __bind(this.redirect, this);
      Controller.__super__.constructor.apply(this, arguments);
    }
    Controller.singleton('sharedController');
    Controller.beforeFilter = function(nameOrFunction) {
      var filters, _base;
      Batman.initializeObject(this);
      filters = (_base = this._batman).beforeFilters || (_base.beforeFilters = []);
      if (filters.indexOf(nameOrFunction) === -1) {
        return filters.push(nameOrFunction);
      }
    };
    Controller.accessor('controllerName', {
      get: function() {
        return this._controllerName || (this._controllerName = helpers.underscore($functionName(this.constructor).replace('Controller', '')));
      }
    });
    Controller.afterFilter = function(nameOrFunction) {
      var filters, _base;
      Batman.initializeObject(this);
      filters = (_base = this._batman).afterFilters || (_base.afterFilters = []);
      if (filters.indexOf(nameOrFunction) === -1) {
        return filters.push(nameOrFunction);
      }
    };
    Controller.accessor('action', {
      get: function() {
        return this._currentAction;
      },
      set: function(key, value) {
        return this._currentAction = value;
      }
    });
    Controller.prototype.dispatch = function(action, params) {
      var filter, filters, oldRedirect, redirectTo, _i, _j, _len, _len2, _ref, _ref2, _ref3, _ref4, _ref5;
      if (params == null) {
        params = {};
      }
      params.controller || (params.controller = this.get('controllerName'));
      params.action || (params.action = action);
      params.target || (params.target = this);
      oldRedirect = (_ref = Batman.navigator) != null ? _ref.redirect : void 0;
      if ((_ref2 = Batman.navigator) != null) {
        _ref2.redirect = this.redirect;
      }
      this._actedDuringAction = false;
      this.set('action', action);
      this.set('params', params);
      if (filters = (_ref3 = this.constructor._batman) != null ? _ref3.get('beforeFilters') : void 0) {
        for (_i = 0, _len = filters.length; _i < _len; _i++) {
          filter = filters[_i];
          if (typeof filter === 'function') {
            filter.call(this, params);
          } else {
            this[filter](params);
          }
        }
      }
      developer.assert(this[action], "Error! Controller action " + (this.get('controllerName')) + "." + action + " couldn't be found!");
      this[action](params);
      if (!this._actedDuringAction) {
        this.render();
      }
      if (filters = (_ref4 = this.constructor._batman) != null ? _ref4.get('afterFilters') : void 0) {
        for (_j = 0, _len2 = filters.length; _j < _len2; _j++) {
          filter = filters[_j];
          if (typeof filter === 'function') {
            filter.call(this, params);
          } else {
            this[filter](params);
          }
        }
      }
      delete this._actedDuringAction;
      if ((_ref5 = Batman.navigator) != null) {
        _ref5.redirect = oldRedirect;
      }
      redirectTo = this._afterFilterRedirect;
      delete this._afterFilterRedirect;
      if (redirectTo) {
        return $redirect(redirectTo);
      }
    };
    Controller.prototype.redirect = function(url) {
      if (this._actedDuringAction) {
        throw 'DoubleRedirectError';
      }
      if (this.get('action')) {
        this._actedDuringAction = true;
        return this._afterFilterRedirect = url;
      } else {
        if ($typeOf(url) === 'Object') {
          if (!url.controller) {
            url.controller = this;
          }
        }
        return $redirect(url);
      }
    };
    Controller.prototype.render = function(options) {
      var controllerName, view, _ref, _ref2;
      if (options == null) {
        options = {};
      }
      if (this._actedDuringAction) {
        throw 'DoubleRenderError';
      }
      this._actedDuringAction = true;
      if (options === false) {
        return;
      }
      if (!options.view) {
        controllerName = $functionName(this.constructor).replace('Controller', '');
        options.contexts || (options.contexts = []);
        options.contexts.push(this);
        options.source || (options.source = helpers.underscore(controllerName) + '/' + this._currentAction);
        options.view = new (((_ref = Batman.currentApp) != null ? _ref[helpers.camelize("" + controllerName + "_" + this._currentAction + "_view")] : void 0) || Batman.View)(options);
      }
      if (view = options.view) {
        if ((_ref2 = Batman.currentApp) != null) {
          _ref2.prevent('ready');
        }
        view.on('ready', __bind(function() {
          var _ref3;
          Batman.DOM.replace(options.into || 'main', view.get('node'));
          if ((_ref3 = Batman.currentApp) != null) {
            _ref3.allowAndFire('ready');
          }
          return typeof view.ready === "function" ? view.ready(this.params) : void 0;
        }, this));
      }
      return view;
    };
    return Controller;
  })();
  Batman.Model = (function() {
    __extends(Model, Batman.Object);
    Model.primaryKey = 'id';
    Model.storageKey = null;
    Model.persist = function() {
      var mechanism, mechanisms, results, storage, _base;
      mechanisms = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      Batman.initializeObject(this.prototype);
      storage = (_base = this.prototype._batman).storage || (_base.storage = []);
      results = (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = mechanisms.length; _i < _len; _i++) {
          mechanism = mechanisms[_i];
          mechanism = mechanism.isStorageAdapter ? mechanism : new mechanism(this);
          storage.push(mechanism);
          _results.push(mechanism);
        }
        return _results;
      }).call(this);
      if (results.length > 1) {
        return results;
      } else {
        return results[0];
      }
    };
    Model.encode = function() {
      var decoder, encoder, encoderOrLastKey, key, keys, _base, _base2, _i, _j, _len, _results;
      keys = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), encoderOrLastKey = arguments[_i++];
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
      if (typeof encoder === 'undefined') {
        encoder = this.defaultEncoder.encode;
      }
      if (typeof decoder === 'undefined') {
        decoder = this.defaultEncoder.decode;
      }
      _results = [];
      for (_j = 0, _len = keys.length; _j < _len; _j++) {
        key = keys[_j];
        if (encoder) {
          this.prototype._batman.encoders.set(key, encoder);
        }
        _results.push(decoder ? this.prototype._batman.decoders.set(key, decoder) : void 0);
      }
      return _results;
    };
    Model.defaultEncoder = {
      encode: function(x) {
        return x;
      },
      decode: function(x) {
        return x;
      }
    };
    Model.observeAndFire('primaryKey', function(newPrimaryKey) {
      return this.encode(newPrimaryKey, {
        encode: false,
        decode: this.defaultEncoder.decode
      });
    });
    Model.validate = function() {
      var keys, match, matches, options, optionsOrFunction, validator, validators, _base, _i, _j, _len, _results;
      keys = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), optionsOrFunction = arguments[_i++];
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
        for (_j = 0, _len = Validators.length; _j < _len; _j++) {
          validator = Validators[_j];
          _results.push((function() {
            var _k, _len2;
            if ((matches = validator.matches(options))) {
              for (_k = 0, _len2 = matches.length; _k < _len2; _k++) {
                match = matches[_k];
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
    Model.LifecycleStateMachine = (function() {
      __extends(LifecycleStateMachine, Batman.StateMachine);
      function LifecycleStateMachine() {
        LifecycleStateMachine.__super__.constructor.apply(this, arguments);
      }
      LifecycleStateMachine.transitions({
        load: {
          empty: 'loading',
          loaded: 'loading',
          loading: 'loading'
        },
        loaded: {
          loading: 'loaded'
        },
        error: {
          loading: 'error'
        }
      });
      return LifecycleStateMachine;
    })();
    Model.classAccessor('lifecycle', function() {
      var _base;
      this._batman.check(this);
      return (_base = this._batman).lifecycle || (_base.lifecycle = new Model.LifecycleStateMachine('empty'));
    });
    Model.classAccessor('all', {
      get: function() {
        var _ref;
        if (this.prototype.hasStorage() && ((_ref = this.get('lifecycle.state')) !== 'loaded' && _ref !== 'loading')) {
          this.load();
        }
        return this.get('loaded');
      },
      set: function(k, v) {
        return this.set('loaded', v);
      }
    });
    Model.classAccessor('loaded', {
      get: function() {
        return this._loaded || (this._loaded = new Batman.Set);
      },
      set: function(k, v) {
        return this._loaded = v;
      }
    });
    Model.classAccessor('first', function() {
      return this.get('all').toArray()[0];
    });
    Model.classAccessor('last', function() {
      var x;
      x = this.get('all').toArray();
      return x[x.length - 1];
    });
    Model.find = function(id, callback) {
      var newRecord, record;
      developer.assert(callback, "Must call find with a callback!");
      record = new this();
      record.set('id', id);
      newRecord = this._mapIdentity(record);
      newRecord.load(callback);
      return newRecord;
    };
    Model.load = function(options, callback) {
      var lifecycle;
      if ($typeOf(options) === 'Function') {
        callback = options;
        options = {};
      }
      developer.assert(this.prototype._batman.getAll('storage').length, "Can't load model " + ($functionName(this)) + " without any storage adapters!");
      lifecycle = this.get('lifecycle');
      if (lifecycle.load()) {
        return this.prototype._doStorageOperation('readAll', options, __bind(function(err, records) {
          var mappedRecords, record;
          if (err != null) {
            lifecycle.error();
            return typeof callback === "function" ? callback(err, []) : void 0;
          } else {
            mappedRecords = (function() {
              var _i, _len, _results;
              _results = [];
              for (_i = 0, _len = records.length; _i < _len; _i++) {
                record = records[_i];
                _results.push(this._mapIdentity(record));
              }
              return _results;
            }).call(this);
            lifecycle.loaded();
            return typeof callback === "function" ? callback(err, mappedRecords) : void 0;
          }
        }, this));
      } else {
        return callback(new Batman.StateMachine.InvalidTransitionError("Can't load while in state " + (lifecycle.get('state'))));
      }
    };
    Model.create = function(attrs, callback) {
      var obj, _ref;
      if (!callback) {
        _ref = [{}, attrs], attrs = _ref[0], callback = _ref[1];
      }
      obj = new this(attrs);
      obj.save(callback);
      return obj;
    };
    Model.findOrCreate = function(attrs, callback) {
      var foundRecord, record;
      record = new this(attrs);
      if (record.isNew()) {
        return record.save(callback);
      } else {
        foundRecord = this._mapIdentity(record);
        foundRecord.updateAttributes(attrs);
        return callback(void 0, foundRecord);
      }
    };
    Model._mapIdentity = function(record) {
      var existing, id, _ref;
      if (typeof (id = record.get('id')) === 'undefined' || id === '') {
        return record;
      } else {
        existing = (_ref = this.get("loaded.indexedBy.id").get(id)) != null ? _ref.toArray()[0] : void 0;
        if (existing) {
          existing.updateAttributes(record._batman.attributes || {});
          return existing;
        } else {
          this.get('loaded').add(record);
          return record;
        }
      }
    };
    Model.belongsTo = function(label, scope) {
      return new Batman.Association.belongsTo(this, label, scope);
    };
    Model.hasOne = function(label, scope) {
      return new Batman.Association.hasOne(this, label, scope);
    };
    Model.hasMany = function(label, scope) {
      return new Batman.Association.hasMany(this, label, scope);
    };
    Model.accessor('id', {
      get: function() {
        var pk;
        pk = this.constructor.primaryKey;
        if (pk === 'id') {
          return this.id;
        } else {
          return this.get(pk);
        }
      },
      set: function(k, v) {
        var intId, pk;
        if (typeof v === "string" && !isNaN(intId = parseInt(v, 10))) {
          v = intId;
        }
        pk = this.constructor.primaryKey;
        if (pk === 'id') {
          this._markDirtyAttribute(k, this.id);
          return this.id = v;
        } else {
          return this.set(pk, v);
        }
      }
    });
    Model.accessor('dirtyKeys', 'errors', Batman.Property.defaultAccessor);
    Model.accessor('batmanState', function() {
      return this.lifecycle.get('state');
    });
    Model.accessor(Model.defaultAccessor = {
      get: function(k) {
        var _base;
        return ((_base = this._batman).attributes || (_base.attributes = {}))[k] || this[k];
      },
      set: function(key, value) {
        var oldValue, result, _base;
        oldValue = this.get(key);
        result = ((_base = this._batman).attributes || (_base.attributes = {}))[key] = value;
        this._markDirtyAttribute(key, oldValue);
        return result;
      },
      unset: function(key) {
        var oldValue, _base;
        oldValue = ((_base = this._batman).attributes || (_base.attributes = {}))[key];
        delete this._batman.attributes[key];
        this._markDirtyAttribute(key, oldValue);
        return oldValue;
      }
    });
    Model.InstanceLifecycleStateMachine = (function() {
      __extends(InstanceLifecycleStateMachine, Batman.StateMachine);
      function InstanceLifecycleStateMachine() {
        InstanceLifecycleStateMachine.__super__.constructor.apply(this, arguments);
      }
      InstanceLifecycleStateMachine.transitions({
        load: {
          empty: 'loading',
          dirty: 'loading',
          loaded: 'loading',
          loading: 'loading'
        },
        loaded: {
          loading: 'loaded'
        },
        keySet: {
          empty: 'dirty',
          loaded: 'dirty',
          dirty: 'dirty',
          validated: 'dirty'
        },
        clean: {
          dirty: 'loaded',
          loaded: 'loaded'
        },
        validate: {
          dirty: 'validating',
          loaded: 'validating',
          empty: 'validating',
          validated: 'validating'
        },
        validated: {
          validating: 'validated'
        },
        invalidate: {
          validating: ['dirty', 'loaded', 'empty']
        },
        doneValidation: {
          validated: ['dirty', 'loaded', 'empty']
        },
        save: {
          validated: 'saving',
          empty: 'saving',
          loaded: 'saving',
          dirty: 'saving'
        },
        saved: {
          saving: 'saved'
        },
        create: {
          validated: 'creating',
          empty: 'creating',
          loaded: 'creating',
          dirty: 'creating'
        },
        created: {
          creating: 'created'
        },
        doneStore: {
          created: 'loaded',
          saved: 'loaded'
        },
        destroy: {
          loaded: 'destroying',
          dirty: 'destroying'
        },
        destroyed: {
          destroying: 'destroyed'
        },
        error: {
          loading: 'error',
          validating: 'error',
          destroying: 'error',
          saving: 'error',
          creating: 'error'
        }
      });
      return InstanceLifecycleStateMachine;
    })();
    function Model(idOrAttributes) {
      if (idOrAttributes == null) {
        idOrAttributes = {};
      }
      this.destroy = __bind(this.destroy, this);
      this.save = __bind(this.save, this);
      this.load = __bind(this.load, this);
      developer.assert(this instanceof Batman.Object, "constructors must be called with new");
      this.dirtyKeys = new Batman.Hash;
      this.errors = new Batman.ErrorsSet;
      this.lifecycle = new Batman.Model.InstanceLifecycleStateMachine('empty');
      if ($typeOf(idOrAttributes) === 'Object') {
        Model.__super__.constructor.call(this, idOrAttributes);
      } else {
        Model.__super__.constructor.call(this);
        this.set('id', idOrAttributes);
      }
    }
    Model.prototype.updateAttributes = function(attrs) {
      this.mixin(attrs);
      return this;
    };
    Model.prototype.toString = function() {
      return "" + ($functionName(this.constructor)) + ": " + (this.get('id'));
    };
    Model.prototype.toJSON = function() {
      var encoders, obj;
      obj = {};
      Batman.Association.Collection.encodeModelIntoObject(this, obj);
      encoders = this._batman.get('encoders');
      if (!(!encoders || encoders.isEmpty())) {
        encoders.forEach(__bind(function(key, encoder) {
          var encodedVal, val;
          val = this.get(key);
          if (typeof val !== 'undefined') {
            encodedVal = encoder(val);
            if (typeof encodedVal !== 'undefined') {
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
      Batman.Association.Collection.decodeObjectIntoModel(this, obj, data);
      decoders = this._batman.get('decoders');
      if (!decoders || decoders.isEmpty()) {
        for (key in data) {
          value = data[key];
          obj[key] = value;
        }
      } else {
        decoders.forEach(function(key, decoder) {
          if (data[key]) {
            return obj[key] = decoder(data[key]);
          }
        });
      }
      developer["do"](function() {
        if ((!decoders) || decoders.reduce((function(sum, x) {
          return sum + x;
        }), 0) <= 1) {
          return developer.warn("Warning: Model " + (this.get('storageKey')) + " has suspiciously few decoders!");
        }
      });
      return this.mixin(obj);
    };
    Model.prototype._doStorageOperation = function(operation, options, callback) {
      var mechanism, mechanisms, _i, _len;
      developer.assert(this.hasStorage(), "Can't " + operation + " model " + ($functionName(this.constructor)) + " without any storage adapters!");
      mechanisms = this._batman.get('storage');
      for (_i = 0, _len = mechanisms.length; _i < _len; _i++) {
        mechanism = mechanisms[_i];
        mechanism[operation](this, options, callback);
      }
      return true;
    };
    Model.prototype.hasStorage = function() {
      return (this._batman.get('storage') || []).length > 0;
    };
    Model.prototype.load = function(callback) {
      var _ref;
      if ((_ref = this.lifecycle.get('state')) === 'destroying' || _ref === 'destroyed') {
        if (typeof callback === "function") {
          callback(new Error("Can't load a destroyed record!"));
        }
        return;
      }
      if (this.lifecycle.load()) {
        return this._doStorageOperation('read', {}, __bind(function(err, record) {
          if (!err) {
            this.lifecycle.loaded();
            record = this.constructor._mapIdentity(record);
          } else {
            this.lifecycle.error();
          }
          return typeof callback === "function" ? callback(err, record) : void 0;
        }, this));
      } else {
        return typeof callback === "function" ? callback(new Batman.StateMachine.InvalidTransitionError("Can't load while in state " + (this.lifecycle.get('state')))) : void 0;
      }
    };
    Model.prototype.save = function(callback) {
      var _ref;
      if ((_ref = this.lifecycle.get('state')) === 'destroying' || _ref === 'destroyed') {
        if (typeof callback === "function") {
          callback(new Error("Can't save a destroyed record!"));
        }
        return;
      }
      return this.validate(__bind(function(error, errors) {
        var associations, belongsTo, creating, hasMany, hasOne;
        if (error || errors.length) {
          if (typeof callback === "function") {
            callback(error || errors);
          }
          return;
        }
        creating = this.isNew();
        if (this.lifecycle["do"](creating ? 'create' : 'save')) {
          if (associations = Batman.Association.Collection.getModelAssociations(this)) {
            belongsTo = associations.belongsTo, hasOne = associations.hasOne, hasMany = associations.hasMany;
            if (belongsTo != null) {
              belongsTo.forEach(__bind(function(association) {
                return association.apply(this);
              }, this));
            }
          }
          return this._doStorageOperation((creating ? 'create' : 'update'), {}, __bind(function(err, record) {
            if (!err) {
              this.lifecycle["do"](creating ? 'created' : 'saved');
              this.dirtyKeys.clear();
              if (hasOne != null) {
                hasOne.forEach(function(association) {
                  return association.apply(err, record);
                });
              }
              if (hasMany != null) {
                hasMany.forEach(function(association) {
                  return association.apply(err, record);
                });
              }
              record = this.constructor._mapIdentity(record);
            } else {
              this.lifecycle.error();
            }
            this.lifecycle.doneStore();
            return typeof callback === "function" ? callback(err, record) : void 0;
          }, this));
        } else {
          return typeof callback === "function" ? callback(new Batman.StateMachine.InvalidTransitionError("Can't save while in state " + (this.lifecycle.get('state')))) : void 0;
        }
      }, this));
    };
    Model.prototype.destroy = function(callback) {
      if (this.lifecycle.destroy()) {
        return this._doStorageOperation('destroy', {}, __bind(function(err, record) {
          if (!err) {
            this.constructor.get('all').remove(this);
            this.lifecycle.destroyed();
          } else {
            this.lifecycle.error();
          }
          return typeof callback === "function" ? callback(err) : void 0;
        }, this));
      } else {
        return typeof callback === "function" ? callback(new Batman.StateMachine.InvalidTransitionError("Can't destroy while in state " + (this.lifecycle.get('state')))) : void 0;
      }
    };
    Model.prototype.validate = function(callback) {
      var count, finish, key, oldState, v, validationCallback, validator, validators, _i, _j, _len, _len2, _ref;
      oldState = this.lifecycle.get('state');
      this.errors.clear();
      if (this.lifecycle.validate()) {
        finish = __bind(function() {
          if (this.errors.get('length') === 0) {
            this.lifecycle.validated();
            this.lifecycle.doneValidation(oldState);
            return typeof callback === "function" ? callback(void 0, this.errors) : void 0;
          } else {
            this.lifecycle.invalidate(oldState);
            return typeof callback === "function" ? callback(void 0, this.errors) : void 0;
          }
        }, this);
        validators = this._batman.get('validators') || [];
        if (!(validators.length > 0)) {
          finish();
        } else {
          count = validators.length;
          validationCallback = __bind(function() {
            if (--count === 0) {
              return finish();
            }
          }, this);
          for (_i = 0, _len = validators.length; _i < _len; _i++) {
            validator = validators[_i];
            v = validator.validator;
            _ref = validator.keys;
            for (_j = 0, _len2 = _ref.length; _j < _len2; _j++) {
              key = _ref[_j];
              if (v) {
                v.validateEach(this.errors, this, key, validationCallback);
              } else {
                validator.callback(this.errors, this, key, validationCallback);
              }
            }
          }
        }
      } else {
        if (typeof callback === "function") {
          callback(new Batman.StateMachine.InvalidTransitionError("Can't validate while in state " + (this.lifecycle.get('state'))));
        }
      }
    };
    Model.prototype.isNew = function() {
      return typeof this.get('id') === 'undefined';
    };
    Model.prototype._markDirtyAttribute = function(key, oldValue) {
      var _ref;
      if ((_ref = this.lifecycle.get('state')) !== 'loading' && _ref !== 'creating' && _ref !== 'saving' && _ref !== 'saved') {
        if (this.lifecycle.keySet()) {
          return this.dirtyKeys.set(key, oldValue);
        } else {
          throw new Batman.StateMachine.InvalidTransitionError("Can't set while in state " + (this.lifecycle.get('state')));
        }
      }
    };
    return Model;
  }).call(this);
  Batman.Association = (function() {
    function Association(model, label, options) {
      var getAccessor, self;
      this.model = model;
      this.label = label;
      this.options = options != null ? options : {};
      Batman.Association.Collection.add(this);
      self = this;
      getAccessor = function() {
        return self.getAccessor.call(this, self, model, label);
      };
      model.accessor(label, {
        get: getAccessor,
        set: Batman.Model.defaultAccessor.set,
        unset: Batman.Model.defaultAccessor.unset
      });
    }
    Association.prototype.getRelatedModel = function() {
      var modelName, scope;
      scope = this.options['namespace'] || Batman.currentApp;
      modelName = this.options['name'] || helpers.camelize(helpers.singularize(this.label));
      return scope != null ? scope[modelName] : void 0;
    };
    Association.prototype.decodeObjectIntoModel = function(model, obj, data) {
      var json, record, relatedModel;
      if (json = data[this.label]) {
        if (relatedModel = this.getRelatedModel()) {
          record = new relatedModel(json);
          return obj[this.label] = relatedModel._mapIdentity(record);
        }
      }
    };
    Association.prototype.getAccessor = function() {
      return developer.error("You must override getAccessor in Batman.Association subclasses.");
    };
    Association.prototype.encodeModelIntoObject = function() {
      return developer.error("You must override encodeModelIntoObject in Batman.Associatio subclasses.");
    };
    return Association;
  })();
  Batman.Association.Collection = (function() {
    var BatmanAssociationCollection;
    BatmanAssociationCollection = (function() {
      function BatmanAssociationCollection() {
        this.storage = new Batman.SimpleHash;
      }
      BatmanAssociationCollection.prototype.add = function(association) {
        var associationTypeHash, baseModelHash;
        if (!(baseModelHash = this.storage.get(association.model))) {
          baseModelHash = new Batman.SimpleHash;
          this.storage.set(association.model, baseModelHash);
        }
        if (!(associationTypeHash = baseModelHash.get(association.constructor))) {
          associationTypeHash = new Batman.SimpleHash;
          baseModelHash.set(association.constructor, associationTypeHash);
        }
        return associationTypeHash.set(association, association.label);
      };
      BatmanAssociationCollection.prototype.getModelAssociations = function(model) {
        var hash;
        if (hash = this.storage.get(model.constructor)) {
          return {
            belongsTo: hash.get(Batman.Association.belongsTo),
            hasOne: hash.get(Batman.Association.hasOne),
            hasMany: hash.get(Batman.Association.hasMany)
          };
        }
      };
      BatmanAssociationCollection.prototype.encodeModelIntoObject = function(model, obj) {
        if (!this._encodingRelation) {
          this._encodingRelation = true;
          this.forEach(model, function(association) {
            return association.encodeModelIntoObject(model, obj);
          });
          return this._encodingRelation = false;
        }
      };
      BatmanAssociationCollection.prototype.decodeObjectIntoModel = function(model, obj, data) {
        if (!this._decodingRelation) {
          this._decodingRelation = true;
          this.forEach(model, function(association) {
            return association.decodeObjectIntoModel(model, obj, data);
          });
          return this._decodingRelation = false;
        }
      };
      BatmanAssociationCollection.prototype.forEach = function(model, callback) {
        return this.storage.forEach(function(modelClass, associationClassHash) {
          if (!(model instanceof modelClass)) {
            return;
          }
          return associationClassHash.forEach(function(associationClass, associationHash) {
            return associationHash != null ? associationHash.forEach(function(association) {
              return callback(association);
            }) : void 0;
          });
        });
      };
      return BatmanAssociationCollection;
    })();
    return new BatmanAssociationCollection;
  })();
  Batman.Association.belongsTo = (function() {
    __extends(belongsTo, Batman.Association);
    function belongsTo() {
      belongsTo.__super__.constructor.apply(this, arguments);
      this.model.encode("" + this.label + "_id");
    }
    belongsTo.prototype.getAccessor = function(self, model, label) {
      var loadedRecord, relatedID, relatedModel, relatedRecord, _ref;
      if (relatedRecord = (_ref = this._batman.attributes) != null ? _ref[label] : void 0) {
        return relatedRecord;
      }
      if (!(relatedID = this.get("" + label + "_id"))) {
        return;
      }
      if (!(relatedModel = self.getRelatedModel())) {
        return;
      }
      loadedRecord = relatedModel.get('loaded').indexedBy('id').get(relatedID);
      if (!loadedRecord.isEmpty()) {
        return loadedRecord.toArray()[0];
      } else {
        return relatedModel.find(relatedID, function(error, loadedRecord) {
          if (error) {
            throw error;
          }
        });
      }
    };
    belongsTo.prototype.apply = function(base) {
      var model;
      if (model = base.get(this.label)) {
        return base.set("" + this.label + "_id", model.get('id'));
      }
    };
    belongsTo.prototype.encodeModelIntoObject = function(model, obj) {
      var relation;
      if (this.options["saveInline"] !== true) {
        return;
      }
      if (relation = model.get(this.label)) {
        return obj[this.label] = relation.toJSON();
      }
    };
    return belongsTo;
  })();
  Batman.Association.hasOne = (function() {
    __extends(hasOne, Batman.Association);
    function hasOne() {
      hasOne.__super__.constructor.apply(this, arguments);
      this.propertyName = $functionName(this.model).toLowerCase();
      this.foreignKey = "" + (helpers.underscore($functionName(this.model))) + "_id";
    }
    hasOne.prototype.getAccessor = function(self, model, label) {
      var existingInstance, id, loadOptions, loadedRecord, relatedModel, relatedRecords;
      if (this.amSetting) {
        return;
      }
      existingInstance = Batman.Model.defaultAccessor.get.call(this, label);
      if (existingInstance != null) {
        return existingInstance;
      }
      if (!(relatedModel = self.getRelatedModel())) {
        return;
      }
      if (!(id = this.get('id'))) {
        return;
      }
      relatedRecords = relatedModel.get('loaded').indexedBy(self.foreignKey).get(id);
      if (!relatedRecords.isEmpty()) {
        return relatedRecords.toArray()[0];
      } else {
        loadedRecord = new relatedModel;
        this.amSetting = true;
        this.set(label, loadedRecord);
        this.amSetting = false;
        loadOptions = {};
        loadOptions[self.foreignKey] = id;
        relatedModel.load(loadOptions, __bind(function(error, loadedRecords) {
          if (error) {
            throw error;
          }
          if (!loadedRecords || loadedRecords.length <= 0) {
            return;
          }
          return loadedRecord.fromJSON(loadedRecords[0].toJSON());
        }, this));
        return loadedRecord;
      }
    };
    hasOne.prototype.apply = function(baseSaveError, base) {
      var relation, _ref;
      if (relation = (_ref = base._batman.attributes) != null ? _ref[this.label] : void 0) {
        return relation.set(this.foreignKey, base.get('id'));
      }
    };
    hasOne.prototype.encodeModelIntoObject = function(model, obj) {
      var relation, relationJSON;
      if (this.options["saveInline"] === false) {
        return;
      }
      if (relation = model.get(this.label)) {
        relationJSON = relation.toJSON();
        relationJSON[this.foreignKey] = model.get('id');
        return obj[this.label] = relationJSON;
      }
    };
    return hasOne;
  })();
  Batman.Association.hasMany = (function() {
    __extends(hasMany, Batman.Association);
    function hasMany() {
      hasMany.__super__.constructor.apply(this, arguments);
      this.propertyName = $functionName(this.model).toLowerCase();
      this.foreignKey = "" + (helpers.underscore($functionName(this.model))) + "_id";
    }
    hasMany.prototype.getAccessor = function(self, model, label) {
      var id, loadOptions, recordInAttributes, relatedModel, relatedRecords, _ref;
      if (this.amSetting) {
        return;
      }
      if (!(relatedModel = self.getRelatedModel())) {
        return;
      }
      if (recordInAttributes = (_ref = this._batman.attributes) != null ? _ref[label] : void 0) {
        return recordInAttributes;
      }
      if (!(id = this.get('id'))) {
        return;
      }
      relatedRecords = relatedModel.get('loaded').indexedBy(self.foreignKey).get(id);
      if (relatedRecords.isEmpty()) {
        this.amSetting = true;
        this.set(label, relatedRecords);
        this.amSetting = false;
        loadOptions = {};
        loadOptions[self.foreignKey] = id;
        relatedModel.load(loadOptions, function(error, records) {
          if (error) {
            throw error;
          }
        });
      }
      return relatedRecords;
    };
    hasMany.prototype.apply = function(baseSaveError, base) {
      var relations, _ref;
      if (relations = (_ref = base._batman.attributes) != null ? _ref[this.label] : void 0) {
        return relations.forEach(__bind(function(model) {
          return model.set(this.foreignKey, base.get('id'));
        }, this));
      }
    };
    hasMany.prototype.encodeModelIntoObject = function(model, obj) {
      var jsonArray, relationSet;
      if (this.options["saveInline"] === false) {
        return;
      }
      if (relationSet = model.get(this.label)) {
        jsonArray = [];
        relationSet.forEach(__bind(function(relation) {
          var relationJSON;
          relationJSON = relation.toJSON();
          relationJSON[this.foreignKey] = model.get('id');
          return jsonArray.push(relationJSON);
        }, this));
        return obj[this.label] = jsonArray;
      }
    };
    hasMany.prototype.decodeObjectIntoModel = function(model, obj, data) {
      var jsonArray, jsonObject, record, relatedModel, relations, _i, _len;
      if (jsonArray = data[this.label]) {
        relations = new Batman.Set;
        if (relatedModel = this.getRelatedModel()) {
          for (_i = 0, _len = jsonArray.length; _i < _len; _i++) {
            jsonObject = jsonArray[_i];
            record = new relatedModel(jsonObject);
            record = relatedModel._mapIdentity(record);
            relations.add(record);
          }
        }
        return obj[this.label] = relations;
      }
    };
    return hasMany;
  })();
  Batman.ValidationError = (function() {
    __extends(ValidationError, Batman.Object);
    function ValidationError(attribute, message) {
      ValidationError.__super__.constructor.call(this, {
        attribute: attribute,
        message: message
      });
    }
    return ValidationError;
  })();
  Batman.ErrorsSet = (function() {
    __extends(ErrorsSet, Batman.Set);
    function ErrorsSet() {
      ErrorsSet.__super__.constructor.apply(this, arguments);
    }
    ErrorsSet.accessor(function(key) {
      return this.indexedBy('attribute').get(key);
    });
    ErrorsSet.prototype.add = function(key, error) {
      return ErrorsSet.__super__.add.call(this, new Batman.ValidationError(key, error));
    };
    return ErrorsSet;
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
      return developer.error("You must override validate in Batman.Validator subclasses.");
    };
    Validator.prototype.format = function(key, messageKey, interpolations) {
      return t('errors.format', {
        attribute: key,
        message: t("errors.messages." + messageKey, interpolations)
      });
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
      LengthValidator.prototype.validateEach = function(errors, record, key, callback) {
        var options, value;
        options = this.options;
        value = record.get(key);
        if (options.minLength && value.length < options.minLength) {
          errors.add(key, this.format(key, 'too_short', {
            count: options.minLength
          }));
        }
        if (options.maxLength && value.length > options.maxLength) {
          errors.add(key, this.format(key, 'too_long', {
            count: options.maxLength
          }));
        }
        if (options.length && value.length !== options.length) {
          errors.add(key, this.format(key, 'wrong_length', {
            count: options.length
          }));
        }
        return callback();
      };
      return LengthValidator;
    })(), Batman.PresenceValidator = (function() {
      __extends(PresenceValidator, Batman.Validator);
      function PresenceValidator() {
        PresenceValidator.__super__.constructor.apply(this, arguments);
      }
      PresenceValidator.options('presence');
      PresenceValidator.prototype.validateEach = function(errors, record, key, callback) {
        var value;
        value = record.get(key);
        if (this.options.presence && !(value != null)) {
          errors.add(key, this.format(key, 'blank'));
        }
        return callback();
      };
      return PresenceValidator;
    })()
  ];
  $mixin(Batman.translate.messages, {
    errors: {
      format: "%{attribute} %{message}",
      messages: {
        too_short: "must be at least %{count} characters",
        too_long: "must be less than %{count} characters",
        wrong_length: "must be %{count} characters",
        blank: "can't be blank"
      }
    }
  });
  Batman.StorageAdapter = (function() {
    var k, time, _fn, _i, _j, _len, _len2, _ref, _ref2;
    __extends(StorageAdapter, Batman.Object);
    function StorageAdapter(model) {
      StorageAdapter.__super__.constructor.call(this, {
        model: model
      });
    }
    StorageAdapter.prototype.isStorageAdapter = true;
    StorageAdapter.prototype.modelKey = function(record) {
      var model;
      model = (record != null ? record.constructor : void 0) || this.model;
      return model.get('storageKey') || helpers.pluralize(helpers.underscore($functionName(model)));
    };
    StorageAdapter.prototype._batman.check(StorageAdapter.prototype);
    _ref = ['all', 'create', 'read', 'readAll', 'update', 'destroy'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      k = _ref[_i];
      _ref2 = ['before', 'after'];
      _fn = __bind(function(k, time) {
        var key;
        key = "" + time + (helpers.capitalize(k));
        return this.prototype[key] = function(filter) {
          var _base, _name;
          this._batman.check(this);
          return ((_base = this._batman)[_name = "" + key + "Filters"] || (_base[_name] = [])).push(filter);
        };
      }, StorageAdapter);
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        time = _ref2[_j];
        _fn(k, time);
      }
    }
    StorageAdapter.prototype.before = function() {
      var callback, k, keys, _k, _l, _len3, _results;
      keys = 2 <= arguments.length ? __slice.call(arguments, 0, _k = arguments.length - 1) : (_k = 0, []), callback = arguments[_k++];
      _results = [];
      for (_l = 0, _len3 = keys.length; _l < _len3; _l++) {
        k = keys[_l];
        _results.push(this["before" + (helpers.capitalize(k))](callback));
      }
      return _results;
    };
    StorageAdapter.prototype.after = function() {
      var callback, k, keys, _k, _l, _len3, _results;
      keys = 2 <= arguments.length ? __slice.call(arguments, 0, _k = arguments.length - 1) : (_k = 0, []), callback = arguments[_k++];
      _results = [];
      for (_l = 0, _len3 = keys.length; _l < _len3; _l++) {
        k = keys[_l];
        _results.push(this["after" + (helpers.capitalize(k))](callback));
      }
      return _results;
    };
    StorageAdapter.prototype._filterData = function() {
      var action, data, prefix;
      prefix = arguments[0], action = arguments[1], data = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      return (this._batman.get("" + prefix + (helpers.capitalize(action)) + "Filters") || []).concat(this._batman.get("" + prefix + "AllFilters") || []).reduce(__bind(function(filteredData, filter) {
        return filter.call(this, filteredData);
      }, this), data);
    };
    StorageAdapter.prototype.getRecordFromData = function(data) {
      var record;
      record = new this.model();
      record.fromJSON(data);
      return record;
    };
    return StorageAdapter;
  }).call(this);
  $passError = function(f) {
    return function(filterables) {
      var err;
      if (filterables[0]) {
        return filterables;
      } else {
        err = filterables.shift();
        filterables = f.call(this, filterables);
        filterables.unshift(err);
        return filterables;
      }
    };
  };
  Batman.LocalStorage = (function() {
    __extends(LocalStorage, Batman.StorageAdapter);
    function LocalStorage() {
      if (typeof window.localStorage === 'undefined') {
        return null;
      }
      LocalStorage.__super__.constructor.apply(this, arguments);
      this.storage = localStorage;
      return;
    }
    LocalStorage.prototype.storageRegExp = function(record) {
      return new RegExp("^" + (this.modelKey(record)) + "(\\d+)$");
    };
    LocalStorage.prototype.idForRecord = function(record) {
      var nextId, re;
      re = this.storageRegExp(record);
      nextId = 1;
      this._forAllRecords(function(k, v) {
        var matches;
        if (matches = re.exec(k)) {
          return nextId = Math.max(nextId, parseInt(matches[1], 10) + 1);
        }
      });
      return nextId;
    };
    LocalStorage.prototype.before('create', 'update', $passError(function(_arg) {
      var options, record;
      record = _arg[0], options = _arg[1];
      return [JSON.stringify(record), options];
    }));
    LocalStorage.prototype.after('read', $passError(function(_arg) {
      var attributes, options, record;
      record = _arg[0], attributes = _arg[1], options = _arg[2];
      return [record.fromJSON(JSON.parse(attributes)), attributes, options];
    }));
    LocalStorage.prototype._forAllRecords = function(f) {
      var i, k, _ref, _results;
      _results = [];
      for (i = 0, _ref = this.storage.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        k = this.storage.key(i);
        _results.push(f.call(this, k, this.storage.getItem(k)));
      }
      return _results;
    };
    LocalStorage.prototype.getRecordFromData = function(data) {
      var record;
      record = LocalStorage.__super__.getRecordFromData.apply(this, arguments);
      this.nextId = Math.max(this.nextId, parseInt(record.get('id'), 10) + 1);
      return record;
    };
    LocalStorage.prototype.update = function(record, options, callback) {
      var err, id, recordToSave, _ref;
      _ref = this._filterData('before', 'update', void 0, record, options), err = _ref[0], recordToSave = _ref[1];
      if (!err) {
        id = record.get('id');
        if (id != null) {
          this.storage.setItem(this.modelKey(record) + id, recordToSave);
        } else {
          err = new Error("Couldn't get record primary key.");
        }
      }
      return callback.apply(null, this._filterData('after', 'update', err, record, options));
    };
    LocalStorage.prototype.create = function(record, options, callback) {
      var err, id, key, recordToSave, _ref;
      _ref = this._filterData('before', 'create', void 0, record, options), err = _ref[0], recordToSave = _ref[1];
      if (!err) {
        id = record.get('id') || record.set('id', this.idForRecord(record));
        if (id != null) {
          key = this.modelKey(record) + id;
          if (this.storage.getItem(key)) {
            err = new Error("Can't create because the record already exists!");
          } else {
            this.storage.setItem(key, recordToSave);
          }
        } else {
          err = new Error("Couldn't set record primary key on create!");
        }
      }
      return callback.apply(null, this._filterData('after', 'create', err, record, options));
    };
    LocalStorage.prototype.read = function(record, options, callback) {
      var attrs, err, id, _ref;
      _ref = this._filterData('before', 'read', void 0, record, options), err = _ref[0], record = _ref[1];
      id = record.get('id');
      if (!err) {
        if (id != null) {
          attrs = this.storage.getItem(this.modelKey(record) + id);
          if (!attrs) {
            err = new Error("Couldn't find record!");
          }
        } else {
          err = new Error("Couldn't get record primary key.");
        }
      }
      return callback.apply(null, this._filterData('after', 'read', err, record, attrs, options));
    };
    LocalStorage.prototype.readAll = function(proto, options, callback) {
      var err, re, records, _ref;
      records = [];
      _ref = this._filterData('before', 'readAll', void 0, options), err = _ref[0], options = _ref[1];
      if (!err) {
        re = this.storageRegExp(proto);
        this._forAllRecords(function(storageKey, data) {
          var keyMatches;
          if (keyMatches = re.exec(storageKey)) {
            return records.push({
              data: data,
              id: keyMatches[1]
            });
          }
        });
      }
      return callback.apply(null, this._filterData('after', 'readAll', err, records, options));
    };
    LocalStorage.prototype.after('readAll', $passError(function(_arg) {
      var allAttributes, attributes, data, options;
      allAttributes = _arg[0], options = _arg[1];
      allAttributes = (function() {
        var _i, _len, _name, _results;
        _results = [];
        for (_i = 0, _len = allAttributes.length; _i < _len; _i++) {
          attributes = allAttributes[_i];
          data = JSON.parse(attributes.data);
          data[_name = this.model.primaryKey] || (data[_name] = parseInt(attributes.id, 10));
          _results.push(data);
        }
        return _results;
      }).call(this);
      return [allAttributes, options];
    }));
    LocalStorage.prototype.after('readAll', $passError(function(_arg) {
      var allAttributes, data, k, match, matches, options, v, _i, _len;
      allAttributes = _arg[0], options = _arg[1];
      matches = [];
      for (_i = 0, _len = allAttributes.length; _i < _len; _i++) {
        data = allAttributes[_i];
        match = true;
        for (k in options) {
          v = options[k];
          if (data[k] !== v) {
            match = false;
            break;
          }
        }
        if (match) {
          matches.push(data);
        }
      }
      return [matches, options];
    }));
    LocalStorage.prototype.after('readAll', $passError(function(_arg) {
      var data, filteredAttributes, options;
      filteredAttributes = _arg[0], options = _arg[1];
      return [
        (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = filteredAttributes.length; _i < _len; _i++) {
            data = filteredAttributes[_i];
            _results.push(this.getRecordFromData(data));
          }
          return _results;
        }).call(this), filteredAttributes, options
      ];
    }));
    LocalStorage.prototype.destroy = function(record, options, callback) {
      var err, id, key, _ref;
      _ref = this._filterData('before', 'destroy', void 0, record, options), err = _ref[0], record = _ref[1];
      if (!err) {
        id = record.get('id');
        if (id != null) {
          key = this.modelKey(record) + id;
          if (this.storage.getItem(key)) {
            this.storage.removeItem(key);
          } else {
            err = new Error("Can't delete nonexistant record!");
          }
        } else {
          err = new Error("Can't delete record without an primary key!");
        }
      }
      return callback.apply(null, this._filterData('after', 'destroy', err, record, options));
    };
    return LocalStorage;
  })();
  Batman.RestStorage = (function() {
    __extends(RestStorage, Batman.StorageAdapter);
    RestStorage.prototype.defaultOptions = {
      type: 'json'
    };
    RestStorage.prototype.recordJsonNamespace = false;
    RestStorage.prototype.collectionJsonNamespace = false;
    RestStorage.prototype.serializeAsForm = true;
    function RestStorage() {
      RestStorage.__super__.constructor.apply(this, arguments);
      this.defaultOptions = $mixin({}, this.defaultOptions);
    }
    RestStorage.prototype.recordJsonNamespace = function(record) {
      return helpers.singularize(this.modelKey(record));
    };
    RestStorage.prototype.collectionJsonNamespace = function(proto) {
      return helpers.pluralize(this.modelKey(proto));
    };
    RestStorage.prototype.before('create', 'update', $passError(function(_arg) {
      var json, namespace, options, record, x;
      record = _arg[0], options = _arg[1];
      json = record.toJSON();
      record = (namespace = this.recordJsonNamespace(record)) ? (x = {}, x[namespace] = json, x) : json;
      if (!this.serializeAsForm) {
        record = JSON.stringify(record);
      }
      return [record, options];
    }));
    RestStorage.prototype.after('create', 'read', 'readAll', 'update', 'destroy', function(_arg) {
      var data, error, options, record;
      error = _arg[0], record = _arg[1], data = _arg[2], options = _arg[3];
      if (!error) {
        if (typeof data === 'string') {
          try {
            data = JSON.parse(data);
          } catch (e) {
            error = e;
          }
        }
      }
      return [error, record, data, options];
    });
    RestStorage.prototype.after('create', 'read', 'update', $passError(function(_arg) {
      var data, namespace, options, record;
      record = _arg[0], data = _arg[1], options = _arg[2];
      namespace = this.recordJsonNamespace(record);
      if (namespace && (data[namespace] != null)) {
        data = data[namespace];
      }
      return [record, data, options];
    }));
    RestStorage.prototype.after('create', 'read', 'update', $passError(function(_arg) {
      var data, options, record;
      record = _arg[0], data = _arg[1], options = _arg[2];
      record.fromJSON(data);
      return [record, data, options];
    }));
    RestStorage.prototype.optionsForRecord = function(record, recordOptions, callback) {
      var id, url;
      if (record.url) {
        url = typeof record.url === 'function' ? record.url(recordOptions) : record.url;
      } else {
        url = record.constructor.url ? typeof record.constructor.url === 'function' ? record.constructor.url(recordOptions) : record.constructor.url : "/" + (this.modelKey(record));
        if (recordOptions.idRequired) {
          id = record.get('id');
          if (!(id != null)) {
            callback.call(this, new Error("Couldn't get record primary key!"));
            return;
          }
          url = url + "/" + id;
        }
      }
      if (!url) {
        return callback.call(this, new Error("Couldn't get model url!"));
      } else {
        return callback.call(this, void 0, $mixin({}, this.defaultOptions, {
          url: url
        }));
      }
    };
    RestStorage.prototype.optionsForCollection = function(model, recordsOptions, callback) {
      var url;
      if (model.url) {
        url = typeof model.url === 'function' ? model.url(recordsOptions) : model.url;
      } else {
        url = "/" + (this.modelKey(model.prototype));
      }
      if (!url) {
        return callback.call(this, new Error("Couldn't get collection url!"));
      } else {
        return callback.call(this, void 0, $mixin({}, this.defaultOptions, {
          url: url,
          data: $mixin({}, this.defaultOptions.data, recordsOptions)
        }));
      }
    };
    RestStorage.prototype.create = function(record, recordOptions, callback) {
      return this.optionsForRecord(record, {
        idRequired: false
      }, function(err, options) {
        var data, _ref;
        _ref = this._filterData('before', 'create', err, record, recordOptions), err = _ref[0], data = _ref[1];
        if (err) {
          callback(err);
          return;
        }
        return new Batman.Request($mixin(options, {
          data: data,
          method: 'POST',
          success: __bind(function(data) {
            return callback.apply(null, this._filterData('after', 'create', void 0, record, data, recordOptions));
          }, this),
          error: __bind(function(error) {
            return callback.apply(null, this._filterData('after', 'create', error, record, error.request.get('response'), recordOptions));
          }, this)
        }));
      });
    };
    RestStorage.prototype.update = function(record, recordOptions, callback) {
      return this.optionsForRecord(record, {
        idRequired: true
      }, function(err, options) {
        var data, _ref;
        _ref = this._filterData('before', 'update', err, record, recordOptions), err = _ref[0], data = _ref[1];
        if (err) {
          callback(err);
          return;
        }
        return new Batman.Request($mixin(options, {
          data: data,
          method: 'PUT',
          success: __bind(function(data) {
            return callback.apply(null, this._filterData('after', 'update', void 0, record, data, recordOptions));
          }, this),
          error: __bind(function(error) {
            return callback.apply(null, this._filterData('after', 'update', error, record, error.request.get('response'), recordOptions));
          }, this)
        }));
      });
    };
    RestStorage.prototype.read = function(record, recordOptions, callback) {
      return this.optionsForRecord(record, {
        idRequired: true
      }, function(err, options) {
        var _ref;
        _ref = this._filterData('before', 'read', err, record, recordOptions), err = _ref[0], record = _ref[1], recordOptions = _ref[2];
        if (err) {
          callback(err);
          return;
        }
        return new Batman.Request($mixin(options, {
          data: recordOptions,
          method: 'GET',
          success: __bind(function(data) {
            return callback.apply(null, this._filterData('after', 'read', void 0, record, data, recordOptions));
          }, this),
          error: __bind(function(error) {
            return callback.apply(null, this._filterData('after', 'read', error, record, error.request.get('response'), recordOptions));
          }, this)
        }));
      });
    };
    RestStorage.prototype.readAll = function(proto, recordsOptions, callback) {
      return this.optionsForCollection(proto.constructor, recordsOptions, function(err, options) {
        var _ref;
        _ref = this._filterData('before', 'readAll', err, recordsOptions), err = _ref[0], recordsOptions = _ref[1];
        if (err) {
          callback(err);
          return;
        }
        if (recordsOptions && recordsOptions.url) {
          options.url = recordsOptions.url;
          delete recordsOptions.url;
        }
        return new Batman.Request($mixin(options, {
          data: recordsOptions,
          method: 'GET',
          success: __bind(function(data) {
            return callback.apply(null, this._filterData('after', 'readAll', void 0, data, proto, recordsOptions));
          }, this),
          error: __bind(function(error) {
            return callback.apply(null, this._filterData('after', 'readAll', error, error.request.get('response'), proto, recordsOptions));
          }, this)
        }));
      });
    };
    RestStorage.prototype.after('readAll', $passError(function(_arg) {
      var data, namespace, options, proto, recordData;
      data = _arg[0], proto = _arg[1], options = _arg[2];
      namespace = this.collectionJsonNamespace(proto);
      recordData = namespace && (data[namespace] != null) ? data[namespace] : data;
      return [recordData, data, proto, options];
    }));
    RestStorage.prototype.after('readAll', $passError(function(_arg) {
      var attributes, options, proto, recordData, serverData;
      recordData = _arg[0], serverData = _arg[1], proto = _arg[2], options = _arg[3];
      return [
        (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = recordData.length; _i < _len; _i++) {
            attributes = recordData[_i];
            _results.push(this.getRecordFromData(attributes));
          }
          return _results;
        }).call(this), serverData, proto, options
      ];
    }));
    RestStorage.prototype.destroy = function(record, recordOptions, callback) {
      return this.optionsForRecord(record, {
        idRequired: true
      }, function(err, options) {
        var _ref;
        _ref = this._filterData('before', 'destroy', err, record, recordOptions), err = _ref[0], record = _ref[1], recordOptions = _ref[2];
        if (err) {
          callback(err);
          return;
        }
        return new Batman.Request($mixin(options, {
          method: 'DELETE',
          success: __bind(function(data) {
            return callback.apply(null, this._filterData('after', 'destroy', void 0, record, data, recordOptions));
          }, this),
          error: __bind(function(error) {
            return callback.apply(null, this._filterData('after', 'destroy', error, record, error.request.get('response'), recordOptions));
          }, this)
        }));
      });
    };
    return RestStorage;
  })();
  Batman.ViewSourceCache = (function() {
    __extends(ViewSourceCache, Batman.Object);
    function ViewSourceCache() {
      ViewSourceCache.__super__.constructor.apply(this, arguments);
      this.sources = {};
      this.requests = {};
    }
    ViewSourceCache.prototype.propertyClass = Batman.Property;
    ViewSourceCache.accessor({
      get: function(path) {
        path = Batman.Navigator.normalizePath(path);
        if (this.sources[path] != null) {
          return this.sources[path];
        }
        if (this.requests[path] == null) {
          this.requests = new Batman.Request({
            url: path + '.html',
            type: 'html',
            success: __bind(function(response) {
              return this.set(path, response);
            }, this),
            error: function(response) {
              throw new Error("Could not load view from " + path);
            }
          });
        }
      },
      set: function(k, v) {
        return this.sources[k] = v;
      }
    });
    ViewSourceCache.prototype.prefetch = function(path) {
      this.get(path);
      return true;
    };
    return ViewSourceCache;
  })();
  Batman.View = (function() {
    __extends(View, Batman.Object);
    function View() {
      var context, node;
      this.contexts = [];
      View.__super__.constructor.apply(this, arguments);
      if (context = this.get('context')) {
        this.contexts.push(context);
        this.unset('context');
      }
      if (node = this.get('node')) {
        this.render(node);
      } else {
        this.observe('node', __bind(function(node) {
          return this.render(node);
        }, this));
      }
    }
    View.sourceCache = new Batman.ViewSourceCache();
    View.prototype.source = '';
    View.prototype.html = '';
    View.prototype.node = null;
    View.prototype.contentFor = null;
    View.prototype.event('ready').oneShot = true;
    View.prototype.prefix = 'views';
    View.accessor('html', {
      get: function() {
        var path, source;
        if (this.html && this.html.length > 0) {
          return this.html;
        }
        source = this.get('source');
        if (!source) {
          return;
        }
        path = Batman.Navigator.normalizePath(this.prefix, source);
        return this.html = this.constructor.sourceCache.get(path);
      },
      set: function(_, html) {
        return this.html = html;
      }
    });
    View.accessor('node', {
      get: function() {
        var html;
        if (!this.node) {
          html = this.get('html');
          if (!(html && html.length > 0)) {
            return;
          }
          this.node = document.createElement('div');
          $setInnerHTML(this.node, html);
        }
        return this.node;
      },
      set: function(_, node) {
        return this.node = node;
      }
    });
    View.prototype.render = function(node) {
      this.event('ready').resetOneShot();
      if (this._renderer) {
        this._renderer.forgetAll();
      }
      if (node) {
        this._renderer = new Batman.Renderer(node, __bind(function() {
          var contents, yieldTo;
          yieldTo = this.contentFor;
          if (typeof yieldTo === 'string') {
            this.contentFor = Batman.DOM._yields[yieldTo];
          }
          if (this.contentFor && node) {
            $setInnerHTML(this.contentFor, '');
            return $appendChild(this.contentFor, node);
          } else if (yieldTo) {
            if (contents = Batman.DOM._yieldContents[yieldTo]) {
              return contents.push(node);
            } else {
              return Batman.DOM._yieldContents[yieldTo] = [node];
            }
          }
        }, this), this.contexts);
        return this._renderer.on('rendered', __bind(function() {
          return this.fire('ready', node);
        }, this));
      }
    };
    return View;
  })();
  Batman.Renderer = (function() {
    var bindingRegexp, k, sortBindings, _i, _len, _ref;
    __extends(Renderer, Batman.Object);
    Renderer.prototype.deferEvery = 50;
    function Renderer(node, callback, contexts) {
      var _ref;
      this.node = node;
      if (contexts == null) {
        contexts = [];
      }
      this.resume = __bind(this.resume, this);
      this.start = __bind(this.start, this);
      Renderer.__super__.constructor.call(this);
      if (callback != null) {
        this.on('parsed', callback);
      }
      this.context = contexts instanceof Batman.RenderContext ? contexts : (_ref = Batman.RenderContext).start.apply(_ref, contexts);
      this.timeout = $setImmediate(this.start);
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
      this.fire('parsed');
      return this.fire('rendered');
    };
    Renderer.prototype.stop = function() {
      clearTimeout(this.timeout);
      return this.fire('stopped');
    };
    Renderer.prototype.forgetAll = function() {};
    _ref = ['parsed', 'rendered', 'stopped'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      k = _ref[_i];
      Renderer.prototype.event(k).oneShot = true;
    }
    bindingRegexp = /^data\-(.*)/;
    sortBindings = function(a, b) {
      if (a[0] === 'foreach') {
        return -1;
      } else if (b[0] === 'foreach') {
        return 1;
      } else if (a[0] === 'formfor') {
        return -1;
      } else if (b[0] === 'formfor') {
        return 1;
      } else if (a[0] === 'bind') {
        return -1;
      } else if (b[0] === 'bind') {
        return 1;
      } else {
        return 0;
      }
    };
    Renderer.prototype.parseNode = function(node) {
      var attr, bindings, key, name, nextNode, oldContext, readerArgs, result, skipChildren, varIndex, _base, _base2, _j, _len2, _name, _name2, _ref2;
      if (this.deferEvery && (new Date - this.startTime) > this.deferEvery) {
        this.resumeNode = node;
        this.timeout = $setImmediate(this.resume);
        return;
      }
      if (node.getAttribute && node.attributes) {
        bindings = (function() {
          var _j, _len2, _ref2, _ref3, _results;
          _ref2 = node.attributes;
          _results = [];
          for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
            attr = _ref2[_j];
            name = (_ref3 = attr.nodeName.match(bindingRegexp)) != null ? _ref3[1] : void 0;
            if (!name) {
              continue;
            }
            _results.push(~(varIndex = name.indexOf('-')) ? [name.substr(0, varIndex), name.substr(varIndex + 1), attr.value] : [name, attr.value]);
          }
          return _results;
        })();
        _ref2 = bindings.sort(sortBindings);
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          readerArgs = _ref2[_j];
          key = readerArgs[1];
          result = readerArgs.length === 2 ? typeof (_base = Batman.DOM.readers)[_name = readerArgs[0]] === "function" ? _base[_name](node, key, this.context, this) : void 0 : typeof (_base2 = Batman.DOM.attrReaders)[_name2 = readerArgs[0]] === "function" ? _base2[_name2](node, key, readerArgs[2], this.context, this) : void 0;
          if (result === false) {
            skipChildren = true;
            break;
          } else if (result instanceof Batman.RenderContext) {
            oldContext = this.context;
            this.context = result;
            $onParseExit(node, __bind(function() {
              return this.context = oldContext;
            }, this));
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
      sibling = node.nextSibling;
      $onParseExit(node).forEach(function(callback) {
        return callback();
      });
      if (this.node === node) {
        return;
      }
      if (sibling) {
        return sibling;
      }
      nextParent = node;
      while (nextParent = nextParent.parentNode) {
        $onParseExit(nextParent).forEach(function(callback) {
          return callback();
        });
        if (this.node === nextParent) {
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
  Batman.RenderContext = (function() {
    var ContextProxy;
    RenderContext.start = function() {
      var context, contexts, node;
      contexts = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      node = new this(window);
      if (Batman.currentApp) {
        contexts.push(Batman.currentApp);
      }
      while (context = contexts.pop()) {
        node = node.descend(context);
      }
      return node;
    };
    function RenderContext(object, parent) {
      this.object = object;
      this.parent = parent;
    }
    RenderContext.prototype.findKey = function(key) {
      var base, currentNode, val;
      base = key.split('.')[0].split('|')[0].trim();
      currentNode = this;
      while (currentNode) {
        if (currentNode.object.get != null) {
          val = currentNode.object.get(base);
        } else {
          val = currentNode.object[base];
        }
        if (typeof val !== 'undefined') {
          return [$get(currentNode.object, key), currentNode.object];
        }
        currentNode = currentNode.parent;
      }
      return [container.get(key), container];
    };
    RenderContext.prototype.descend = function(object, scopedKey) {
      var oldObject;
      if (scopedKey) {
        oldObject = object;
        object = new Batman.Object();
        object[scopedKey] = oldObject;
      }
      return new this.constructor(object, this);
    };
    RenderContext.prototype.descendWithKey = function(key, scopedKey) {
      var proxy;
      proxy = new ContextProxy(this, key);
      return this.descend(proxy, scopedKey);
    };
    RenderContext.prototype.chain = function() {
      var parent, x;
      x = [];
      parent = this;
      while (parent) {
        x.push(parent.object);
        parent = parent.parent;
      }
      return x;
    };
    RenderContext.ContextProxy = ContextProxy = (function() {
      __extends(ContextProxy, Batman.Object);
      ContextProxy.prototype.isContextProxy = true;
      ContextProxy.accessor('proxiedObject', function() {
        return this.binding.get('filteredValue');
      });
      ContextProxy.accessor({
        get: function(key) {
          return this.get("proxiedObject." + key);
        },
        set: function(key, value) {
          return this.set("proxiedObject." + key, value);
        },
        unset: function(key) {
          return this.unset("proxiedObject." + key);
        }
      });
      function ContextProxy(renderContext, keyPath, localKey) {
        this.renderContext = renderContext;
        this.keyPath = keyPath;
        this.localKey = localKey;
        this.binding = new Batman.DOM.AbstractBinding(void 0, this.keyPath, this.renderContext);
      }
      return ContextProxy;
    })();
    return RenderContext;
  }).call(this);
  Batman.DOM = {
    readers: {
      target: function(node, key, context, renderer) {
        Batman.DOM.readers.bind(node, key, context, renderer, 'nodeChange');
        return true;
      },
      source: function(node, key, context, renderer) {
        Batman.DOM.readers.bind(node, key, context, renderer, 'dataChange');
        return true;
      },
      bind: function(node, key, context, renderer, only) {
        var bindingClass;
        bindingClass = false;
        switch (node.nodeName.toLowerCase()) {
          case 'input':
            switch (node.getAttribute('type')) {
              case 'checkbox':
                Batman.DOM.attrReaders.bind(node, 'checked', key, context, renderer, only);
                return true;
              case 'radio':
                bindingClass = Batman.DOM.RadioBinding;
                break;
              case 'file':
                bindingClass = Batman.DOM.FileBinding;
            }
            break;
          case 'select':
            bindingClass = Batman.DOM.SelectBinding;
        }
        bindingClass || (bindingClass = Batman.DOM.Binding);
        (function(func, args, ctor) {
          ctor.prototype = func.prototype;
          var child = new ctor, result = func.apply(child, args);
          return typeof result === "object" ? result : child;
        })(bindingClass, arguments, function() {});
        return true;
      },
      context: function(node, key, context, renderer) {
        return context.descendWithKey(key);
      },
      mixin: function(node, key, context, renderer) {
        new Batman.DOM.MixinBinding(node, key, context.descend(Batman.mixins), renderer);
        return true;
      },
      showif: function(node, key, context, parentRenderer, invert) {
        new Batman.DOM.ShowHideBinding(node, key, context, parentRenderer, false, invert);
        return true;
      },
      hideif: function() {
        var _ref;
        return (_ref = Batman.DOM.readers).showif.apply(_ref, __slice.call(arguments).concat([true]));
      },
      route: function(node, key, context) {
        var action, app, container, dispatcher, isHash, model, name, url, _ref, _ref2, _ref3;
        if (key.substr(0, 1) === '/') {
          url = key;
        } else {
          isHash = key.indexOf('#') > 1;
          _ref = isHash ? key.split('#') : key.split('/'), key = _ref[0], action = _ref[1];
          _ref2 = context.findKey('dispatcher'), dispatcher = _ref2[0], app = _ref2[1];
          if (!isHash) {
            _ref3 = context.findKey(key), model = _ref3[0], container = _ref3[1];
          }
          dispatcher || (dispatcher = Batman.currentApp.dispatcher);
          if (isHash) {
            url = dispatcher.findUrl({
              controller: key,
              action: action
            });
          } else if (model instanceof Batman.Model) {
            action || (action = 'show');
            name = helpers.underscore(helpers.pluralize($functionName(model.constructor)));
            url = dispatcher.findUrl({
              resource: name,
              id: model.get('id'),
              action: action
            });
          } else if (model != null ? model.prototype : void 0) {
            action || (action = 'index');
            name = helpers.underscore(helpers.pluralize($functionName(model)));
            url = dispatcher.findUrl({
              resource: name,
              action: action
            });
          }
        }
        if (!url) {
          return;
        }
        if (node.nodeName.toUpperCase() === 'A') {
          node.href = Batman.Navigator.defaultClass().prototype.linkTo(url);
        }
        Batman.DOM.events.click(node, function() {
          return $redirect(url);
        });
        return true;
      },
      partial: function(node, path, context, renderer) {
        var view;
        renderer.prevent('rendered');
        view = new Batman.View({
          source: path,
          contentFor: node,
          contexts: context.chain()
        });
        view.on('ready', function() {
          return renderer.allowAndFire('rendered');
        });
        return true;
      },
      defineview: function(node, name, context, renderer) {
        $onParseExit(node, function() {
          return $removeNode(node);
        });
        Batman.View.sourceCache.set(Batman.Navigator.normalizePath(Batman.View.prototype.prefix, name), node.innerHTML);
        return false;
      },
      yield: function(node, key) {
        $setImmediate(function() {
          return Batman.DOM.yield(key, node);
        });
        return true;
      },
      contentfor: function(node, key) {
        $setImmediate(function() {
          return Batman.DOM.contentFor(key, node);
        });
        return true;
      },
      replace: function(node, key) {
        $setImmediate(function() {
          return Batman.DOM.replace(key, node);
        });
        return true;
      }
    },
    _yieldContents: {},
    _yields: {},
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
      source: function(node, attr, key, context, renderer) {
        return Batman.DOM.attrReaders.bind(node, attr, key, context, renderer, 'dataChange');
      },
      bind: function(node, attr, key, context, renderer, only) {
        var bindingClass;
        bindingClass = (function() {
          switch (attr) {
            case 'checked':
            case 'disabled':
            case 'selected':
              return Batman.DOM.CheckedBinding;
            case 'value':
            case 'href':
            case 'src':
            case 'size':
              return Batman.DOM.NodeAttributeBinding;
            case 'class':
              return Batman.DOM.ClassBinding;
            case 'style':
              return Batman.DOM.StyleBinding;
            default:
              return Batman.DOM.AttributeBinding;
          }
        })();
        (function(func, args, ctor) {
          ctor.prototype = func.prototype;
          var child = new ctor, result = func.apply(child, args);
          return typeof result === "object" ? result : child;
        })(bindingClass, arguments, function() {});
        return true;
      },
      context: function(node, contextName, key, context) {
        return context.descendWithKey(key, contextName);
      },
      event: function(node, eventName, key, context) {
        (function(func, args, ctor) {
          ctor.prototype = func.prototype;
          var child = new ctor, result = func.apply(child, args);
          return typeof result === "object" ? result : child;
        })(Batman.DOM.EventBinding, arguments, function() {});
        return true;
      },
      addclass: function(node, className, key, context, parentRenderer, invert) {
        new Batman.DOM.AddClassBinding(node, className, key, context, parentRenderer, false, invert);
        return true;
      },
      removeclass: function(node, className, key, context, parentRenderer) {
        return Batman.DOM.attrReaders.addclass(node, className, key, context, parentRenderer, true);
      },
      foreach: function(node, iteratorName, key, context, parentRenderer) {
        (function(func, args, ctor) {
          ctor.prototype = func.prototype;
          var child = new ctor, result = func.apply(child, args);
          return typeof result === "object" ? result : child;
        })(Batman.DOM.IteratorBinding, arguments, function() {});
        return false;
      },
      formfor: function(node, localName, key, context) {
        Batman.DOM.events.submit(node, function(node, e) {
          return $preventDefault(e);
        });
        return context.descendWithKey(key, localName);
      }
    },
    events: {
      click: function(node, callback, eventName) {
        if (eventName == null) {
          eventName = 'click';
        }
        $addEventListener(node, eventName, function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          callback.apply(null, [node].concat(__slice.call(args)));
          return $preventDefault(args[0]);
        });
        if (node.nodeName.toUpperCase() === 'A' && !node.href) {
          node.href = '#';
        }
        return node;
      },
      doubleclick: function(node, callback) {
        return Batman.DOM.events.click(node, callback, 'dblclick');
      },
      change: function(node, callback) {
        var eventName, eventNames, oldCallback, _i, _len, _results;
        eventNames = (function() {
          switch (node.nodeName.toUpperCase()) {
            case 'TEXTAREA':
              return ['keyup', 'change'];
            case 'INPUT':
              if (node.type.toUpperCase() === 'TEXT') {
                oldCallback = callback;
                callback = function(e) {
                  var _ref;
                  if (e.type === 'keyup' && (13 <= (_ref = e.keyCode) && _ref <= 14)) {
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
        _results = [];
        for (_i = 0, _len = eventNames.length; _i < _len; _i++) {
          eventName = eventNames[_i];
          _results.push($addEventListener(node, eventName, function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            return callback.apply(null, [node].concat(__slice.call(args)));
          }));
        }
        return _results;
      },
      submit: function(node, callback) {
        if (Batman.DOM.nodeIsEditable(node)) {
          $addEventListener(node, 'keyup', function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            if (args[0].keyCode === 13 || args[0].which === 13 || args[0].keyIdentifier === 'Enter' || args[0].key === 'Enter') {
              $preventDefault(args[0]);
              return callback.apply(null, [node].concat(__slice.call(args)));
            }
          });
        } else {
          $addEventListener(node, 'submit', function() {
            var args;
            args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
            $preventDefault(args[0]);
            return callback.apply(null, [node].concat(__slice.call(args)));
          });
        }
        return node;
      },
      other: function(node, eventName, callback) {
        return $addEventListener(node, eventName, function() {
          var args;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          return callback.apply(null, [node].concat(__slice.call(args)));
        });
      }
    },
    yield: function(name, node, _replaceContent) {
      var content, contents, _i, _len;
      if (_replaceContent == null) {
        _replaceContent = !Batman.data(node, 'yielded');
      }
      Batman.DOM._yields[name] = node;
      if (contents = Batman.DOM._yieldContents[name]) {
        if (_replaceContent) {
          $setInnerHTML(node, '', true);
        }
        for (_i = 0, _len = contents.length; _i < _len; _i++) {
          content = contents[_i];
          if (!Batman.data(content, 'yielded')) {
            if ($isChildOf(node, content)) {
              content = content.cloneNode(true);
            }
            $appendChild(node, content, true);
            Batman.data(content, 'yielded', true);
          }
        }
        delete Batman.DOM._yieldContents[name];
        return Batman.data(node, 'yielded', true);
      }
    },
    contentFor: function(name, node, _replaceContent) {
      var contents, yieldingNode;
      contents = Batman.DOM._yieldContents[name];
      if (contents) {
        contents.push(node);
      } else {
        Batman.DOM._yieldContents[name] = [node];
      }
      if (yieldingNode = Batman.DOM._yields[name]) {
        return Batman.DOM.yield(name, yieldingNode, _replaceContent);
      }
    },
    replace: function(name, node) {
      return Batman.DOM.contentFor(name, node, true);
    },
    trackBinding: $trackBinding = function(binding, node) {
      var bindings;
      if (bindings = Batman.data(node, 'bindings')) {
        return bindings.add(binding);
      } else {
        return Batman.data(node, 'bindings', new Batman.SimpleSet(binding));
      }
    },
    unbindNode: $unbindNode = function(node) {
      var bindings, eventListeners, eventName, listeners;
      if (bindings = Batman.data(node, 'bindings')) {
        bindings.forEach(function(binding) {
          return binding.destroy();
        });
      }
      if (listeners = Batman.data(node, 'listeners')) {
        for (eventName in listeners) {
          eventListeners = listeners[eventName];
          eventListeners.forEach(function(listener) {
            return $removeEventListener(node, eventName, listener);
          });
        }
      }
      return Batman.removeData(node);
    },
    unbindTree: $unbindTree = function(node, unbindRoot) {
      var child, _i, _len, _ref, _results;
      if (unbindRoot == null) {
        unbindRoot = true;
      }
      if ((node != null ? node.nodeType : void 0) !== 1) {
        return;
      }
      if (unbindRoot) {
        $unbindNode(node);
      }
      _ref = node.childNodes;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        _results.push($unbindTree(child));
      }
      return _results;
    },
    setInnerHTML: $setInnerHTML = function() {
      var args, child, hide, html, node, _i, _len, _ref;
      node = arguments[0], html = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      _ref = node.childNodes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        if (hide = Batman.data(child, 'hide')) {
          hide.apply(child, args);
        }
      }
      $unbindTree(node, false);
      return node != null ? node.innerHTML = html : void 0;
    },
    removeNode: $removeNode = function(node) {
      var _ref;
      if (node != null) {
        if ((_ref = node.parentNode) != null) {
          _ref.removeChild(node);
        }
      }
      return Batman.DOM.didRemoveNode(node);
    },
    appendChild: $appendChild = function() {
      var args, child, parent, _ref;
      parent = arguments[0], child = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      if ((_ref = Batman.data(child, 'show')) != null) {
        _ref.apply(child, args);
      }
      return parent.appendChild(child);
    },
    valueForNode: function(node, value) {
      var isSetting;
      if (value == null) {
        value = '';
      }
      isSetting = arguments.length > 1;
      switch (node.nodeName.toUpperCase()) {
        case 'INPUT':
          if (isSetting) {
            return node.value = value;
          } else {
            return node.value;
          }
          break;
        case 'TEXTAREA':
          if (isSetting) {
            return node.innerHTML = node.value = value;
          } else {
            return node.innerHTML;
          }
          break;
        case 'SELECT':
          return node.value = value;
        default:
          if (isSetting) {
            return $setInnerHTML(node, value);
          } else {
            return node.innerHTML;
          }
      }
    },
    nodeIsEditable: function(node) {
      var _ref;
      return (_ref = node.nodeName.toUpperCase()) === 'INPUT' || _ref === 'TEXTAREA' || _ref === 'SELECT';
    },
    addEventListener: $addEventListener = function(node, eventName, callback) {
      var listeners;
      if (!(listeners = Batman.data(node, 'listeners'))) {
        listeners = Batman.data(node, 'listeners', {});
      }
      if (!listeners[eventName]) {
        listeners[eventName] = new Batman.Set;
      }
      listeners[eventName].add(callback);
      if ($hasAddEventListener) {
        return node.addEventListener(eventName, callback, false);
      } else {
        return node.attachEvent("on" + eventName, callback);
      }
    },
    removeEventListener: $removeEventListener = function(node, eventName, callback) {
      var eventListeners, listeners;
      if (listeners = Batman.data(node, 'listeners')) {
        if (eventListeners = listeners[eventName]) {
          eventListeners.remove(callback);
        }
      }
      if ($hasAddEventListener) {
        return node.removeEventListener(eventName, callback, false);
      } else {
        return node.detachEvent('on' + eventName, callback);
      }
    },
    hasAddEventListener: $hasAddEventListener = !!(typeof window !== "undefined" && window !== null ? window.addEventListener : void 0),
    didRemoveNode: function(node) {
      return $unbindTree(node);
    },
    onParseExit: $onParseExit = function(node, callback) {
      var set;
      set = Batman.data(node, 'onParseExit') || Batman.data(node, 'onParseExit', new Batman.SimpleSet);
      if (callback != null) {
        set.add(callback);
      }
      return set;
    }
  };
  Batman.DOM.AbstractBinding = (function() {
    var deProxy, get_dot_rx, get_rx, keypath_rx;
    __extends(AbstractBinding, Batman.Object);
    keypath_rx = /(^|,)\s*(?!(?:true|false)\s*(?:$|,))([a-zA-Z][\w\.]*[\?\!]?)\s*(?=$|,)/g;
    get_dot_rx = /(?:\]\.)(.+?)(?=[\[\.]|\s*\||$)/;
    get_rx = /(?!^\s*)\[(.*?)\]/g;
    deProxy = function(object) {
      if (object instanceof Batman.RenderContext.ContextProxy) {
        return object.get('proxiedObject');
      } else {
        return object;
      }
    };
    AbstractBinding.accessor('filteredValue', function() {
      var result, unfilteredValue;
      unfilteredValue = this.get('unfilteredValue');
      if (this.filterFunctions.length > 0) {
        developer.currentFilterStack = this.renderContext;
        result = this.filterFunctions.reduce(__bind(function(value, fn, i) {
          var args;
          args = this.filterArguments[i].map(function(argument) {
            if (argument._keypath) {
              return $get(argument.context, argument._keypath);
            } else {
              return argument;
            }
          });
          args.unshift(value);
          args = args.map(deProxy);
          return fn.apply(this.renderContext, args);
        }, this), unfilteredValue);
        developer.currentFilterStack = null;
        return result;
      } else {
        return deProxy(unfilteredValue);
      }
    });
    AbstractBinding.accessor('unfilteredValue', function() {
      var k;
      if (k = this.get('key')) {
        return this.get("keyContext." + k);
      } else {
        return this.get('value');
      }
    });
    AbstractBinding.accessor('keyContext', function() {
      return this.renderContext.findKey(this.key)[1];
    });
    AbstractBinding.prototype.bindImmediately = true;
    function AbstractBinding(node, keyPath, renderContext, renderer, only) {
      this.node = node;
      this.keyPath = keyPath;
      this.renderContext = renderContext;
      this.renderer = renderer;
      this.only = only != null ? only : false;
      if (this.node != null) {
        Batman.DOM.trackBinding(this, this.node);
      }
      this.parseFilter();
      if (this.bindImmediately) {
        this.bind();
      }
    }
    AbstractBinding.prototype.bind = function() {
      var shouldSet, _ref, _ref2;
      shouldSet = true;
      if ((this.node != null) && ((_ref = this.only) === false || _ref === 'nodeChange') && Batman.DOM.nodeIsEditable(this.node)) {
        Batman.DOM.events.change(this.node, __bind(function() {
          shouldSet = false;
          if (typeof this.nodeChange === "function") {
            this.nodeChange(this.node, this.get('keyContext') || this.value);
          }
          return shouldSet = true;
        }, this));
      }
      if ((_ref2 = this.only) === false || _ref2 === 'dataChange') {
        return this.observeAndFire('filteredValue', __bind(function(value) {
          if (shouldSet) {
            return typeof this.dataChange === "function" ? this.dataChange(value, this.node) : void 0;
          }
        }, this));
      }
    };
    AbstractBinding.prototype.destroy = function() {
      var _ref;
      this.forget();
      return (_ref = this._batman.properties) != null ? _ref.forEach(function(key, property) {
        return property.removeSourceHandlers();
      }) : void 0;
    };
    AbstractBinding.prototype.parseFilter = function() {
      var args, filter, filterName, filterString, filters, key, keyPath, orig, split;
      this.filterFunctions = [];
      this.filterArguments = [];
      keyPath = this.keyPath;
      while (get_dot_rx.test(keyPath)) {
        keyPath = keyPath.replace(get_dot_rx, "]['$1']");
      }
      filters = keyPath.replace(get_rx, " | get $1 ").replace(/'/g, '"').split(/(?!")\s+\|\s+(?!")/);
      try {
        key = this.parseSegment(orig = filters.shift())[0];
      } catch (e) {
        developer.warn(e);
        developer.error("Error! Couldn't parse keypath in \"" + orig + "\". Parsing error above.");
      }
      if (key && key._keypath) {
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
                developer.error("Bad filter arguments \"" + args + "\"!");
              }
            } else {
              this.filterArguments.push([]);
            }
          } else {
            developer.error("Unrecognized filter '" + filterName + "' in key \"" + this.keyPath + "\"!");
          }
        }
        return this.filterArguments = this.filterArguments.map(__bind(function(argumentList) {
          return argumentList.map(__bind(function(argument) {
            var _, _ref;
            if (argument._keypath) {
              _ref = this.renderContext.findKey(argument._keypath), _ = _ref[0], argument.context = _ref[1];
            }
            return argument;
          }, this));
        }, this));
      }
    };
    AbstractBinding.prototype.parseSegment = function(segment) {
      return JSON.parse("[" + segment.replace(keypath_rx, "$1{\"_keypath\": \"$2\"}") + "]");
    };
    return AbstractBinding;
  })();
  Batman.DOM.AbstractAttributeBinding = (function() {
    __extends(AbstractAttributeBinding, Batman.DOM.AbstractBinding);
    function AbstractAttributeBinding() {
      var args, attributeName, node;
      node = arguments[0], attributeName = arguments[1], args = 3 <= arguments.length ? __slice.call(arguments, 2) : [];
      this.attributeName = attributeName;
      AbstractAttributeBinding.__super__.constructor.apply(this, [node].concat(__slice.call(args)));
    }
    return AbstractAttributeBinding;
  })();
  Batman.DOM.AbstractCollectionBinding = (function() {
    __extends(AbstractCollectionBinding, Batman.DOM.AbstractAttributeBinding);
    function AbstractCollectionBinding() {
      AbstractCollectionBinding.__super__.constructor.apply(this, arguments);
    }
    AbstractCollectionBinding.prototype.bindCollection = function(newCollection) {
      if (newCollection !== this.collection) {
        this.unbindCollection();
        this.collection = newCollection;
        if (this.collection) {
          if (this.collection.isObservable && this.collection.toArray) {
            this.collection.observe('toArray', this.handleArrayChanged);
          } else if (this.collection.isEventEmitter) {
            this.collection.on('itemsWereAdded', this.handleItemsWereAdded);
            this.collection.on('itemsWereRemoved', this.handleItemsWereRemoved);
          } else {
            return false;
          }
          return true;
        }
      }
      return false;
    };
    AbstractCollectionBinding.prototype.unbindCollection = function() {
      if (this.collection) {
        if (this.collection.isObservable && this.collection.toArray) {
          return this.collection.forget('toArray', this.handleArrayChanged);
        } else if (this.collection.isEventEmitter) {
          this.collection.event('itemsWereAdded').removeHandler(this.handleItemsWereAdded);
          return this.collection.event('itemsWereRemoved').removeHandler(this.handleItemsWereRemoved);
        }
      }
    };
    AbstractCollectionBinding.prototype.handleItemsWereAdded = function() {};
    AbstractCollectionBinding.prototype.handleItemsWereRemoved = function() {};
    AbstractCollectionBinding.prototype.handleArrayChanged = function() {};
    AbstractCollectionBinding.prototype.destroy = function() {
      this.unbindCollection();
      return AbstractCollectionBinding.__super__.destroy.apply(this, arguments);
    };
    return AbstractCollectionBinding;
  })();
  Batman.DOM.Binding = (function() {
    __extends(Binding, Batman.DOM.AbstractBinding);
    function Binding() {
      Binding.__super__.constructor.apply(this, arguments);
    }
    Binding.prototype.nodeChange = function(node, context) {
      if (this.key && this.filterFunctions.length === 0) {
        return this.get('keyContext').set(this.key, this.node.value);
      }
    };
    Binding.prototype.dataChange = function(value, node) {
      return Batman.DOM.valueForNode(this.node, value);
    };
    return Binding;
  })();
  Batman.DOM.AttributeBinding = (function() {
    __extends(AttributeBinding, Batman.DOM.AbstractAttributeBinding);
    function AttributeBinding() {
      AttributeBinding.__super__.constructor.apply(this, arguments);
    }
    AttributeBinding.prototype.dataChange = function(value) {
      return this.node.setAttribute(this.attributeName, value);
    };
    AttributeBinding.prototype.nodeChange = function(node) {
      return this.get('keyContext').set(this.key, Batman.DOM.attrReaders._parseAttribute(node.getAttribute(this.attributeName)));
    };
    return AttributeBinding;
  })();
  Batman.DOM.NodeAttributeBinding = (function() {
    __extends(NodeAttributeBinding, Batman.DOM.AbstractAttributeBinding);
    function NodeAttributeBinding() {
      NodeAttributeBinding.__super__.constructor.apply(this, arguments);
    }
    NodeAttributeBinding.prototype.dataChange = function(value) {
      return this.node[this.attributeName] = value;
    };
    NodeAttributeBinding.prototype.nodeChange = function(node) {
      return this.get('keyContext').set(this.key, Batman.DOM.attrReaders._parseAttribute(node[this.attributeName]));
    };
    return NodeAttributeBinding;
  })();
  Batman.DOM.ShowHideBinding = (function() {
    __extends(ShowHideBinding, Batman.DOM.AbstractBinding);
    function ShowHideBinding(node, className, key, context, parentRenderer, invert) {
      this.invert = invert != null ? invert : false;
      this.originalDisplay = node.style.display || '';
      ShowHideBinding.__super__.constructor.apply(this, arguments);
    }
    ShowHideBinding.prototype.dataChange = function(value) {
      var hide, _ref;
      if (!!value === !this.invert) {
        if ((_ref = Batman.data(this.node, 'show')) != null) {
          _ref.call(this.node);
        }
        return this.node.style.display = this.originalDisplay;
      } else {
        hide = Batman.data(this.node, 'hide');
        if (typeof hide === 'function') {
          return hide.call(this.node);
        } else {
          return this.node.style.display = 'none';
        }
      }
    };
    return ShowHideBinding;
  })();
  Batman.DOM.CheckedBinding = (function() {
    __extends(CheckedBinding, Batman.DOM.NodeAttributeBinding);
    CheckedBinding.prototype.dataChange = function(value) {
      var _base;
      this.node[this.attributeName] = !!value;
      return typeof (_base = Batman.data(this.node.parentNode, 'updateBinding')) === "function" ? _base() : void 0;
    };
    function CheckedBinding() {
      CheckedBinding.__super__.constructor.apply(this, arguments);
      Batman.data(this.node, this.attributeName, this);
    }
    return CheckedBinding;
  })();
  Batman.DOM.ClassBinding = (function() {
    __extends(ClassBinding, Batman.DOM.AbstractCollectionBinding);
    function ClassBinding() {
      this.handleItemsWereAdded = __bind(this.handleItemsWereAdded, this);
      this.handleItemsWereRemoved = __bind(this.handleItemsWereRemoved, this);
      this.handleArrayChanged = __bind(this.handleArrayChanged, this);
      ClassBinding.__super__.constructor.apply(this, arguments);
    }
    ClassBinding.prototype.dataChange = function(value) {
      if (value != null) {
        this.unbindCollection();
        if (typeof value === 'string') {
          return this.node.className = value;
        } else {
          this.bindCollection(value);
          return this.updateFromCollection();
        }
      }
    };
    ClassBinding.prototype.updateFromCollection = function() {
      var array, k, v;
      if (this.collection) {
        array = this.collection.map ? this.collection.map(function(x) {
          return x;
        }) : (function() {
          var _ref, _results;
          _ref = this.collection;
          _results = [];
          for (k in _ref) {
            if (!__hasProp.call(_ref, k)) continue;
            v = _ref[k];
            _results.push(k);
          }
          return _results;
        }).call(this);
        if (array.toArray != null) {
          array = array.toArray();
        }
        return this.node.className = array.join(' ');
      }
    };
    ClassBinding.prototype.handleArrayChanged = function() {
      return this.updateFromCollection();
    };
    ClassBinding.prototype.handleItemsWereRemoved = function() {
      return this.updateFromCollection();
    };
    ClassBinding.prototype.handleItemsWereAdded = function() {
      return this.updateFromCollection();
    };
    return ClassBinding;
  })();
  Batman.DOM.AddClassBinding = (function() {
    __extends(AddClassBinding, Batman.DOM.AbstractAttributeBinding);
    function AddClassBinding(node, className, keyPath, renderContext, renderer, only, invert) {
      this.invert = invert != null ? invert : false;
      this.className = className.replace(/\|/g, ' ');
      AddClassBinding.__super__.constructor.apply(this, arguments);
      delete this.attributeName;
    }
    AddClassBinding.prototype.dataChange = function(value) {
      var currentName, includesClassName;
      currentName = this.node.className;
      includesClassName = currentName.indexOf(this.className) !== -1;
      if (!!value === !this.invert) {
        if (!includesClassName) {
          return this.node.className = "" + currentName + " " + this.className;
        }
      } else {
        if (includesClassName) {
          return this.node.className = currentName.replace(this.className, '');
        }
      }
    };
    return AddClassBinding;
  })();
  Batman.DOM.EventBinding = (function() {
    __extends(EventBinding, Batman.DOM.AbstractAttributeBinding);
    EventBinding.prototype.bindImmediately = false;
    function EventBinding() {
      var attacher, callback, confirmText;
      EventBinding.__super__.constructor.apply(this, arguments);
      confirmText = this.node.getAttribute('data-confirm');
      callback = __bind(function() {
        var _ref;
        if (confirmText && !confirm(confirmText)) {
          return;
        }
        return (_ref = this.get('filteredValue')) != null ? _ref.apply(this.get('callbackContext'), arguments) : void 0;
      }, this);
      if (attacher = Batman.DOM.events[this.attributeName]) {
        attacher(this.node, callback);
      } else {
        Batman.DOM.events.other(this.node, this.attributeName, callback);
      }
    }
    EventBinding.accessor('callbackContext', function() {
      var context, contextKeySegments;
      contextKeySegments = this.key.split('.');
      contextKeySegments.pop();
      return context = contextKeySegments.length > 0 ? this.get('keyContext').get(contextKeySegments.join('.')) : this.get('keyContext');
    });
    return EventBinding;
  })();
  Batman.DOM.RadioBinding = (function() {
    __extends(RadioBinding, Batman.DOM.AbstractBinding);
    function RadioBinding() {
      RadioBinding.__super__.constructor.apply(this, arguments);
    }
    RadioBinding.prototype.dataChange = function(value) {
      var boundValue;
      if ((boundValue = this.get('filteredValue')) != null) {
        return this.node.checked = boundValue === this.node.value;
      } else if (this.node.checked) {
        return this.get('keyContext').set(this.key, this.node.value);
      }
    };
    RadioBinding.prototype.nodeChange = function(node) {
      return this.get('keyContext').set(this.key, Batman.DOM.attrReaders._parseAttribute(node.value));
    };
    return RadioBinding;
  })();
  Batman.DOM.FileBinding = (function() {
    __extends(FileBinding, Batman.DOM.AbstractBinding);
    function FileBinding() {
      FileBinding.__super__.constructor.apply(this, arguments);
    }
    FileBinding.prototype.nodeChange = function(node, subContext) {
      var actualObject, adapter, keyContext, segments, _i, _len, _ref;
      segments = this.key.split('.');
      if (segments.length > 1) {
        keyContext = subContext.get(segments.slice(0, -1).join('.'));
      } else {
        keyContext = subContext;
      }
      if (keyContext instanceof Batman.RenderContext.ContextProxy) {
        actualObject = keyContext.get('proxiedObject');
      } else {
        actualObject = keyContext;
      }
      if (actualObject.hasStorage && actualObject.hasStorage()) {
        _ref = actualObject._batman.get('storage');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          adapter = _ref[_i];
          if (adapter instanceof Batman.RestStorage) {
            adapter.defaultOptions.formData = true;
          }
        }
      }
      if (node.hasAttribute('multiple')) {
        return subContext.set(this.key, Array.prototype.slice.call(node.files));
      } else {
        return subContext.set(this.key, node.files[0]);
      }
    };
    return FileBinding;
  })();
  Batman.DOM.MixinBinding = (function() {
    __extends(MixinBinding, Batman.DOM.AbstractBinding);
    function MixinBinding() {
      MixinBinding.__super__.constructor.apply(this, arguments);
    }
    MixinBinding.prototype.dataChange = function(value) {
      if (value != null) {
        return $mixin(this.node, value);
      }
    };
    return MixinBinding;
  })();
  Batman.DOM.SelectBinding = (function() {
    __extends(SelectBinding, Batman.DOM.AbstractBinding);
    SelectBinding.prototype.bindImmediately = false;
    function SelectBinding() {
      this.updateOptionBindings = __bind(this.updateOptionBindings, this);
      this.updateSelectBinding = __bind(this.updateSelectBinding, this);
      this.nodeChange = __bind(this.nodeChange, this);
      this.dataChange = __bind(this.dataChange, this);      SelectBinding.__super__.constructor.apply(this, arguments);
      this.renderer.on('rendered', __bind(function() {
        if (this.node != null) {
          Batman.data(this.node, 'updateBinding', this.updateSelectBinding);
          return this.bind();
        }
      }, this));
    }
    SelectBinding.prototype.dataChange = function(newValue) {
      var child, match, matches, value, valueToChild, _i, _j, _k, _len, _len2, _len3, _ref, _ref2;
      if (newValue instanceof Array) {
        valueToChild = {};
        _ref = this.node.children;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          child = _ref[_i];
          child.selected = false;
          matches = valueToChild[child.value];
          if (matches) {
            matches.push(child);
          } else {
            matches = [child];
          }
          valueToChild[child.value] = matches;
        }
        for (_j = 0, _len2 = newValue.length; _j < _len2; _j++) {
          value = newValue[_j];
          _ref2 = valueToChild[value];
          for (_k = 0, _len3 = _ref2.length; _k < _len3; _k++) {
            match = _ref2[_k];
            match.selected = true;
          }
        }
      } else {
        Batman.DOM.valueForNode(this.node, newValue);
      }
      return this.updateOptionBindings();
    };
    SelectBinding.prototype.nodeChange = function() {
      this.updateSelectBinding();
      return this.updateOptionBindings();
    };
    SelectBinding.prototype.updateSelectBinding = function() {
      var c, selections;
      selections = this.node.multiple ? (function() {
        var _i, _len, _ref, _results;
        _ref = this.node.children;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          c = _ref[_i];
          if (c.selected) {
            _results.push(c.value);
          }
        }
        return _results;
      }).call(this) : this.node.value;
      if (selections.length === 1) {
        selections = selections[0];
      }
      this.get('keyContext').set(this.key, selections);
      return true;
    };
    SelectBinding.prototype.updateOptionBindings = function() {
      var child, selectedBinding, _i, _len, _ref;
      _ref = this.node.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        if (selectedBinding = Batman.data(child, 'selected')) {
          selectedBinding.nodeChange(selectedBinding.node);
        }
      }
      return true;
    };
    return SelectBinding;
  })();
  Batman.DOM.StyleBinding = (function() {
    __extends(StyleBinding, Batman.DOM.AbstractCollectionBinding);
    StyleBinding.SingleStyleBinding = (function() {
      __extends(SingleStyleBinding, Batman.DOM.AbstractAttributeBinding);
      function SingleStyleBinding() {
        var args, parent, _i;
        args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), parent = arguments[_i++];
        this.parent = parent;
        SingleStyleBinding.__super__.constructor.apply(this, args);
      }
      SingleStyleBinding.prototype.dataChange = function(value) {
        return this.parent.setStyle(this.attributeName, value);
      };
      return SingleStyleBinding;
    })();
    function StyleBinding() {
      this.setStyle = __bind(this.setStyle, this);
      this.handleItemsWereRemoved = __bind(this.handleItemsWereRemoved, this);
      this.handleItemsWereAdded = __bind(this.handleItemsWereAdded, this);      this.oldStyles = {};
      StyleBinding.__super__.constructor.apply(this, arguments);
    }
    StyleBinding.prototype.dataChange = function(value) {
      var cssName, cssValue, key, keyValue, keypathContext, keypathValue, style, _i, _len, _ref, _ref2, _ref3, _results;
      if (!value) {
        this.reapplyOldStyles();
        return;
      }
      this.unbindCollection();
      if (typeof value === 'string') {
        this.reapplyOldStyles();
        _ref = value.split(';');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          style = _ref[_i];
          _ref2 = style.split(/:(.+)/), cssName = _ref2[0], cssValue = _ref2[1];
          this.setStyle(cssName, cssValue);
        }
        return;
      }
      if (value instanceof Batman.Hash) {
        if (this.bindCollection(value)) {
          return value.forEach(__bind(function(key, value) {
            return this.setStyle(key, value);
          }, this));
        }
      } else if (value instanceof Object) {
        this.reapplyOldStyles();
        _results = [];
        for (key in value) {
          if (!__hasProp.call(value, key)) continue;
          keyValue = value[key];
          _ref3 = this.renderContext.findKey(keyValue), keypathValue = _ref3[0], keypathContext = _ref3[1];
          _results.push(keypathValue ? (this.bindSingleAttribute(key, keyValue), this.setStyle(key, keypathValue)) : this.setStyle(key, keyValue));
        }
        return _results;
      }
    };
    StyleBinding.prototype.handleItemsWereAdded = function(newKey) {
      return this.setStyle(newKey, this.collection.get(newKey));
    };
    StyleBinding.prototype.handleItemsWereRemoved = function(oldKey) {
      return this.setStyle(oldKey, '');
    };
    StyleBinding.prototype.bindSingleAttribute = function(attr, keyPath) {
      return new this.constructor.SingleStyleBinding(this.node, attr, keyPath, this.renderContext, this.renderer, this.only, this);
    };
    StyleBinding.prototype.setStyle = function(key, value) {
      if (!key) {
        return;
      }
      key = helpers.camelize(key.trim(), true);
      this.oldStyles[key] = this.node.style[key];
      return this.node.style[key] = value ? value.trim() : "";
    };
    StyleBinding.prototype.reapplyOldStyles = function() {
      var cssName, cssValue, _ref, _results;
      _ref = this.oldStyles;
      _results = [];
      for (cssName in _ref) {
        if (!__hasProp.call(_ref, cssName)) continue;
        cssValue = _ref[cssName];
        _results.push(this.setStyle(cssName, cssValue));
      }
      return _results;
    };
    return StyleBinding;
  })();
  Batman.DOM.IteratorBinding = (function() {
    __extends(IteratorBinding, Batman.DOM.AbstractCollectionBinding);
    IteratorBinding.prototype.deferEvery = 50;
    IteratorBinding.prototype.currentActionNumber = 0;
    IteratorBinding.prototype.queuedActionNumber = 0;
    IteratorBinding.prototype.bindImmediately = false;
    function IteratorBinding() {
      var args, sourceNode;
      sourceNode = arguments[0], args = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      this.handleArrayChanged = __bind(this.handleArrayChanged, this);
      this.handleItemsWereRemoved = __bind(this.handleItemsWereRemoved, this);
      this.handleItemsWereAdded = __bind(this.handleItemsWereAdded, this);
      this.parentNode = sourceNode.parentNode;
      this.initialSiblingNode = sourceNode.nextSibling;
      IteratorBinding.__super__.constructor.apply(this, [this.parentNode].concat(__slice.call(args)));
      this.iteratorName = this.attributeName;
      this.parentRenderer = this.renderer;
      this.nodeMap = new Batman.SimpleHash;
      this.actionMap = new Batman.SimpleHash;
      this.rendererMap = new Batman.SimpleHash;
      this.actions = [];
      this.prototypeNode = sourceNode.cloneNode(true);
      this.prototypeNode.removeAttribute("data-foreach-" + this.iteratorName);
      this.parentRenderer.on('parsed', __bind(function() {
        this.prototypeNode[Batman.expando] = sourceNode[Batman.expando];
        if (Batman.canDeleteExpando) {
          delete sourceNode[Batman.expando];
        }
        return $removeNode(sourceNode);
      }, this));
      this.parentRenderer.prevent('rendered');
      this.fragment = document.createDocumentFragment();
      this.bind();
    }
    IteratorBinding.prototype.destroy = function() {
      $unbindNode(this.prototypeNode);
      IteratorBinding.__super__.destroy.apply(this, arguments);
      return this.destroyed = true;
    };
    IteratorBinding.prototype.unbindCollection = function() {
      if (this.collection) {
        this.nodeMap.forEach(function(item, node) {
          return $removeNode(node);
        });
        this.nodeMap.clear();
        this.rendererMap.forEach(function(item, renderer) {
          return renderer.stop();
        });
        this.rendererMap.clear();
        return IteratorBinding.__super__.unbindCollection.apply(this, arguments);
      }
    };
    IteratorBinding.prototype.dataChange = function(newCollection) {
      var key, value, _ref;
      this.bindCollection(newCollection);
      if (this.collection) {
        if (this.collection.toArray) {
          this.handleArrayChanged();
        } else if (this.collection.forEach) {
          this.collection.forEach(__bind(function(item) {
            return this.addItem(item);
          }, this));
        } else {
          _ref = this.collection;
          for (key in _ref) {
            if (!__hasProp.call(_ref, key)) continue;
            value = _ref[key];
            this.addItem(key);
          }
        }
      } else {
        developer.warn("Warning! data-foreach-" + this.iteratorName + " called with an undefined binding. Key was: " + this.key + ".");
      }
      return this.processActionQueue();
    };
    IteratorBinding.prototype.handleItemsWereAdded = function() {
      var item, items, _i, _len, _results;
      items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      _results = [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        _results.push(this.addItem(item, {
          fragment: true
        }));
      }
      return _results;
    };
    IteratorBinding.prototype.handleItemsWereRemoved = function() {
      var item, items, _i, _len, _results;
      items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      _results = [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        _results.push(this.removeItem(item));
      }
      return _results;
    };
    IteratorBinding.prototype.handleArrayChanged = function() {
      var existingNode, item, newItemsInOrder, trackingNodeMap, _i, _len;
      newItemsInOrder = this.collection.toArray();
      trackingNodeMap = new Batman.SimpleHash;
      for (_i = 0, _len = newItemsInOrder.length; _i < _len; _i++) {
        item = newItemsInOrder[_i];
        existingNode = this.nodeMap.get(item);
        trackingNodeMap.set(item, true);
        if (existingNode) {
          this.insertItem(item, existingNode, {
            fragment: false,
            actionNumber: this.queuedActionNumber++,
            sync: true
          });
        } else {
          this.addItem(item, {
            fragment: false
          });
        }
      }
      return this.nodeMap.forEach(__bind(function(item, node) {
        if (!trackingNodeMap.hasKey(item)) {
          return this.removeItem(item);
        }
      }, this));
    };
    IteratorBinding.prototype.addItem = function(item, options) {
      var childRenderer, finish, self;
      if (options == null) {
        options = {
          fragment: true
        };
      }
      this.parentRenderer.prevent('rendered');
      self = this;
      options.actionNumber = this.queuedActionNumber++;
      childRenderer = new Batman.Renderer(this._nodeForItem(item), (function() {
        return self.insertItem(item, this.node, options);
      }), this.renderContext.descend(item, this.iteratorName));
      this.rendererMap.set(item, childRenderer);
      finish = __bind(function() {
        if (this.destroyed) {
          return;
        }
        return this.parentRenderer.allowAndFire('rendered');
      }, this);
      childRenderer.on('rendered', finish);
      childRenderer.on('stopped', __bind(function() {
        if (this.destroyed) {
          return;
        }
        this.actions[options.actionNumber] = function() {};
        finish();
        return this.processActionQueue();
      }, this));
      return item;
    };
    IteratorBinding.prototype.removeItem = function(item) {
      var hideFunction, oldNode;
      if (this.destroyed) {
        return;
      }
      this._removeOldAction(item);
      oldNode = this.nodeMap.unset(item);
      if (oldNode) {
        if (hideFunction = Batman.data(oldNode, 'hide')) {
          return hideFunction.call(oldNode);
        } else {
          return $removeNode(oldNode);
        }
      }
    };
    IteratorBinding.prototype.insertItem = function(item, node, options) {
      var futureActionNumber, _base, _base2, _name, _name2;
      if (options == null) {
        options = {};
      }
      if (this.destroyed) {
        return;
      }
      futureActionNumber = this.actionMap.get(item);
      if ((futureActionNumber != null) && futureActionNumber > options.actionNumber) {
        this.actions[options.actionNumber] = function() {};
      } else {
        this._removeOldAction(item);
        this.actionMap.set(item, options.actionNumber);
        if (this.nodeMap.get(item) !== node) {
          (_base = this.actions)[_name = options.actionNumber] || (_base[_name] = function() {});
        } else {
          this.rendererMap.unset(item);
          (_base2 = this.actions)[_name2 = options.actionNumber] || (_base2[_name2] = function() {
            var show;
            show = Batman.data(node, 'show');
            if (typeof show === 'function') {
              show.call(node, {
                before: this.nextSibling()
              });
            } else {
              if (options.fragment) {
                this.fragment.appendChild(node);
              } else {
                this.parentNode.insertBefore(node, this.nextSibling());
              }
            }
            return this.lastNode = node;
          });
        }
      }
      this.actions[options.actionNumber].item = item;
      return this.processActionQueue();
    };
    IteratorBinding.prototype.processActionQueue = function() {
      if (this.destroyed) {
        return;
      }
      if (!this.actionQueueTimeout) {
        return this.actionQueueTimeout = $setImmediate(__bind(function() {
          var f, startTime;
          if (this.destroyed) {
            return;
          }
          delete this.actionQueueTimeout;
          startTime = new Date;
          while (!!(f = this.actions[this.currentActionNumber])) {
            this.actions[this.currentActionNumber] = true;
            f.call(this);
            this.currentActionNumber++;
            if (this.deferEvery && (new Date - startTime) > this.deferEvery) {
              return this.processActionQueue();
            }
          }
          if (this.fragment && this.rendererMap.length === 0 && this.fragment.hasChildNodes()) {
            this.parentNode.insertBefore(this.fragment, this.nextSibling());
            this.fragment = document.createDocumentFragment();
          }
          if (this.currentActionNumber === this.queuedActionNumber) {
            return this.parentRenderer.allowAndFire('rendered');
          }
        }, this));
      }
    };
    IteratorBinding.prototype.nextSibling = function() {
      if (this.lastNode) {
        return this.lastNode.nextSibling;
      } else {
        if (this.initialSiblingNode && this.initialSiblingNode.parentNode) {
          return this.initialSiblingNode;
        } else {
          return;
        }
      }
    };
    IteratorBinding.prototype._nodeForItem = function(item) {
      var newNode;
      newNode = this.prototypeNode.cloneNode(true);
      this.nodeMap.set(item, newNode);
      return newNode;
    };
    IteratorBinding.prototype._removeOldAction = function(item) {
      var oldActionNumber;
      oldActionNumber = this.actionMap.get(item);
      if ((oldActionNumber != null) && oldActionNumber > this.currentActionNumber) {
        this.actionMap.unset(item);
        return this.actions[oldActionNumber] = function() {};
      }
    };
    return IteratorBinding;
  })();
  buntUndefined = function(f) {
    return function(value) {
      if (typeof value === 'undefined') {
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
    equals: buntUndefined(function(lhs, rhs) {
      return lhs === rhs;
    }),
    not: function(value) {
      return !!!value;
    },
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
    }),
    meta: buntUndefined(function(value, keypath) {
      developer.assert(value.meta, "Error, value doesn't have a meta to filter on!");
      return value.meta.get(keypath);
    }),
    interpolate: function(string, interpolationKeypaths) {
      var k, v, values;
      if (string == null) {
        return;
      }
      values = {};
      for (k in interpolationKeypaths) {
        v = interpolationKeypaths[k];
        values[k] = this.findKey(v)[0];
        if (!(values[k] != null)) {
          Batman.developer.warn("Warning! Undefined interpolation key " + k + " for interpolation", string);
          values[k] = '';
        }
      }
      return Batman.helpers.interpolate(string, values);
    }
  };
  _ref = ['capitalize', 'singularize', 'underscore', 'camelize'];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    k = _ref[_i];
    filters[k] = buntUndefined(helpers[k]);
  }
  developer.addFilters();
  $mixin(Batman, {
    cache: {},
    uuid: 0,
    expando: "batman" + Math.random().toString().replace(/\D/g, ''),
    canDeleteExpando: (function() {
      try {
        div = document.createElement('div');
        return delete div.test;
      } catch (e) {
        return Batman.canDeleteExpando = false;
      }
    })(),
    noData: {
      "embed": true,
      "object": "clsid:D27CDB6E-AE6D-11cf-96B8-444553540000",
      "applet": true
    },
    hasData: function(elem) {
      elem = (elem.nodeType ? Batman.cache[elem[Batman.expando]] : elem[Batman.expando]);
      return !!elem && !isEmptyDataObject(elem);
    },
    data: function(elem, name, data, pvt) {
      var cache, getByName, id, internalKey, isNode, ret, thisCache;
      if (!Batman.acceptData(elem)) {
        return;
      }
      internalKey = Batman.expando;
      getByName = typeof name === "string";
      isNode = elem.nodeType;
      cache = isNode ? Batman.cache : elem;
      id = isNode ? elem[Batman.expando] : elem[Batman.expando] && Batman.expando;
      if ((!id || (pvt && id && (cache[id] && !cache[id][internalKey]))) && getByName && data === void 0) {
        return;
      }
      if (!id) {
        if (isNode) {
          elem[Batman.expando] = id = ++Batman.uuid;
        } else {
          id = Batman.expando;
        }
      }
      if (!cache[id]) {
        cache[id] = {};
      }
      if (typeof name === "object" || typeof name === "function") {
        if (pvt) {
          cache[id][internalKey] = $mixin(cache[id][internalKey], name);
        } else {
          cache[id] = $mixin(cache[id], name);
        }
      }
      thisCache = cache[id];
      if (pvt) {
        if (!thisCache[internalKey]) {
          thisCache[internalKey] = {};
        }
        thisCache = thisCache[internalKey];
      }
      if (data !== void 0) {
        thisCache[helpers.camelize(name, true)] = data;
      }
      if (getByName) {
        ret = thisCache[name];
        if (ret == null) {
          ret = thisCache[helpers.camelize(name, true)];
        }
      } else {
        ret = thisCache;
      }
      return ret;
    },
    removeData: function(elem, name, pvt) {
      var cache, id, internalCache, internalKey, isNode, thisCache;
      if (!Batman.acceptData(elem)) {
        return;
      }
      internalKey = Batman.expando;
      isNode = elem.nodeType;
      cache = isNode ? Batman.cache : elem;
      id = isNode ? elem[Batman.expando] : Batman.expando;
      if (!cache[id]) {
        return;
      }
      if (name) {
        thisCache = pvt ? cache[id][internalKey] : cache[id];
        if (thisCache) {
          if (!thisCache[name]) {
            name = helpers.camelize(name, true);
          }
          delete thisCache[name];
          if (!isEmptyDataObject(thisCache)) {
            return;
          }
        }
      }
      if (pvt) {
        delete cache[id][internalKey];
        if (!isEmptyDataObject(cache[id])) {
          return;
        }
      }
      internalCache = cache[id][internalKey];
      if (Batman.canDeleteExpando || !cache.setInterval) {
        delete cache[id];
      } else {
        cache[id] = null;
      }
      if (internalCache) {
        cache[id] = {};
        return cache[id][internalKey] = internalCache;
      } else if (isNode) {
        if (Batman.canDeleteExpando) {
          return delete elem[Batman.expando];
        } else if (elem.removeAttribute) {
          return elem.removeAttribute(Batman.expando);
        } else {
          return elem[Batman.expando] = null;
        }
      }
    },
    _data: function(elem, name, data) {
      return Batman.data(elem, name, data, true);
    },
    acceptData: function(elem) {
      var match;
      if (elem.nodeName) {
        match = Batman.noData[elem.nodeName.toLowerCase()];
        if (match) {
          return !(match === true || elem.getAttribute("classid") !== match);
        }
      }
      return true;
    }
  });
  isEmptyDataObject = function(obj) {
    var name;
    for (name in obj) {
      return false;
    }
    return true;
  };
  mixins = Batman.mixins = new Batman.Object();
  Batman.Encoders = {};
  Batman.Paginator = (function() {
    __extends(Paginator, Batman.Object);
    function Paginator() {
      Paginator.__super__.constructor.apply(this, arguments);
    }
    Paginator.Cache = (function() {
      function Cache(offset, limit, items) {
        this.offset = offset;
        this.limit = limit;
        this.items = items;
        this.length = items.length;
        this.reach = offset + limit;
      }
      Cache.prototype.containsItemsForOffsetAndLimit = function(offset, limit) {
        return offset >= this.offset && (offset + limit) <= this.reach;
      };
      Cache.prototype.itemsForOffsetAndLimit = function(offset, limit) {
        var begin, end;
        if (!this.containsItemsForOffsetAndLimit(offset, limit)) {
          return;
        }
        begin = offset - this.offset;
        end = begin + limit;
        return this.items.slice(begin, end);
      };
      return Cache;
    })();
    Paginator.prototype.offset = 0;
    Paginator.prototype.limit = 10;
    Paginator.prototype.totalCount = 0;
    Paginator.prototype.offsetFromPageAndLimit = function(page, limit) {
      return Math.round((+page - 1) * limit);
    };
    Paginator.prototype.pageFromOffsetAndLimit = function(offset, limit) {
      return offset / limit + 1;
    };
    Paginator.prototype.toArray = function() {
      var cache, items, limit, offset;
      cache = this.get('cache');
      offset = this.get('offset');
      limit = this.get('limit');
      items = cache != null ? cache.itemsForOffsetAndLimit(offset, limit) : void 0;
      if (!items) {
        this.loadItemsForOffsetAndLimit(offset, limit);
      }
      return items || [];
    };
    Paginator.prototype.page = function() {
      return this.pageFromOffsetAndLimit(this.get('offset'), this.get('limit'));
    };
    Paginator.prototype.pageCount = function() {
      return Math.ceil(this.get('totalCount') / this.get('limit'));
    };
    Paginator.prototype.previousPage = function() {
      return this.set('page', this.get('page') - 1);
    };
    Paginator.prototype.nextPage = function() {
      return this.set('page', this.get('page') + 1);
    };
    Paginator.prototype.loadItemsForOffsetAndLimit = function(offset, limit) {};
    Paginator.prototype.updateCache = function(offset, limit, items) {
      return this.set('cache', new Batman.Paginator.Cache(offset, limit, items));
    };
    Paginator.accessor('toArray', Paginator.prototype.toArray);
    Paginator.accessor('offset', 'limit', 'totalCount', {
      get: Batman.Property.defaultAccessor.get,
      set: function(key, value) {
        return Batman.Property.defaultAccessor.set.call(this, key, +value);
      }
    });
    Paginator.accessor('page', {
      get: Paginator.prototype.page,
      set: function(_, value) {
        value = +value;
        this.set('offset', this.offsetFromPageAndLimit(value, this.get('limit')));
        return value;
      }
    });
    Paginator.accessor('pageCount', Paginator.prototype.pageCount);
    return Paginator;
  })();
  Batman.ModelPaginator = (function() {
    __extends(ModelPaginator, Batman.Paginator);
    function ModelPaginator() {
      ModelPaginator.__super__.constructor.apply(this, arguments);
    }
    ModelPaginator.prototype.cachePadding = 0;
    ModelPaginator.prototype.paddedOffset = function(offset) {
      offset -= this.cachePadding;
      if (offset < 0) {
        return 0;
      } else {
        return offset;
      }
    };
    ModelPaginator.prototype.paddedLimit = function(limit) {
      return limit + this.cachePadding * 2;
    };
    ModelPaginator.prototype.loadItemsForOffsetAndLimit = function(offset, limit) {
      var k, params, v, _ref2;
      params = this.paramsForOffsetAndLimit(offset, limit);
      _ref2 = this.params;
      for (k in _ref2) {
        v = _ref2[k];
        params[k] = v;
      }
      return this.model.load(params, __bind(function(err, records) {
        if (err == null) {
          return this.updateCache(this.offsetFromParams(params), this.limitFromParams(params), records);
        }
      }, this));
    };
    ModelPaginator.prototype.paramsForOffsetAndLimit = function(offset, limit) {
      return {
        offset: this.paddedOffset(offset),
        limit: this.paddedLimit(limit)
      };
    };
    ModelPaginator.prototype.offsetFromParams = function(params) {
      return params.offset;
    };
    ModelPaginator.prototype.limitFromParams = function(params) {
      return params.limit;
    };
    return ModelPaginator;
  })();
  container = typeof exports !== "undefined" && exports !== null ? (module.exports = Batman, global) : (window.Batman = Batman, window);
  $mixin(container, Batman.Observable);
  Batman.exportHelpers = function(onto) {
    var k, _j, _len2, _ref2;
    _ref2 = ['mixin', 'unmixin', 'route', 'redirect', 'typeOf', 'redirect', 'setImmediate'];
    for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
      k = _ref2[_j];
      onto["$" + k] = Batman[k];
    }
    return onto;
  };
  Batman.exportGlobals = function() {
    return Batman.exportHelpers(container);
  };
}).call(this);

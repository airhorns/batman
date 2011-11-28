(function() {
  var $addEventListener, $appendChild, $clearImmediate, $contains, $extendsEnumerable, $forEach, $forgetParseExit, $functionName, $get, $hasAddEventListener, $insertBefore, $isChildOf, $mixin, $objectHasKey, $onParseExit, $preventDefault, $redirect, $removeEventListener, $removeNode, $setImmediate, $setInnerHTML, $setStyleProperty, $trackBinding, $typeOf, $unbindNode, $unbindTree, $unmixin, Batman, BatmanObject, Validators, buntUndefined, camelize_rx, capitalize_rx, developer, div, filters, helpers, isEmptyDataObject, k, mixins, t, underscore_rx1, underscore_rx2, _Batman, _i, _implementImmediates, _len, _objectToString, _ref, _stateMachine_setState;
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
  Batman.version = '0.8.0';
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
  $setImmediate = $clearImmediate = null;
  _implementImmediates = function(container) {
    var canUsePostMessage, count, functions, getHandle, handler, prefix, tasks;
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
    _implementImmediates(Batman.container);
    return Batman.setImmediate.apply(this, arguments);
  };
  Batman.clearImmediate = $clearImmediate = function() {
    _implementImmediates(Batman.container);
    return Batman.clearImmediate.apply(this, arguments);
  };
  Batman.forEach = $forEach = function(container, iterator, ctx) {
    var e, i, k, v, _len, _results, _results2;
    if (container.forEach) {
      return container.forEach(iterator, ctx);
    } else if (container.indexOf) {
      _results = [];
      for (i = 0, _len = container.length; i < _len; i++) {
        e = container[i];
        _results.push(iterator.call(ctx, e, i, container));
      }
      return _results;
    } else {
      _results2 = [];
      for (k in container) {
        v = container[k];
        _results2.push(iterator.call(ctx, k, v, container));
      }
      return _results2;
    }
  };
  Batman.objectHasKey = $objectHasKey = function(object, key) {
    if (typeof object.hasKey === 'function') {
      return object.hasKey(key);
    } else {
      return key in object;
    }
  };
  Batman.contains = $contains = function(container, item) {
    if (container.indexOf) {
      return __indexOf.call(container, item) >= 0;
    } else if (typeof container.has === 'function') {
      return container.has(item);
    } else {
      return $objectHasKey(container, item);
    }
  };
  Batman.get = $get = function(base, key) {
    if (typeof base.get === 'function') {
      return base.get(key);
    } else {
      return Batman.Property.forBaseAndKey(base, key).getValue();
    }
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
      if (!developer.suppressed) {
        return f();
      }
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
  Batman.Inflector = (function() {
    function Inflector() {}
    Inflector.prototype.plural = [];
    Inflector.prototype.singular = [];
    Inflector.prototype.uncountable = [];
    Inflector.plural = function(regex, replacement) {
      return this.prototype.plural.unshift([regex, replacement]);
    };
    Inflector.singular = function(regex, replacement) {
      return this.prototype.singular.unshift([regex, replacement]);
    };
    Inflector.irregular = function(singular, plural) {
      if (singular.charAt(0) === plural.charAt(0)) {
        this.plural(new RegExp("(" + (singular.charAt(0)) + ")" + (singular.slice(1)) + "$", "i"), "$1" + plural.slice(1));
        this.plural(new RegExp("(" + (singular.charAt(0)) + ")" + (plural.slice(1)) + "$", "i"), "$1" + plural.slice(1));
        return this.singular(new RegExp("(" + (plural.charAt(0)) + ")" + (plural.slice(1)) + "$", "i"), "$1" + singular.slice(1));
      } else {
        this.plural(new RegExp("" + singular + "$", 'i'), plural);
        this.plural(new RegExp("" + plural + "$", 'i'), plural);
        return this.singular(new RegExp("" + plural + "$", 'i'), singular);
      }
    };
    Inflector.uncountable = function() {
      var strings;
      strings = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      return this.prototype.uncountable = this.prototype.uncountable.concat(strings.map(function(x) {
        return new RegExp("" + x + "$", 'i');
      }));
    };
    Inflector.plural(/$/, 's');
    Inflector.plural(/s$/i, 's');
    Inflector.plural(/(ax|test)is$/i, '$1es');
    Inflector.plural(/(octop|vir)us$/i, '$1i');
    Inflector.plural(/(octop|vir)i$/i, '$1i');
    Inflector.plural(/(alias|status)$/i, '$1es');
    Inflector.plural(/(bu)s$/i, '$1ses');
    Inflector.plural(/(buffal|tomat)o$/i, '$1oes');
    Inflector.plural(/([ti])um$/i, '$1a');
    Inflector.plural(/([ti])a$/i, '$1a');
    Inflector.plural(/sis$/i, 'ses');
    Inflector.plural(/(?:([^f])fe|([lr])f)$/i, '$1$2ves');
    Inflector.plural(/(hive)$/i, '$1s');
    Inflector.plural(/([^aeiouy]|qu)y$/i, '$1ies');
    Inflector.plural(/(x|ch|ss|sh)$/i, '$1es');
    Inflector.plural(/(matr|vert|ind)(?:ix|ex)$/i, '$1ices');
    Inflector.plural(/([m|l])ouse$/i, '$1ice');
    Inflector.plural(/([m|l])ice$/i, '$1ice');
    Inflector.plural(/^(ox)$/i, '$1en');
    Inflector.plural(/^(oxen)$/i, '$1');
    Inflector.plural(/(quiz)$/i, '$1zes');
    Inflector.singular(/s$/i, '');
    Inflector.singular(/(n)ews$/i, '$1ews');
    Inflector.singular(/([ti])a$/i, '$1um');
    Inflector.singular(/((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$/i, '$1$2sis');
    Inflector.singular(/(^analy)ses$/i, '$1sis');
    Inflector.singular(/([^f])ves$/i, '$1fe');
    Inflector.singular(/(hive)s$/i, '$1');
    Inflector.singular(/(tive)s$/i, '$1');
    Inflector.singular(/([lr])ves$/i, '$1f');
    Inflector.singular(/([^aeiouy]|qu)ies$/i, '$1y');
    Inflector.singular(/(s)eries$/i, '$1eries');
    Inflector.singular(/(m)ovies$/i, '$1ovie');
    Inflector.singular(/(x|ch|ss|sh)es$/i, '$1');
    Inflector.singular(/([m|l])ice$/i, '$1ouse');
    Inflector.singular(/(bus)es$/i, '$1');
    Inflector.singular(/(o)es$/i, '$1');
    Inflector.singular(/(shoe)s$/i, '$1');
    Inflector.singular(/(cris|ax|test)es$/i, '$1is');
    Inflector.singular(/(octop|vir)i$/i, '$1us');
    Inflector.singular(/(alias|status)es$/i, '$1');
    Inflector.singular(/^(ox)en/i, '$1');
    Inflector.singular(/(vert|ind)ices$/i, '$1ex');
    Inflector.singular(/(matr)ices$/i, '$1ix');
    Inflector.singular(/(quiz)zes$/i, '$1');
    Inflector.singular(/(database)s$/i, '$1');
    Inflector.irregular('person', 'people');
    Inflector.irregular('man', 'men');
    Inflector.irregular('child', 'children');
    Inflector.irregular('sex', 'sexes');
    Inflector.irregular('move', 'moves');
    Inflector.irregular('cow', 'kine');
    Inflector.irregular('zombie', 'zombies');
    Inflector.uncountable('equipment', 'information', 'rice', 'money', 'species', 'series', 'fish', 'sheep', 'jeans');
    Inflector.prototype.ordinalize = function(number) {
      var absNumber, _ref;
      absNumber = Math.abs(parseInt(number));
      if (_ref = absNumber % 100, __indexOf.call([11, 12, 13], _ref) >= 0) {
        return number + "th";
      } else {
        switch (absNumber % 10) {
          case 1:
            return number + "st";
          case 2:
            return number + "nd";
          case 3:
            return number + "rd";
          default:
            return number + "th";
        }
      }
    };
    Inflector.prototype.pluralize = function(word) {
      var regex, replace_string, uncountableRegex, _i, _j, _len, _len2, _ref, _ref2, _ref3;
      _ref = this.uncountable;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        uncountableRegex = _ref[_i];
        if (uncountableRegex.test(word)) {
          return word;
        }
      }
      _ref2 = this.plural;
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        _ref3 = _ref2[_j], regex = _ref3[0], replace_string = _ref3[1];
        if (regex.test(word)) {
          return word.replace(regex, replace_string);
        }
      }
      return word;
    };
    Inflector.prototype.singularize = function(word) {
      var regex, replace_string, uncountableRegex, _i, _j, _len, _len2, _ref, _ref2, _ref3;
      _ref = this.uncountable;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        uncountableRegex = _ref[_i];
        if (uncountableRegex.test(word)) {
          return word;
        }
      }
      _ref2 = this.singular;
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        _ref3 = _ref2[_j], regex = _ref3[0], replace_string = _ref3[1];
        if (regex.test(word)) {
          return word.replace(regex, replace_string);
        }
      }
      return word;
    };
    return Inflector;
  })();
  camelize_rx = /(?:^|_|\-)(.)/g;
  capitalize_rx = /(^|\s)([a-z])/g;
  underscore_rx1 = /([A-Z]+)([A-Z][a-z])/g;
  underscore_rx2 = /([a-z\d])([A-Z])/g;
  helpers = Batman.helpers = {
    inflector: new Batman.Inflector(),
    singularize: function(string) {
      return helpers.inflector.singularize(string);
    },
    pluralize: function(string) {
      return helpers.inflector.pluralize(string);
    },
    ordinalize: function(number) {
      return helpers.ordinalize(number);
    },
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
      },
      cachable: false
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
      developer["do"](__bind(function() {
        var keyType;
        keyType = $typeOf(this.key);
        if (keyType === 'Array' || keyType === 'Object') {
          return developer.log("Accessing a property with an " + keyType + " key. This is okay, but could be a source of memory leaks if you aren't careful.");
        }
      }, this));
    }
    Property.prototype._isolationCount = 0;
    Property.prototype.cached = false;
    Property.prototype.value = null;
    Property.prototype.sources = null;
    Property.prototype.isProperty = true;
    Property.prototype.isDead = false;
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
            handlers = property.changeEvent().handlers;
            return handlers.forEach(iterator);
          }
        });
      }
    };
    Property.prototype.observers = function() {
      var results;
      results = [];
      this.eachObserver(function(observer) {
        return results.push(observer);
      });
      return results;
    };
    Property.prototype.hasObservers = function() {
      return this.observers().length > 0;
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
      if (!this.isCached()) {
        this.pushSourceTracker();
        try {
          this.value = this.valueFromAccessor();
          this.cached = true;
        } finally {
          this.updateSourcesFromTracker();
        }
      }
      return this.value;
    };
    Property.prototype.isCachable = function() {
      var cachable;
      if (this.isFinal()) {
        return true;
      }
      cachable = this.accessor().cachable;
      if (cachable != null) {
        return !!cachable;
      } else {
        return true;
      }
    };
    Property.prototype.isCached = function() {
      return this.isCachable() && this.cached;
    };
    Property.prototype.isFinal = function() {
      return !!this.accessor()['final'];
    };
    Property.prototype.refresh = function() {
      var previousValue, value;
      this.cached = false;
      previousValue = this.value;
      value = this.getValue();
      if (value !== previousValue && !this.isIsolated()) {
        this.fire(value, previousValue);
      }
      if (this.value !== void 0 && this.isFinal()) {
        return this.lockValue();
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
      } else if (!this.isFinal() && !this.hasObservers()) {
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
      var set;
      if (!(set = this.accessor().set)) {
        return;
      }
      return this._changeValue(function() {
        return set.call(this.base, this.key, val);
      });
    };
    Property.prototype.unsetValue = function() {
      var unset;
      if (!(unset = this.accessor().unset)) {
        return;
      }
      return this._changeValue(function() {
        return unset.call(this.base, this.key);
      });
    };
    Property.prototype._changeValue = function(block) {
      var result;
      this.cached = false;
      this.pushDummySourceTracker();
      try {
        result = block.apply(this);
        this.refresh();
      } finally {
        this.popSourceTracker();
      }
      if (!(this.isCached() || this.hasObservers())) {
        this.die();
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
      if (this.sources == null) {
        this.getValue();
      }
      return this;
    };
    Property.prototype._removeHandlers = function() {
      var handler;
      handler = this.sourceChangeHandler();
      this._eachSourceChangeEvent(function(e) {
        return e.removeHandler(handler);
      });
      delete this.sources;
      return this.changeEvent().handlers.clear();
    };
    Property.prototype.lockValue = function() {
      this._removeHandlers();
      this.getValue = function() {
        return this.value;
      };
      return this.setValue = this.unsetValue = this.refresh = this.observe = function() {};
    };
    Property.prototype.die = function() {
      var _ref, _ref2;
      this._removeHandlers();
      if ((_ref = this.base._batman) != null) {
        if ((_ref2 = _ref.properties) != null) {
          _ref2.unset(this.key);
        }
      }
      return this.isDead = true;
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
      var base, propertyClass, remainingPath, remainingSegments, segment, _i, _len, _ref;
      if (end == null) {
        end = this.depth;
      }
      base = this.base;
      _ref = this.segments.slice(0, begin);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        segment = _ref[_i];
        if (!((base != null) && (base = $get(base, segment)))) {
          return;
        }
      }
      propertyClass = base.propertyClass || Batman.Keypath;
      remainingSegments = this.segments.slice(begin, end);
      remainingPath = remainingSegments.join('.');
      if (propertyClass === Batman.Keypath || remainingSegments.length === 1) {
        return Batman.Keypath.forBaseAndKey(base, remainingPath);
      } else {
        return new Batman.Keypath(base, remainingPath);
      }
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
      var isClass, parent, proto, results, val, _ref, _ref2;
      if (getter == null) {
        getter = function(x) {
          return x;
        };
      }
      results = [];
      isClass = !!this.object.prototype;
      parent = isClass ? (_ref = this.object.__super__) != null ? _ref.constructor : void 0 : (proto = Object.getPrototypeOf(this.object)) === this.object ? this.object.constructor.__super__ : proto;
      if (parent != null) {
        if ((_ref2 = parent._batman) != null) {
          _ref2.check(parent);
        }
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
    __extends(BatmanObject, Object);
    Batman.initializeObject(BatmanObject);
    Batman.initializeObject(BatmanObject.prototype);
    BatmanObject.global = function(isGlobal) {
      if (isGlobal === false) {
        return;
      }
      return Batman.container[$functionName(this)] = this;
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
        ctx = Batman.container;
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
        ctx = Batman.container;
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
        ctx = Batman.container;
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
    function SimpleHash(obj) {
      this._storage = {};
      this.length = 0;
      if (obj != null) {
        this.update(obj);
      }
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
    SimpleHash.prototype.forEach = function(iterator, ctx) {
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
            _results2.push(iterator.call(ctx, obj, value, this));
          }
          return _results2;
        }).call(this));
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
    SimpleHash.prototype.update = function(object) {
      var k, v, _results;
      _results = [];
      for (k in object) {
        v = object[k];
        _results.push(this.set(k, v));
      }
      return _results;
    };
    SimpleHash.prototype.replace = function(object) {
      this.forEach(__bind(function(key, value) {
        if (!(key in object)) {
          return this.unset(key);
        }
      }, this));
      return this.update(object);
    };
    SimpleHash.prototype.toObject = function() {
      var key, obj, pair, _ref;
      obj = {};
      _ref = this._storage;
      for (key in _ref) {
        pair = _ref[key];
        obj[key] = pair[0][1];
      }
      return obj;
    };
    SimpleHash.prototype.toJSON = SimpleHash.prototype.toObject;
    return SimpleHash;
  })();
  Batman.Hash = (function() {
    var k, proto, _fn, _i, _len, _ref;
    __extends(Hash, Batman.Object);
    Hash.Metadata = (function() {
      __extends(Metadata, Batman.Object);
      function Metadata(hash) {
        this.hash = hash;
      }
      Metadata.accessor('length', function() {
        this.hash.registerAsMutableSource();
        return this.hash.length;
      });
      Metadata.accessor('isEmpty', function() {
        return this.hash.isEmpty();
      });
      Metadata.accessor('keys', function() {
        return this.hash.keys();
      });
      return Metadata;
    })();
    function Hash() {
      this.meta = new this.constructor.Metadata(this);
      Batman.SimpleHash.apply(this, arguments);
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
      }),
      cachable: false
    });
    Hash.prototype._preventMutationEvents = function(block) {
      this.prevent('change');
      this.prevent('itemsWereAdded');
      this.prevent('itemsWereRemoved');
      try {
        return block.call(this);
      } finally {
        this.allow('change');
        this.allow('itemsWereAdded');
        this.allow('itemsWereRemoved');
      }
    };
    Hash.prototype.clear = Hash.mutation(function() {
      var keys, result;
      keys = this.keys();
      this._preventMutationEvents(function() {
        return this.forEach(__bind(function(k) {
          return this.unset(k);
        }, this));
      });
      result = Batman.SimpleHash.prototype.clear.call(this);
      this.fire.apply(this, ['itemsWereRemoved'].concat(__slice.call(keys)));
      return result;
    });
    Hash.prototype.update = Hash.mutation(function(object) {
      var addedKeys;
      addedKeys = [];
      this._preventMutationEvents(function() {
        return Batman.forEach(object, __bind(function(k, v) {
          if (!this.hasKey(k)) {
            addedKeys.push(k);
          }
          return this.set(k, v);
        }, this));
      });
      if (addedKeys.length > 0) {
        return this.fire.apply(this, ['itemsWereAdded'].concat(__slice.call(addedKeys)));
      }
    });
    Hash.prototype.replace = Hash.mutation(function(object) {
      var addedKeys, removedKeys;
      addedKeys = [];
      removedKeys = [];
      this._preventMutationEvents(function() {
        this.forEach(__bind(function(k, _) {
          if (!Batman.objectHasKey(object, k)) {
            this.unset(k);
            return removedKeys.push(k);
          }
        }, this));
        return Batman.forEach(object, __bind(function(k, v) {
          if (!this.hasKey(k)) {
            addedKeys.push(k);
          }
          return this.set(k, v);
        }, this));
      });
      if (addedKeys.length > 0) {
        this.fire.apply(this, ['itemsWereAdded'].concat(__slice.call(addedKeys)));
      }
      if (removedKeys.length > 0) {
        return this.fire.apply(this, ['itemsWereRemoved'].concat(__slice.call(removedKeys)));
      }
    });
    Hash.prototype.equality = Batman.SimpleHash.prototype.equality;
    Hash.prototype.hashKeyFor = Batman.SimpleHash.prototype.hashKeyFor;
    _ref = ['hasKey', 'forEach', 'isEmpty', 'keys', 'merge', 'toJSON', 'toObject'];
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
  }).call(this);
  Batman.SimpleSet = (function() {
    function SimpleSet() {
      this._storage = new Batman.SimpleHash;
      this._indexes = new Batman.SimpleHash;
      this._uniqueIndexes = new Batman.SimpleHash;
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
    SimpleSet.prototype.forEach = function(iterator, ctx) {
      var container;
      container = this;
      return this._storage.forEach(function(key) {
        return iterator.call(ctx, key, null, container);
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
    SimpleSet.prototype.replace = function(other) {
      try {
        if (typeof this.prevent === "function") {
          this.prevent('change');
        }
        this.clear();
        return this.add.apply(this, other.toArray());
      } finally {
        if (typeof this.allowAndFire === "function") {
          this.allowAndFire('change', this, this);
        }
      }
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
    SimpleSet.prototype.indexedByUnique = function(key) {
      return this._uniqueIndexes.get(key) || this._uniqueIndexes.set(key, new Batman.UniqueSetIndex(this, key));
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
    _ref = ['add', 'remove', 'clear', 'replace', 'indexedBy', 'indexedByUnique', 'sortedBy'];
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
    Set.accessor('indexedByUnique', function() {
      return new Batman.TerminalAccessible(__bind(function(key) {
        return this.indexedByUnique(key);
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
    Set.accessor('first', function() {
      return this.toArray()[0];
    });
    Set.accessor('last', function() {
      return this.toArray()[this.length - 1];
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
    _ref = ['add', 'remove', 'clear', 'replace'];
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
    SetSort.prototype.forEach = function(iterator, ctx) {
      var e, i, _len, _ref, _results;
      _ref = this.get('_storage');
      _results = [];
      for (i = 0, _len = _ref.length; i < _len; i++) {
        e = _ref[i];
        _results.push(iterator.call(ctx, e, i, this));
      }
      return _results;
    };
    SetSort.prototype.compare = function(a, b) {
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
      if (a === false) {
        return 1;
      }
      if (b === false) {
        return -1;
      }
      if (a === true) {
        return 1;
      }
      if (b === true) {
        return -1;
      }
      if (a !== a) {
        if (b !== b) {
          return 0;
        } else {
          return 1;
        }
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
      return this._resultSetForKey(key).remove(item);
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
  Batman.StateMachine = {
    initialize: function() {
      Batman.initializeObject(this);
      if (!this._batman.states) {
        return this._batman.states = new Batman.SimpleHash;
      }
    },
    state: function(name, callback) {
      Batman.StateMachine.initialize.call(this);
      if (!name) {
        return this._batman.getFirst('state');
      }
      developer.assert(this.isEventEmitter, "StateMachine requires EventEmitter");
      this[name] || (this[name] = function(callback) {
        return _stateMachine_setState.call(this, name);
      });
      if (typeof callback === 'function') {
        return this.on(name, callback);
      }
    },
    transition: function(from, to, callback) {
      Batman.StateMachine.initialize.call(this);
      this.state(from);
      this.state(to);
      if (callback) {
        return this.on("" + from + "->" + to, callback);
      }
    }
  };
  Batman.Object.actsAsStateMachine = function(includeInstanceMethods) {
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
  _stateMachine_setState = function(newState) {
    var oldState, _base, _ref;
    Batman.StateMachine.initialize.call(this);
    if (this._batman.isTransitioning) {
      ((_base = this._batman).nextState || (_base.nextState = [])).push(newState);
      return false;
    }
    this._batman.isTransitioning = true;
    oldState = this.state();
    this._batman.state = newState;
    if (newState && oldState) {
      this.fire("" + oldState + "->" + newState, newState, oldState);
    }
    if (newState) {
      this.fire(newState, newState, oldState);
    }
    this._batman.isTransitioning = false;
    if ((_ref = this._batman.nextState) != null ? _ref.length : void 0) {
      this[this._batman.nextState.shift()]();
    }
    return newState;
  };
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
    Request.prototype.method = 'GET';
    Request.prototype.formData = false;
    Request.prototype.response = null;
    Request.prototype.status = null;
    Request.accessor('method', $mixin({}, Batman.Property.defaultAccessor, {
      set: function(k, val) {
        return this[k] = val != null ? typeof val.toUpperCase === "function" ? val.toUpperCase() : void 0 : void 0;
      }
    }));
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
    App.classAccessor('currentParams', {
      get: function() {
        return new Batman.Hash;
      },
      'final': true
    });
    App.classAccessor('paramsManager', {
      get: function() {
        var nav, params;
        if (!(nav = this.get('navigator'))) {
          return;
        }
        params = this.get('currentParams');
        return params.replacer = new Batman.ParamsReplacer(nav, params);
      },
      'final': true
    });
    App.classAccessor('paramsPusher', {
      get: function() {
        var nav, params;
        if (!(nav = this.get('navigator'))) {
          return;
        }
        params = this.get('currentParams');
        return params.pusher = new Batman.ParamsPusher(nav, params);
      },
      'final': true
    });
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
          context: this,
          node: document
        }));
      } else if (typeof this.layout === 'string') {
        this.set('layout', new this[helpers.camelize(this.layout) + 'View']);
      }
      if (typeof this.navigator === 'undefined' && this.dispatcher.routeMap) {
        this.on('run', __bind(function() {
          return this.set('navigator', Batman.navigator = Batman.Navigator.forApp(this)).start();
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
          result.target = this.dispatcher.app.controllers.get(result.controller);
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
      params = this.parameterize(url);
      this.dispatcher.app.get('currentParams').replace(params);
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
        return controller.get('sharedController');
      };
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
      } else {
        if ($typeOf(params) === 'Object') {
          this.app.get('currentParams').replace(params);
        } else {
          this.app.get('currentParams').clear();
        }
        if (url !== '/404') {
          $redirect('/404');
        }
      }
      this.app.set('currentURL', url);
      this.app.set('currentRoute', route);
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
  Batman.ParamsReplacer = (function() {
    __extends(ParamsReplacer, Batman.Object);
    function ParamsReplacer(navigator, params) {
      this.navigator = navigator;
      this.params = params;
    }
    ParamsReplacer.prototype.redirect = function() {
      return this.navigator.replace(this.toObject());
    };
    ParamsReplacer.prototype.replace = function(params) {
      this.params.replace(params);
      return this.redirect();
    };
    ParamsReplacer.prototype.update = function(params) {
      this.params.update(params);
      return this.redirect();
    };
    ParamsReplacer.prototype.clear = function() {
      this.params.clear();
      return this.redirect();
    };
    ParamsReplacer.prototype.toObject = function() {
      return this.params.toObject();
    };
    ParamsReplacer.accessor({
      get: function(k) {
        return this.params.get(k);
      },
      set: function(k, v) {
        var oldValue, result;
        oldValue = this.params.get(k);
        result = this.params.set(k, v);
        if (oldValue !== v) {
          this.redirect();
        }
        return result;
      },
      unset: function(k) {
        var hadKey, result;
        hadKey = this.params.hasKey(k);
        result = this.params.unset(k);
        if (hadKey) {
          this.redirect();
        }
        return result;
      }
    });
    return ParamsReplacer;
  })();
  Batman.ParamsPusher = (function() {
    __extends(ParamsPusher, Batman.ParamsReplacer);
    function ParamsPusher() {
      ParamsPusher.__super__.constructor.apply(this, arguments);
    }
    ParamsPusher.prototype.redirect = function() {
      return this.navigator.push(this.toObject());
    };
    return ParamsPusher;
  })();
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
    resource: function(resource, options, callback) {
      var app, controller, ops, _route;
      if (options == null) {
        options = {};
      }
      if (typeof options === 'function') {
        callback = options;
        options = {};
      }
      resource = helpers.pluralize(resource);
      controller = options.controller || resource;
      _route = __bind(function(url, signature, action) {
        return this.route(url, signature, {
          resource: controller,
          action: action
        });
      }, this);
      if (options.parentResource) {
        resource = "" + options.parentResource + "/:" + (helpers.singularize(options.parentResource)) + "Id/" + resource;
      }
      if (options.index !== false) {
        _route(resource, "" + controller + "#index", 'index');
      }
      if (options["new"] !== false) {
        _route("" + resource + "/new", "" + controller + "#new", 'new');
      }
      if (options.show !== false) {
        _route("" + resource + "/:id", "" + controller + "#show", 'show');
      }
      if (options.edit !== false) {
        _route("" + resource + "/:id/edit", "" + controller + "#edit", 'edit');
      }
      if (callback) {
        app = this;
        ops = {
          resource: resource,
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
          resources: __bind(function(childResources, options, callback) {
            if (options == null) {
              options = {};
            }
            if (typeof options === 'function') {
              callback = options;
              options = {};
            }
            options.parentResource = resource;
            return this.resources(childResources, options, callback);
          }, this)
        };
        return callback.call(ops);
      }
    },
    resources: function(resources, options, callback) {
      var resource, _i, _len, _results;
      if (resources instanceof Array) {
        _results = [];
        for (_i = 0, _len = resources.length; _i < _len; _i++) {
          resource = resources[_i];
          _results.push(this.resource(resource, options, callback));
        }
        return _results;
      } else {
        return this.resource(resources, options, callback);
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
    Controller.accessor('controllerName', function() {
      return this._controllerName || (this._controllerName = helpers.underscore($functionName(this.constructor).replace('Controller', '')));
    });
    Controller.beforeFilter = function(nameOrFunction) {
      var filters, _base;
      Batman.initializeObject(this);
      filters = (_base = this._batman).beforeFilters || (_base.beforeFilters = []);
      if (filters.indexOf(nameOrFunction) === -1) {
        return filters.push(nameOrFunction);
      }
    };
    Controller.afterFilter = function(nameOrFunction) {
      var filters, _base;
      Batman.initializeObject(this);
      filters = (_base = this._batman).afterFilters || (_base.afterFilters = []);
      if (filters.indexOf(nameOrFunction) === -1) {
        return filters.push(nameOrFunction);
      }
    };
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
      this._inAction = true;
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
      delete this._inAction;
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
      if (this._actedDuringAction && this._inAction) {
        developer.warn("Warning! Trying to redirect but an action has already be taken during " + (this.get('controllerName')) + "." + (this.get('action')) + "}");
      }
      if (this._inAction) {
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
      var view, _ref, _ref2;
      if (options == null) {
        options = {};
      }
      if (this._actedDuringAction && this._inAction) {
        developer.warn("Warning! Trying to render but an action has already be taken during " + (this.get('controllerName')) + "." + (this.get('action')));
      }
      this._actedDuringAction = true;
      if (options === false) {
        return;
      }
      if (!options.view) {
        options.context || (options.context = this);
        options.source || (options.source = helpers.underscore(this.get('controllerName') + '/' + this.get('action')));
        options.view = new (((_ref = Batman.currentApp) != null ? _ref[helpers.camelize("" + (this.get('controllerName')) + "_" + (this.get('action')) + "_view")] : void 0) || Batman.View)(options);
      }
      if (view = options.view) {
        if ((_ref2 = Batman.currentApp) != null) {
          _ref2.prevent('ready');
        }
        view.on('ready', __bind(function() {
          var node, yieldTo, yieldingNode, _ref3;
          node = view.get('node');
          yieldTo = options.into || 'main';
          if (view.hasContainer) {
            if (yieldingNode = Batman.DOM._yields[yieldTo]) {
              $setInnerHTML(yieldingNode, '');
              while (node.childNodes.length > 0) {
                $appendChild(yieldingNode, node.childNodes[0]);
              }
            }
          } else {
            Batman.DOM.replace(yieldTo, node);
          }
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
    var k, _fn, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3;
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
    Model.classAccessor('all', {
      get: function() {
        var _ref;
        if (this.prototype.hasStorage() && ((_ref = this.classState()) !== 'loaded' && _ref !== 'loading')) {
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
      if ($typeOf(options) === 'Function') {
        callback = options;
        options = {};
      }
      developer.assert(this.prototype._batman.getAll('storage').length, "Can't load model " + ($functionName(this)) + " without any storage adapters!");
      this.loading();
      return this.prototype._doStorageOperation('readAll', options, __bind(function(err, records) {
        var mappedRecords, record;
        if (err != null) {
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
          this.loaded();
          return typeof callback === "function" ? callback(err, mappedRecords) : void 0;
        }
      }, this));
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
    _ref = ['belongsTo', 'hasOne', 'hasMany'];
    _fn = __bind(function(k) {
      return this[k] = function(label, scope) {
        var collection, _base;
        this._batman.check(this);
        collection = (_base = this._batman).associations || (_base.associations = new Batman.AssociationCollection(this));
        return collection.add(new Batman["" + (helpers.capitalize(k)) + "Association"](this, label, scope));
      };
    }, Model);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      k = _ref[_i];
      _fn(k);
    }
    Model.prototype.associationProxy = function(association) {
      var proxies, _base;
      Batman.initializeObject(this);
      proxies = (_base = this._batman).associationProxies || (_base.associationProxies = new Batman.SimpleHash);
      return proxies.get(association.label) || proxies.set(association.label, new association.proxyClass(association, this));
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
        var pk;
        if (typeof v === "string" && v.match(/[^0-9]/) === null) {
          v = parseInt(v, 10);
        }
        pk = this.constructor.primaryKey;
        if (pk === 'id') {
          return this.id = v;
        } else {
          return this.set(pk, v);
        }
      }
    });
    Model.accessor('dirtyKeys', 'errors', Batman.Property.defaultAccessor);
    Model.accessor('batmanState', {
      get: function() {
        return this.state();
      },
      set: function(k, v) {
        return this.state(v);
      }
    });
    Model.accessor(Model.defaultAccessor = {
      get: function(k) {
        var attribute, _base;
        attribute = ((_base = this._batman).attributes || (_base.attributes = {}))[k];
        if (typeof attribute !== 'undefined') {
          return attribute;
        } else {
          return this[k];
        }
      },
      set: function(k, v) {
        var _base;
        return ((_base = this._batman).attributes || (_base.attributes = {}))[k] = v;
      },
      unset: function(k) {
        var x, _base;
        x = ((_base = this._batman).attributes || (_base.attributes = {}))[k];
        delete this._batman.attributes[k];
        return x;
      }
    });
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
      if ($typeOf(idOrAttributes) === 'Object') {
        Model.__super__.constructor.call(this, idOrAttributes);
      } else {
        Model.__super__.constructor.call(this);
        this.set('id', idOrAttributes);
      }
      if (!this.state()) {
        this.empty();
      }
    }
    Model.prototype.set = function(key, value) {
      var oldValue, result, _ref2;
      oldValue = this.get(key);
      if (oldValue === value) {
        return;
      }
      result = Model.__super__.set.apply(this, arguments);
      this.dirtyKeys.set(key, oldValue);
      if ((_ref2 = this.state()) !== 'dirty' && _ref2 !== 'loading' && _ref2 !== 'creating') {
        this.dirty();
      }
      return result;
    };
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
      encoders = this._batman.get('encoders');
      if (!(!encoders || encoders.isEmpty())) {
        encoders.forEach(__bind(function(key, encoder) {
          var encodedVal, val;
          val = this.get(key);
          if (typeof val !== 'undefined') {
            encodedVal = encoder(val, key, obj, this);
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
      decoders = this._batman.get('decoders');
      if (!decoders || decoders.isEmpty()) {
        for (key in data) {
          value = data[key];
          obj[key] = value;
        }
      } else {
        decoders.forEach(__bind(function(key, decoder) {
          if (typeof data[key] !== 'undefined') {
            return obj[key] = decoder(data[key], key, data, obj, this);
          }
        }, this));
      }
      developer["do"](__bind(function() {
        if ((!decoders) || decoders.length <= 1) {
          return developer.warn("Warning: Model " + ($functionName(this.constructor)) + " has suspiciously few decoders!");
        }
      }, this));
      return this.mixin(obj);
    };
    Model.actsAsStateMachine(true);
    _ref2 = ['empty', 'dirty', 'loading', 'loaded', 'saving', 'saved', 'creating', 'created', 'validating', 'validated', 'destroying', 'destroyed'];
    for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
      k = _ref2[_j];
      Model.state(k);
    }
    _ref3 = ['loading', 'loaded'];
    for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
      k = _ref3[_k];
      Model.classState(k);
    }
    Model.prototype._doStorageOperation = function(operation, options, callback) {
      var mechanism, mechanisms, _l, _len4;
      developer.assert(this.hasStorage(), "Can't " + operation + " model " + ($functionName(this.constructor)) + " without any storage adapters!");
      mechanisms = this._batman.get('storage');
      for (_l = 0, _len4 = mechanisms.length; _l < _len4; _l++) {
        mechanism = mechanisms[_l];
        mechanism[operation](this, options, callback);
      }
      return true;
    };
    Model.prototype.hasStorage = function() {
      return (this._batman.get('storage') || []).length > 0;
    };
    Model.prototype.load = function(callback) {
      var _ref4;
      if ((_ref4 = this.state()) === 'destroying' || _ref4 === 'destroyed') {
        if (typeof callback === "function") {
          callback(new Error("Can't load a destroyed record!"));
        }
        return;
      }
      this.loading();
      return this._doStorageOperation('read', {}, __bind(function(err, record) {
        if (!err) {
          this.loaded();
          record = this.constructor._mapIdentity(record);
        }
        return typeof callback === "function" ? callback(err, record) : void 0;
      }, this));
    };
    Model.prototype.save = function(callback) {
      var _ref4;
      if ((_ref4 = this.state()) === 'destroying' || _ref4 === 'destroyed') {
        if (typeof callback === "function") {
          callback(new Error("Can't save a destroyed record!"));
        }
        return;
      }
      return this.validate(__bind(function(isValid, errors) {
        var associations, creating, _ref5, _ref6;
        if (!isValid) {
          if (typeof callback === "function") {
            callback(errors);
          }
          return;
        }
        creating = this.isNew();
        this.saving();
        if (creating) {
          this.creating();
        }
        associations = (_ref5 = this.constructor._batman.associations) != null ? _ref5.getAllByType() : void 0;
        if (associations != null) {
          if ((_ref6 = associations.get('belongsTo')) != null) {
            _ref6.forEach(__bind(function(association, label) {
              return association.apply(this);
            }, this));
          }
        }
        return this._doStorageOperation((creating ? 'create' : 'update'), {}, __bind(function(err, record) {
          var _ref7, _ref8;
          if (!err) {
            if (creating) {
              this.created();
            }
            this.saved();
            this.dirtyKeys.clear();
            if (associations != null) {
              if ((_ref7 = associations.get('hasOne')) != null) {
                _ref7.forEach(function(association) {
                  return association.apply(err, record);
                });
              }
            }
            if (associations != null) {
              if ((_ref8 = associations.get('hasMany')) != null) {
                _ref8.forEach(function(association) {
                  return association.apply(err, record);
                });
              }
            }
            record = this.constructor._mapIdentity(record);
          }
          return typeof callback === "function" ? callback(err, record) : void 0;
        }, this));
      }, this));
    };
    Model.prototype.destroy = function(callback) {
      this.destroying();
      return this._doStorageOperation('destroy', {}, __bind(function(err, record) {
        if (!err) {
          this.constructor.get('all').remove(this);
          this.destroyed();
        }
        return typeof callback === "function" ? callback(err) : void 0;
      }, this));
    };
    Model.prototype.validate = function(callback) {
      var count, finish, key, oldState, v, validationCallback, validator, validators, _l, _len4, _len5, _m, _ref4;
      oldState = this.state();
      this.errors.clear();
      this.validating();
      finish = __bind(function() {
        this.validated();
        this[oldState]();
        return typeof callback === "function" ? callback(this.errors.length === 0, this.errors) : void 0;
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
        for (_l = 0, _len4 = validators.length; _l < _len4; _l++) {
          validator = validators[_l];
          v = validator.validator;
          _ref4 = validator.keys;
          for (_m = 0, _len5 = _ref4.length; _m < _len5; _m++) {
            key = _ref4[_m];
            if (v) {
              v.validateEach(this.errors, this, key, validationCallback);
            } else {
              validator.callback(this.errors, this, key, validationCallback);
            }
          }
        }
      }
    };
    Model.prototype.isNew = function() {
      return typeof this.get('id') === 'undefined';
    };
    return Model;
  }).call(this);
  Batman.AssociationCollection = (function() {
    AssociationCollection.availableAssociations = ['belongsTo', 'hasOne', 'hasMany'];
    function AssociationCollection(model) {
      this.model = model;
      this.byTypeStorage = new Batman.SimpleHash;
      this.byLabelStorage = new Batman.SimpleHash;
    }
    AssociationCollection.prototype.add = function(association) {
      var associationTypeHash;
      this.byLabelStorage.set(association.label, association);
      if (!(associationTypeHash = this.byTypeStorage.get(association.constructor))) {
        associationTypeHash = new Batman.SimpleHash;
        this.byTypeStorage.set(association.associationType, associationTypeHash);
      }
      return associationTypeHash.set(association, association.label);
    };
    AssociationCollection.prototype.getByType = function(type) {
      return this.byTypeStorage.get(type);
    };
    AssociationCollection.prototype.getByLabel = function(label) {
      return this.byLabelStorage.get(label);
    };
    AssociationCollection.prototype.getAllByType = function() {
      var ancestorCollection, ancestorCollections, ancestorValuesAtKey, key, newStorage, val, _i, _len, _ref, _ref2;
      this.model._batman.check(this.model);
      ancestorCollections = this.model._batman.ancestors(function(ancestor) {
        var _ref;
        return (_ref = ancestor._batman) != null ? _ref.get('associations') : void 0;
      });
      newStorage = new Batman.SimpleHash;
      _ref = Batman.AssociationCollection.availableAssociations;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        key = _ref[_i];
        ancestorValuesAtKey = (function() {
          var _j, _len2, _results;
          _results = [];
          for (_j = 0, _len2 = ancestorCollections.length; _j < _len2; _j++) {
            ancestorCollection = ancestorCollections[_j];
            if (val = ancestorCollection != null ? ancestorCollection.getByType(key) : void 0) {
              _results.push(val);
            }
          }
          return _results;
        })();
        newStorage.set(key, (_ref2 = this.byTypeStorage.get(key) || new Batman.SimpleHash).merge.apply(_ref2, ancestorValuesAtKey));
      }
      this.byTypeStorage = newStorage;
      this.getAllByType = function() {
        return this.byTypeStorage;
      };
      return this.byTypeStorage;
    };
    AssociationCollection.prototype.associationForLabel = function(searchLabel) {
      var ret;
      ret = void 0;
      this.getAllByType().forEach(function(type, associations) {
        if (ret) {
          return;
        }
        return associations.forEach(function(association, label) {
          if (ret) {
            return;
          }
          if (label === searchLabel) {
            return ret = association;
          }
        });
      });
      return ret;
    };
    return AssociationCollection;
  })();
  Batman.Association = (function() {
    Association.prototype.associationType = '';
    Association.prototype.defaultOptions = {
      saveInline: true,
      autoload: true
    };
    function Association(model, label, options) {
      var defaultOptions, getAccessor, self;
      this.model = model;
      this.label = label;
      if (options == null) {
        options = {};
      }
      defaultOptions = {
        namespace: Batman.currentApp,
        name: helpers.camelize(helpers.singularize(this.label))
      };
      this.options = $mixin(defaultOptions, this.defaultOptions, options);
      model.encode(label, this.encoder());
      self = this;
      getAccessor = function() {
        return self.getAccessor.call(this, self, model, label);
      };
      model.accessor(label, {
        get: getAccessor,
        set: model.defaultAccessor.set,
        unset: model.defaultAccessor.unset
      });
      if (this.url) {
        model.url || (model.url = function(recordOptions) {
          return self.url(recordOptions);
        });
      }
    }
    Association.prototype.setIndex = function() {
      this.index || (this.index = new Batman.AssociationSetIndex(this));
      return this.index;
    };
    Association.prototype.getAccessor = function(self, model, label) {
      var proxy, recordInAttributes;
      if (recordInAttributes = self.getFromAttributes(this)) {
        return recordInAttributes;
      }
      if (self.getRelatedModel()) {
        proxy = this.associationProxy(self);
        if (!proxy.get('loaded') && self.options.autoload) {
          proxy.load();
        }
        return proxy;
      }
    };
    Association.prototype.getRelatedModel = function() {
      var modelName, scope;
      scope = this.options.namespace || Batman.currentApp;
      modelName = this.options.name;
      return scope != null ? scope[modelName] : void 0;
    };
    Association.prototype.getFromAttributes = function(record) {
      return record.constructor.defaultAccessor.get.call(record, this.label);
    };
    Association.prototype.encoder = function() {
      return developer.error("You must override encoder in Batman.Association subclasses.");
    };
    Association.prototype.inverse = function() {
      var inverse, relatedAssocs;
      if (relatedAssocs = this.getRelatedModel()._batman.associations) {
        if (this.options.inverseOf) {
          return relatedAssocs.getByLabel(this.options.inverseOf);
        }
        inverse = null;
        relatedAssocs.byLabelStorage.forEach(__bind(function(label, assoc) {
          if (assoc.getRelatedModel() === this.model) {
            return inverse = assoc;
          }
        }, this));
        return inverse;
      }
    };
    return Association;
  })();
  Batman.SingularAssociation = (function() {
    __extends(SingularAssociation, Batman.Association);
    function SingularAssociation() {
      SingularAssociation.__super__.constructor.apply(this, arguments);
    }
    SingularAssociation.prototype.isSingular = true;
    return SingularAssociation;
  })();
  Batman.PluralAssociation = (function() {
    __extends(PluralAssociation, Batman.Association);
    function PluralAssociation() {
      PluralAssociation.__super__.constructor.apply(this, arguments);
    }
    PluralAssociation.prototype.isPlural = true;
    return PluralAssociation;
  })();
  Batman.AssociationProxy = (function() {
    __extends(AssociationProxy, Batman.Object);
    function AssociationProxy(association, model) {
      this.association = association;
      this.model = model;
    }
    AssociationProxy.prototype.loaded = false;
    AssociationProxy.prototype.toJSON = function() {
      if (this.loaded) {
        return this.get('target').toJSON();
      }
    };
    AssociationProxy.prototype.load = function(callback) {
      this.fetch(__bind(function(err, relation) {
        this.set('target', relation);
        return typeof callback === "function" ? callback(void 0, relation) : void 0;
      }, this));
      return this.get('target');
    };
    AssociationProxy.accessor('loaded', {
      get: function() {
        return this.loaded;
      },
      set: function(_, v) {
        return this.loaded = v;
      }
    });
    AssociationProxy.accessor('target', {
      get: function() {
        var id;
        if (id = this.model.get(this.association.localKey)) {
          return this.association.getRelatedModel().get('loaded').indexedByUnique('id').get(id);
        }
      },
      set: function(_, v) {
        return v;
      }
    });
    AssociationProxy.accessor({
      get: function(k) {
        var _ref;
        return (_ref = this.get('target')) != null ? _ref.get(k) : void 0;
      },
      set: function(k, v) {
        var _ref;
        return (_ref = this.get('target')) != null ? _ref.set(k, v) : void 0;
      }
    });
    return AssociationProxy;
  })();
  Batman.BelongsToProxy = (function() {
    __extends(BelongsToProxy, Batman.AssociationProxy);
    function BelongsToProxy() {
      BelongsToProxy.__super__.constructor.apply(this, arguments);
    }
    BelongsToProxy.prototype.fetch = function(callback) {
      var loadedRecords, relatedID;
      if (relatedID = this.model.get(this.association.localKey)) {
        loadedRecords = this.association.setIndex().get(relatedID);
        if (!loadedRecords.isEmpty()) {
          this.set('loaded', true);
          return callback(void 0, loadedRecords.toArray()[0]);
        } else {
          return this.association.getRelatedModel().find(relatedID, __bind(function(error, loadedRecord) {
            if (error) {
              throw error;
            }
            if (loadedRecord) {
              this.set('loaded', true);
            }
            return callback(void 0, loadedRecord);
          }, this));
        }
      }
    };
    return BelongsToProxy;
  })();
  Batman.HasOneProxy = (function() {
    __extends(HasOneProxy, Batman.AssociationProxy);
    function HasOneProxy() {
      HasOneProxy.__super__.constructor.apply(this, arguments);
    }
    HasOneProxy.prototype.fetch = function(callback) {
      var id, loadOptions, relatedRecords;
      if (id = this.model.get(this.association.localKey)) {
        relatedRecords = this.association.setIndex().get(id);
        if (!relatedRecords.isEmpty()) {
          this.set('loaded', true);
          return callback(void 0, relatedRecords.toArray()[0]);
        } else {
          loadOptions = {};
          loadOptions[this.association.foreignKey] = id;
          return this.association.getRelatedModel().load(loadOptions, __bind(function(error, loadedRecords) {
            if (error) {
              throw error;
            }
            if (!loadedRecords || loadedRecords.length <= 0) {
              return callback(new Error("Couldn't find related record!"), void 0);
            } else {
              this.set('loaded', true);
              return callback(void 0, loadedRecords[0]);
            }
          }, this));
        }
      }
    };
    return HasOneProxy;
  })();
  Batman.AssociationSet = (function() {
    __extends(AssociationSet, Batman.Set);
    function AssociationSet(key, association) {
      this.key = key;
      this.association = association;
      AssociationSet.__super__.constructor.call(this);
    }
    AssociationSet.prototype.loaded = false;
    AssociationSet.prototype.load = function(callback) {
      var loadOptions;
      loadOptions = {};
      loadOptions[this.association.foreignKey] = this.key;
      return this.association.getRelatedModel().load(loadOptions, __bind(function(err, records) {
        if (!err) {
          this.loaded = true;
        }
        return callback(err, this);
      }, this));
    };
    return AssociationSet;
  })();
  Batman.AssociationSetIndex = (function() {
    __extends(AssociationSetIndex, Batman.SetIndex);
    function AssociationSetIndex(association) {
      this.association = association;
      AssociationSetIndex.__super__.constructor.call(this, this.association.getRelatedModel().get('loaded'), this.association.foreignKey);
    }
    AssociationSetIndex.prototype._resultSetForKey = function(key) {
      return this._storage.getOrSet(key, __bind(function() {
        return new Batman.AssociationSet(key, this.association);
      }, this));
    };
    return AssociationSetIndex;
  })();
  Batman.BelongsToAssociation = (function() {
    __extends(BelongsToAssociation, Batman.SingularAssociation);
    BelongsToAssociation.prototype.associationType = 'belongsTo';
    BelongsToAssociation.prototype.proxyClass = Batman.BelongsToProxy;
    BelongsToAssociation.prototype.defaultOptions = {
      saveInline: false,
      autoload: true
    };
    function BelongsToAssociation() {
      BelongsToAssociation.__super__.constructor.apply(this, arguments);
      this.localKey = this.options.localKey || ("" + this.label + "_id");
      this.foreignKey = this.options.foreignKey || "id";
      this.model.encode(this.localKey);
    }
    BelongsToAssociation.prototype.url = function(recordOptions) {
      var ending, helper, id, inverse, root;
      if (inverse = this.inverse()) {
        root = Batman.helpers.pluralize(this.label);
        id = recordOptions["" + this.label + "_id"];
        helper = inverse.isSingular ? "singularize" : "pluralize";
        ending = Batman.helpers[helper](inverse.label);
        return "/" + root + "/" + id + "/" + ending;
      }
    };
    BelongsToAssociation.prototype.encoder = function() {
      var association;
      association = this;
      return {
        encode: function(val) {
          if (!association.options.saveInline) {
            return;
          }
          return val.toJSON();
        },
        decode: function(data, _, __, ___, childRecord) {
          var inverse, record, relatedModel;
          relatedModel = association.getRelatedModel();
          record = new relatedModel();
          record.fromJSON(data);
          record = relatedModel._mapIdentity(record);
          if (association.options.inverseOf) {
            if (inverse = association.inverse()) {
              if (inverse instanceof Batman.HasManyAssociation) {
                childRecord.set(association.localKey, record.get(association.foreignKey));
              } else {
                record.set(inverse.label, childRecord);
              }
            }
          }
          childRecord.set(association.label, record);
          return record;
        }
      };
    };
    BelongsToAssociation.prototype.apply = function(base) {
      var model;
      if (model = base.get(this.label)) {
        return base.set(this.localKey, model.get(this.foreignKey));
      }
    };
    return BelongsToAssociation;
  })();
  Batman.HasOneAssociation = (function() {
    __extends(HasOneAssociation, Batman.SingularAssociation);
    HasOneAssociation.prototype.associationType = 'hasOne';
    HasOneAssociation.prototype.proxyClass = Batman.HasOneProxy;
    function HasOneAssociation() {
      HasOneAssociation.__super__.constructor.apply(this, arguments);
      this.localKey = this.options.localKey || "id";
      this.foreignKey = this.options.foreignKey || ("" + (helpers.underscore($functionName(this.model))) + "_id");
    }
    HasOneAssociation.prototype.apply = function(baseSaveError, base) {
      var relation;
      if (relation = base.constructor.defaultAccessor.get.call(base, this.label)) {
        return relation.set(this.foreignKey, base.get(this.localKey));
      }
    };
    HasOneAssociation.prototype.encoder = function() {
      var association;
      association = this;
      return {
        encode: function(val, key, object, record) {
          var json;
          if (!association.options.saveInline) {
            return;
          }
          if (json = val.toJSON()) {
            json[association.foreignKey] = record.get(association.localKey);
          }
          return json;
        },
        decode: function(data, _, __, ___, parentRecord) {
          var record, relatedModel;
          relatedModel = association.getRelatedModel();
          record = new relatedModel();
          record.fromJSON(data);
          if (association.options.inverseOf) {
            record.set(association.options.inverseOf, parentRecord);
          }
          record = relatedModel._mapIdentity(record);
          return record;
        }
      };
    };
    return HasOneAssociation;
  })();
  Batman.HasManyAssociation = (function() {
    __extends(HasManyAssociation, Batman.PluralAssociation);
    HasManyAssociation.prototype.associationType = 'hasMany';
    function HasManyAssociation() {
      HasManyAssociation.__super__.constructor.apply(this, arguments);
      this.localKey = this.options.localKey || "id";
      this.foreignKey = this.options.foreignKey || ("" + (helpers.underscore($functionName(this.model))) + "_id");
    }
    HasManyAssociation.prototype.getAccessor = function(self, model, label) {
      var id, recordInAttributes, relatedRecords;
      if (this.amSetting) {
        return;
      }
      if (!self.getRelatedModel()) {
        return;
      }
      if (recordInAttributes = self.getFromAttributes(this)) {
        return recordInAttributes;
      }
      if (id = this.get(self.localKey)) {
        relatedRecords = self.setIndex().get(id);
        this.amSetting = true;
        this.set(label, relatedRecords);
        this.amSetting = false;
        if (self.options.autoload && !relatedRecords.loaded) {
          relatedRecords.load(function(error, records) {
            if (error) {
              throw error;
            }
          });
        }
        return relatedRecords;
      }
    };
    HasManyAssociation.prototype.apply = function(baseSaveError, base) {
      var relations;
      if (relations = base.constructor.defaultAccessor.get.call(base, this.label)) {
        return relations.forEach(__bind(function(model) {
          return model.set(this.foreignKey, base.get(this.localKey));
        }, this));
      }
    };
    HasManyAssociation.prototype.encoder = function() {
      var association;
      association = this;
      return {
        encode: function(relationSet, _, __, record) {
          var jsonArray;
          if (association._beingEncoded) {
            return;
          }
          association._beingEncoded = true;
          if (!association.options.saveInline) {
            return;
          }
          if (relationSet != null) {
            jsonArray = [];
            relationSet.forEach(function(relation) {
              var relationJSON;
              relationJSON = relation.toJSON();
              relationJSON[association.foreignKey] = record.get(association.localKey);
              return jsonArray.push(relationJSON);
            });
          }
          delete association._beingEncoded;
          return jsonArray;
        },
        decode: function(data, _, __, ___, parentRecord) {
          var jsonObject, record, relatedModel, relations, _i, _len;
          relations = new Batman.Set;
          if (relatedModel = association.getRelatedModel()) {
            for (_i = 0, _len = data.length; _i < _len; _i++) {
              jsonObject = data[_i];
              record = new relatedModel;
              record.fromJSON(jsonObject);
              if (association.options.inverseOf) {
                record.set(association.options.inverseOf, parentRecord);
              }
              record = relatedModel._mapIdentity(record);
              relations.add(record);
            }
          } else {
            developer.error("Can't decode model " + association.options.name + " because it hasn't been loaded yet!");
          }
          return relations;
        }
      };
    };
    return HasManyAssociation;
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
        var options, value, _ref;
        options = this.options;
        value = (_ref = record.get(key)) != null ? _ref : [];
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
    __extends(StorageAdapter, Batman.Object);
    StorageAdapter.StorageError = (function() {
      __extends(StorageError, Error);
      StorageError.prototype.name = "StorageError";
      function StorageError(message) {
        StorageError.__super__.constructor.apply(this, arguments);
        this.message = message;
      }
      return StorageError;
    })();
    StorageAdapter.RecordExistsError = (function() {
      __extends(RecordExistsError, StorageAdapter.StorageError);
      RecordExistsError.prototype.name = 'RecordExistsError';
      function RecordExistsError(message) {
        RecordExistsError.__super__.constructor.call(this, message || "Can't create this record because it already exists in the store!");
      }
      return RecordExistsError;
    })();
    StorageAdapter.NotFoundError = (function() {
      __extends(NotFoundError, StorageAdapter.StorageError);
      NotFoundError.prototype.name = 'NotFoundError';
      function NotFoundError(message) {
        NotFoundError.__super__.constructor.call(this, message || "Record couldn't be found in storage!");
      }
      return NotFoundError;
    })();
    function StorageAdapter(model) {
      StorageAdapter.__super__.constructor.call(this, {
        model: model
      });
    }
    StorageAdapter.prototype.isStorageAdapter = true;
    StorageAdapter.prototype.storageKey = function(record) {
      var model;
      model = (record != null ? record.constructor : void 0) || this.model;
      return model.get('storageKey') || helpers.pluralize(helpers.underscore($functionName(model)));
    };
    StorageAdapter.prototype.getRecordFromData = function(attributes, constructor) {
      var record;
      if (constructor == null) {
        constructor = this.model;
      }
      record = new constructor();
      record.fromJSON(attributes);
      return record;
    };
    StorageAdapter.skipIfError = function(f) {
      return function(data, next) {
        if (data.error != null) {
          return next();
        } else {
          return f.call(this, data, next);
        }
      };
    };
    StorageAdapter.prototype.before = function() {
      return this._addFilter.apply(this, ['before'].concat(__slice.call(arguments)));
    };
    StorageAdapter.prototype.after = function() {
      return this._addFilter.apply(this, ['after'].concat(__slice.call(arguments)));
    };
    StorageAdapter.prototype._inheritFilters = function() {
      var filtersByKey, filtersList, key, oldFilters, position, _results;
      if (!this._batman.check(this) || !this._batman.filters) {
        oldFilters = this._batman.getFirst('filters');
        this._batman.filters = {
          before: {},
          after: {}
        };
        if (oldFilters != null) {
          _results = [];
          for (position in oldFilters) {
            filtersByKey = oldFilters[position];
            _results.push((function() {
              var _results2;
              _results2 = [];
              for (key in filtersByKey) {
                filtersList = filtersByKey[key];
                _results2.push(this._batman.filters[position][key] = filtersList.slice(0));
              }
              return _results2;
            }).call(this));
          }
          return _results;
        }
      }
    };
    StorageAdapter.prototype._addFilter = function() {
      var filter, key, keys, position, _base, _i, _j, _len;
      position = arguments[0], keys = 3 <= arguments.length ? __slice.call(arguments, 1, _i = arguments.length - 1) : (_i = 1, []), filter = arguments[_i++];
      this._inheritFilters();
      for (_j = 0, _len = keys.length; _j < _len; _j++) {
        key = keys[_j];
        (_base = this._batman.filters[position])[key] || (_base[key] = []);
        this._batman.filters[position][key].push(filter);
      }
      return true;
    };
    StorageAdapter.prototype.runFilter = function(position, action, data, callback) {
      var actionFilters, allFilters, filters, next;
      this._inheritFilters();
      allFilters = this._batman.filters[position].all || [];
      actionFilters = this._batman.filters[position][action] || [];
      data.action = action;
      filters = actionFilters.concat(allFilters);
      next = __bind(function(error) {
        var nextFilter;
        if (error != null) {
          data.error = error;
        }
        if ((nextFilter = filters.shift()) != null) {
          return nextFilter.call(this, data, next);
        } else {
          return callback.call(this, data);
        }
      }, this);
      return next();
    };
    StorageAdapter.prototype.runBeforeFilter = function() {
      return this.runFilter.apply(this, ['before'].concat(__slice.call(arguments)));
    };
    StorageAdapter.prototype.runAfterFilter = function(action, data, callback) {
      return this.runFilter('after', action, data, this.exportResult(callback));
    };
    StorageAdapter.prototype.exportResult = function(callback) {
      return function(data) {
        return callback(data.error, data.result, data);
      };
    };
    StorageAdapter.prototype._jsonToAttributes = function(json) {
      var data;
      try {
        data = JSON.parse(json);
      } catch (jsonError) {
        return [jsonError, {}];
      }
      return [void 0, data];
    };
    return StorageAdapter;
  })();
  Batman.LocalStorage = (function() {
    var key, _fn, _i, _len, _ref;
    __extends(LocalStorage, Batman.StorageAdapter);
    function LocalStorage() {
      if (typeof window.localStorage === 'undefined') {
        return null;
      }
      LocalStorage.__super__.constructor.apply(this, arguments);
      this.storage = localStorage;
    }
    LocalStorage.prototype.storageRegExpForRecord = function(record) {
      return new RegExp("^" + (this.storageKey(record)) + "(\\d+)$");
    };
    LocalStorage.prototype.nextIdForRecord = function(record) {
      var nextId, re;
      re = this.storageRegExpForRecord(record);
      nextId = 1;
      this._forAllStorageEntries(function(k, v) {
        var matches;
        if (matches = re.exec(k)) {
          return nextId = Math.max(nextId, parseInt(matches[1], 10) + 1);
        }
      });
      return nextId;
    };
    LocalStorage.prototype._forAllStorageEntries = function(iterator) {
      var i, key, _ref;
      for (i = 0, _ref = this.storage.length; 0 <= _ref ? i < _ref : i > _ref; 0 <= _ref ? i++ : i--) {
        key = this.storage.key(i);
        iterator.call(this, key, this.storage.getItem(key));
      }
      return true;
    };
    LocalStorage.prototype._storageEntriesMatching = function(proto, options) {
      var re, records;
      re = this.storageRegExpForRecord(proto);
      records = [];
      this._forAllStorageEntries(function(storageKey, data) {
        var error, keyMatches, _ref;
        if (keyMatches = re.exec(storageKey)) {
          _ref = this._jsonToAttributes(data), error = _ref[0], data = _ref[1];
          if (error != null) {
            return [error, []];
          }
          data[proto.constructor.primaryKey] = keyMatches[1];
          if (this._dataMatches(options, data)) {
            return records.push(data);
          }
        }
      });
      return [void 0, records];
    };
    LocalStorage.prototype._dataMatches = function(conditions, data) {
      var k, match, v;
      match = true;
      for (k in conditions) {
        v = conditions[k];
        if (data[k] !== v) {
          match = false;
          break;
        }
      }
      return match;
    };
    LocalStorage.prototype.before('read', 'create', 'update', 'destroy', LocalStorage.skipIfError(function(data, next) {
      var error;
      if (data.action === 'create') {
        data.id = data.record.get('id') || data.record.set('id', this.nextIdForRecord(data.record));
      } else {
        data.id = data.record.get('id');
      }
      if (data.id == null) {
        error = new this.constructor.StorageError("Couldn't get/set record primary key on " + data.action + "!");
      } else {
        data.key = this.storageKey(data.record) + data.id;
      }
      return next(error);
    }));
    LocalStorage.prototype.before('create', 'update', LocalStorage.skipIfError(function(data, next) {
      data.recordAttributes = JSON.stringify(data.record);
      return next();
    }));
    LocalStorage.prototype.after('read', LocalStorage.skipIfError(function(data, next) {
      var error, _ref;
      if (typeof data.recordAttributes === 'string') {
        _ref = this._jsonToAttributes(data.recordAttributes), error = _ref[0], data.recordAttributes = _ref[1];
        if (error != null) {
          return next(error);
        }
      }
      data.record.fromJSON(data.recordAttributes);
      return next();
    }));
    LocalStorage.prototype.after('read', 'create', 'update', 'destroy', LocalStorage.skipIfError(function(data, next) {
      data.result = data.record;
      return next();
    }));
    LocalStorage.prototype.after('readAll', LocalStorage.skipIfError(function(data, next) {
      var recordAttributes;
      data.result = data.records = (function() {
        var _i, _len, _ref, _results;
        _ref = data.recordsAttributes;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          recordAttributes = _ref[_i];
          _results.push(this.getRecordFromData(recordAttributes, data.proto.constructor));
        }
        return _results;
      }).call(this);
      return next();
    }));
    _ref = ['read', 'create', 'update', 'destroy'];
    _fn = __bind(function(key) {
      return this.prototype[key] = function(record, options, callback) {
        return this.runBeforeFilter(key, {
          record: record,
          options: options
        }, function(data) {
          data = this['_do' + key](data);
          return this.runAfterFilter(key, data, callback);
        });
      };
    }, LocalStorage);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      key = _ref[_i];
      _fn(key);
    }
    LocalStorage.prototype._doread = function(_arg) {
      var error, key, record, recordAttributes;
      error = _arg.error, record = _arg.record, key = _arg.key;
      if (error == null) {
        recordAttributes = this.storage.getItem(key);
        if (!recordAttributes) {
          error = new this.constructor.NotFoundError();
        }
      }
      return {
        recordAttributes: recordAttributes,
        record: record,
        error: error,
        key: key
      };
    };
    LocalStorage.prototype._docreate = function(_arg) {
      var error, key, record, recordAttributes;
      error = _arg.error, record = _arg.record, key = _arg.key, recordAttributes = _arg.recordAttributes;
      if (error == null) {
        if (this.storage.getItem(key)) {
          error = new this.constructor.RecordExistsError;
        } else {
          this.storage.setItem(key, recordAttributes);
        }
      }
      return {
        record: record,
        error: error
      };
    };
    LocalStorage.prototype._doupdate = function(_arg) {
      var error, key, record, recordAttributes;
      error = _arg.error, record = _arg.record, key = _arg.key, recordAttributes = _arg.recordAttributes;
      if (error == null) {
        this.storage.setItem(key, recordAttributes);
      }
      return {
        record: record,
        error: error
      };
    };
    LocalStorage.prototype._dodestroy = function(_arg) {
      var error, key, record, recordAttributes;
      error = _arg.error, record = _arg.record, key = _arg.key, recordAttributes = _arg.recordAttributes;
      if (error == null) {
        this.storage.removeItem(key);
      }
      return {
        record: record,
        error: error
      };
    };
    LocalStorage.prototype.readAll = function(proto, options, callback) {
      return this.runBeforeFilter('readAll', {
        proto: proto,
        options: options
      }, function(_arg) {
        var error, options, proto, recordsAttributes, _ref2;
        proto = _arg.proto, error = _arg.error, options = _arg.options;
        if (error == null) {
          _ref2 = this._storageEntriesMatching(proto, options), error = _ref2[0], recordsAttributes = _ref2[1];
        }
        return this.runAfterFilter('readAll', {
          error: error,
          recordsAttributes: recordsAttributes,
          proto: proto
        }, callback);
      });
    };
    return LocalStorage;
  }).call(this);
  Batman.SessionStorage = (function() {
    __extends(SessionStorage, Batman.LocalStorage);
    function SessionStorage() {
      if (typeof window.sessionStorage === 'undefined') {
        return null;
      }
      SessionStorage.__super__.constructor.apply(this, arguments);
      this.storage = sessionStorage;
    }
    return SessionStorage;
  })();
  Batman.RestStorage = (function() {
    var key, _fn, _i, _len, _ref;
    __extends(RestStorage, Batman.StorageAdapter);
    RestStorage.prototype.defaultOptions = {
      type: 'json'
    };
    RestStorage.prototype.serializeAsForm = true;
    function RestStorage() {
      RestStorage.__super__.constructor.apply(this, arguments);
      this.defaultOptions = $mixin({}, this.defaultOptions);
    }
    RestStorage.prototype.recordJsonNamespace = function(record) {
      return helpers.singularize(this.storageKey(record));
    };
    RestStorage.prototype.collectionJsonNamespace = function(proto) {
      return helpers.pluralize(this.storageKey(proto));
    };
    RestStorage.prototype._execWithOptions = function(object, key, options) {
      if (typeof object[key] === 'function') {
        return object[key](options);
      } else {
        return object[key];
      }
    };
    RestStorage.prototype._defaultCollectionUrl = function(record) {
      return "/" + (this.storageKey(record));
    };
    RestStorage.prototype.urlForRecord = function(record, data) {
      var error, id, url;
      if (record.url) {
        url = this._execWithOptions(record, 'url', data.options);
      } else {
        url = record.constructor.url ? this._execWithOptions(record.constructor, 'url', data.options) : this._defaultCollectionUrl(record);
        if (data.action !== 'create') {
          if ((id = record.get('id')) != null) {
            url = url + "/" + id;
          } else {
            error = new this.constructor.StorageError("Couldn't get/set record primary key on " + data.action + "!");
          }
        }
      }
      return [error, url];
    };
    RestStorage.prototype.urlForCollection = function(model, data) {
      var url;
      url = model.url ? this._execWithOptions(model, 'url', data.options) : this._defaultCollectionUrl(model.prototype, data.options);
      return [void 0, url];
    };
    RestStorage.prototype.request = function(options, callback) {
      options = $mixin(options, {
        success: __bind(function(data) {
          data = $mixin(options, {
            data: data,
            error: void 0
          });
          return this.runAfterFilter(options.action, data, callback);
        }, this),
        error: __bind(function(error) {
          var data, _ref;
          data = $mixin(options, {
            error: error,
            response: (_ref = error.request) != null ? _ref.get('response') : void 0
          });
          return this.runAfterFilter(options.action, data, callback);
        }, this)
      });
      return new Batman.Request(options);
    };
    RestStorage.prototype.before('all', RestStorage.skipIfError(function(data, next) {
      $mixin(data, this.defaultOptions);
      return next();
    }));
    RestStorage.prototype.before('create', 'read', 'update', 'destroy', RestStorage.skipIfError(function(data, next) {
      var error, _ref;
      _ref = this.urlForRecord(data.record, data), error = _ref[0], data.url = _ref[1];
      return next(error);
    }));
    RestStorage.prototype.before('readAll', RestStorage.skipIfError(function(data, next) {
      var error, _ref;
      _ref = this.urlForCollection(data.proto.constructor, data), error = _ref[0], data.url = _ref[1];
      return next(error);
    }));
    RestStorage.prototype.before('create', 'update', RestStorage.skipIfError(function(data, next) {
      var json, namespace;
      json = data.record.toJSON();
      if (namespace = this.recordJsonNamespace(data.record)) {
        data.data = {};
        data.data[namespace] = json;
      } else {
        data.data = json;
      }
      if (!this.serializeAsForm) {
        data.data = JSON.stringify(data.data);
      }
      return next();
    }));
    RestStorage.prototype.after('create', 'read', 'update', RestStorage.skipIfError(function(data, next) {
      var error, json, namespace, _ref;
      if (typeof data.data === 'string') {
        _ref = this._jsonToAttributes(data.data), error = _ref[0], json = _ref[1];
        if (error != null) {
          return next(error);
        }
      } else {
        json = data.data;
      }
      namespace = this.recordJsonNamespace(data.record);
      if (namespace && (json[namespace] != null)) {
        json = json[namespace];
      }
      data.record.fromJSON(json);
      data.result = data.record;
      return next();
    }));
    RestStorage.prototype.after('readAll', RestStorage.skipIfError(function(data, next) {
      var jsonRecordAttributes, namespace;
      if (typeof data.data === 'string') {
        try {
          data.data = JSON.parse(data.data);
        } catch (jsonError) {
          return next(jsonError);
        }
      }
      namespace = this.collectionJsonNamespace(data.proto);
      data.recordsAttributes = namespace && (data.data[namespace] != null) ? data.data[namespace] : data.data;
      data.result = data.records = (function() {
        var _i, _len, _ref, _results;
        _ref = data.recordsAttributes;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          jsonRecordAttributes = _ref[_i];
          _results.push(this.getRecordFromData(jsonRecordAttributes, data.proto.constructor));
        }
        return _results;
      }).call(this);
      return next();
    }));
    RestStorage.HTTPMethods = {
      create: 'POST',
      update: 'PUT',
      read: 'GET',
      readAll: 'GET',
      destroy: 'DELETE'
    };
    _ref = ['create', 'read', 'update', 'destroy'];
    _fn = __bind(function(key) {
      return this.prototype[key] = function(record, options, callback) {
        return this.runBeforeFilter(key, {
          record: record,
          options: options
        }, function(data) {
          data.method = this.constructor.HTTPMethods[key];
          return this.request(data, callback);
        });
      };
    }, RestStorage);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      key = _ref[_i];
      _fn(key);
    }
    RestStorage.prototype.readAll = function(proto, options, callback) {
      return this.runBeforeFilter('readAll', {
        proto: proto,
        options: options
      }, function(data) {
        data.method = this.constructor.HTTPMethods['readAll'];
        return this.request(data, callback);
      });
    };
    return RestStorage;
  }).call(this);
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
      },
      'final': true
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
      var node;
      View.__super__.constructor.apply(this, arguments);
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
          this.hasContainer = true;
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
      var _ref;
      this.event('ready').resetOneShot();
      if ((_ref = this._renderer) != null) {
        _ref.forgetAll();
      }
      if (node) {
        this._renderer = new Batman.Renderer(node, null, this.context);
        return this._renderer.on('rendered', __bind(function() {
          return this.fire('ready', node);
        }, this));
      }
    };
    return View;
  })();
  Batman.Renderer = (function() {
    var bindingRegexp, bindingSortOrder, bindingSortPositions, k, name, pos, _i, _len, _len2, _ref;
    __extends(Renderer, Batman.Object);
    Renderer.prototype.deferEvery = 50;
    function Renderer(node, callback, context) {
      this.node = node;
      this.resume = __bind(this.resume, this);
      this.start = __bind(this.start, this);
      Renderer.__super__.constructor.call(this);
      if (callback != null) {
        this.on('parsed', callback);
      }
      this.context = context instanceof Batman.RenderContext ? context : Batman.RenderContext.start(context);
      this.immediate = $setImmediate(this.start);
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
      this.prevent('stopped');
      this.fire('parsed');
      return this.fire('rendered');
    };
    Renderer.prototype.stop = function() {
      $clearImmediate(this.immediate);
      return this.fire('stopped');
    };
    Renderer.prototype.forgetAll = function() {};
    _ref = ['parsed', 'rendered', 'stopped'];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      k = _ref[_i];
      Renderer.prototype.event(k).oneShot = true;
    }
    bindingRegexp = /^data\-(.*)/;
    bindingSortOrder = ["renderif", "foreach", "formfor", "context", "bind"];
    bindingSortPositions = {};
    for (pos = 0, _len2 = bindingSortOrder.length; pos < _len2; pos++) {
      name = bindingSortOrder[pos];
      bindingSortPositions[name] = pos;
    }
    Renderer.prototype._sortBindings = function(a, b) {
      var aindex, bindex;
      aindex = bindingSortPositions[a[0]];
      bindex = bindingSortPositions[b[0]];
      if (aindex == null) {
        aindex = bindingSortOrder.length;
      }
      if (bindex == null) {
        bindex = bindingSortOrder.length;
      }
      if (aindex > bindex) {
        return 1;
      } else if (bindex > aindex) {
        return -1;
      } else if (a[0] > b[0]) {
        return 1;
      } else if (b[0] > a[0]) {
        return -1;
      } else {
        return 0;
      }
    };
    Renderer.prototype.parseNode = function(node) {
      var attr, bindings, key, nextNode, oldContext, readerArgs, result, skipChildren, varIndex, _base, _base2, _j, _len3, _name, _name2, _ref2;
      if (this.deferEvery && (new Date - this.startTime) > this.deferEvery) {
        this.resumeNode = node;
        this.timeout = $setImmediate(this.resume);
        return;
      }
      if (node.getAttribute && node.attributes) {
        bindings = (function() {
          var _j, _len3, _ref2, _ref3, _results;
          _ref2 = node.attributes;
          _results = [];
          for (_j = 0, _len3 = _ref2.length; _j < _len3; _j++) {
            attr = _ref2[_j];
            name = (_ref3 = attr.nodeName.match(bindingRegexp)) != null ? _ref3[1] : void 0;
            if (!name) {
              continue;
            }
            _results.push(~(varIndex = name.indexOf('-')) ? [name.substr(0, varIndex), name.substr(varIndex + 1), attr.value] : [name, attr.value]);
          }
          return _results;
        })();
        _ref2 = bindings.sort(this._sortBindings);
        for (_j = 0, _len3 = _ref2.length; _j < _len3; _j++) {
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
      $forgetParseExit(node);
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
        $forgetParseExit(nextParent);
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
    RenderContext.start = function(context) {
      var node;
      this.windowWrapper || (this.windowWrapper = {
        window: Batman.container
      });
      node = new this(this.windowWrapper);
      if (Batman.currentApp) {
        node = node.descend(Batman.currentApp);
      }
      if (context) {
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
      this.windowWrapper || (this.windowWrapper = {
        window: Batman.container
      });
      return [$get(this.windowWrapper, key), this.windowWrapper];
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
        var action, app, dispatcher, isHash, model, name, url, _, _ref, _ref2, _ref3;
        if (key.substr(0, 1) === '/') {
          url = key;
        } else {
          isHash = key.indexOf('#') > 1;
          _ref = isHash ? key.split('#') : key.split('/'), key = _ref[0], action = _ref[1];
          _ref2 = context.findKey('dispatcher'), dispatcher = _ref2[0], app = _ref2[1];
          if (!isHash) {
            _ref3 = context.findKey(key), model = _ref3[0], _ = _ref3[1];
          }
          if (model instanceof Batman.AssociationProxy) {
            model = model.get('target');
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
      view: function(node, key, context, renderer) {
        var view, viewClass;
        renderer.prevent('rendered');
        node.removeAttribute("data-view");
        viewClass = context.findKey(key)[0];
        view = new viewClass({
          node: node,
          context: context
        });
        view.on('ready', function() {
          return renderer.allowAndFire('rendered');
        });
        return false;
      },
      partial: function(node, path, context, renderer) {
        Batman.DOM.partial(node, path, context, renderer);
        return true;
      },
      defineview: function(node, name, context, renderer) {
        $onParseExit(node, function() {
          return $removeNode(node);
        });
        Batman.View.sourceCache.set(Batman.Navigator.normalizePath(Batman.View.prototype.prefix, name), node.innerHTML);
        return false;
      },
      renderif: function(node, key, context, renderer) {
        new Batman.DOM.DeferredRenderingBinding(node, key, context, renderer);
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
        _replaceContent = !Batman._data(node, 'yielded');
      }
      Batman.DOM._yields[name] = node;
      if (contents = Batman.DOM._yieldContents[name]) {
        if (_replaceContent) {
          $setInnerHTML(node, '', true);
        }
        for (_i = 0, _len = contents.length; _i < _len; _i++) {
          content = contents[_i];
          if (!Batman._data(content, 'yielded')) {
            if ($isChildOf(node, content)) {
              content = content.cloneNode(true);
            }
            $appendChild(node, content, true);
            Batman._data(content, 'yielded', true);
          }
        }
        delete Batman.DOM._yieldContents[name];
        return Batman._data(node, 'yielded', true);
      }
    },
    contentFor: function(name, node, _replaceContent) {
      var contents, yieldingNode;
      yieldingNode = Batman.DOM._yields[name];
      if (yieldingNode && $isChildOf(yieldingNode, node)) {
        node = node.cloneNode(true);
      }
      if (contents = Batman.DOM._yieldContents[name]) {
        contents.push(node);
      } else {
        Batman.DOM._yieldContents[name] = [node];
      }
      if (yieldingNode) {
        return Batman.DOM.yield(name, yieldingNode, _replaceContent);
      }
    },
    replace: function(name, node) {
      return Batman.DOM.contentFor(name, node, true);
    },
    partial: function(container, path, context, renderer) {
      var view;
      renderer.prevent('rendered');
      view = new Batman.View({
        source: path,
        context: context
      });
      return view.on('ready', function() {
        var child, children, node, _i, _len;
        $setInnerHTML(container, '');
        children = (function() {
          var _i, _len, _ref, _results;
          _ref = view.get('node').childNodes;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            node = _ref[_i];
            _results.push(node);
          }
          return _results;
        })();
        for (_i = 0, _len = children.length; _i < _len; _i++) {
          child = children[_i];
          $appendChild(container, child);
        }
        return renderer.allowAndFire('rendered');
      });
    },
    trackBinding: $trackBinding = function(binding, node) {
      var bindings;
      if (bindings = Batman._data(node, 'bindings')) {
        return bindings.add(binding);
      } else {
        return Batman._data(node, 'bindings', new Batman.SimpleSet(binding));
      }
    },
    unbindNode: $unbindNode = function(node) {
      var bindings, eventListeners, eventName, listeners;
      if (bindings = Batman._data(node, 'bindings')) {
        bindings.forEach(function(binding) {
          return binding.destroy();
        });
      }
      if (listeners = Batman._data(node, 'listeners')) {
        for (eventName in listeners) {
          eventListeners = listeners[eventName];
          eventListeners.forEach(function(listener) {
            return $removeEventListener(node, eventName, listener);
          });
        }
      }
      Batman.removeData(node);
      return Batman.removeData(node, void 0, true);
    },
    unbindTree: $unbindTree = function(node, unbindRoot) {
      var child, _i, _len, _ref, _results;
      if (unbindRoot == null) {
        unbindRoot = true;
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
    setStyleProperty: $setStyleProperty = function(node, property, value, importance) {
      if (node.style.setAttribute) {
        return node.style.setAttribute(property, value, importance);
      } else {
        return node.style.setProperty(property, value, importance);
      }
    },
    removeNode: $removeNode = function(node) {
      var _ref;
      if ((_ref = node.parentNode) != null) {
        _ref.removeChild(node);
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
    insertBefore: $insertBefore = function(parentNode, newNode, referenceNode) {
      if (referenceNode == null) {
        referenceNode = null;
      }
      if (!referenceNode || parentNode.childNodes.length <= 0) {
        return $appendChild(parentNode, newNode);
      } else {
        return parentNode.insertBefore(newNode, referenceNode);
      }
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
      if (!(listeners = Batman._data(node, 'listeners'))) {
        listeners = Batman._data(node, 'listeners', {});
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
      if (listeners = Batman._data(node, 'listeners')) {
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
      set = Batman._data(node, 'onParseExit') || Batman._data(node, 'onParseExit', new Batman.SimpleSet);
      if (callback != null) {
        set.add(callback);
      }
      return set;
    },
    forgetParseExit: $forgetParseExit = function(node, callback) {
      return Batman.removeData(node, 'onParseExit', true);
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
    AbstractBinding.accessor('filteredValue', {
      get: function() {
        var result, self, unfilteredValue;
        unfilteredValue = this.get('unfilteredValue');
        self = this;
        if (this.filterFunctions.length > 0) {
          developer.currentFilterStack = this.renderContext;
          result = this.filterFunctions.reduce(function(value, fn, i) {
            var args;
            args = self.filterArguments[i].map(function(argument) {
              if (argument._keypath) {
                return self.renderContext.findKey(argument._keypath)[0];
              } else {
                return argument;
              }
            });
            args.unshift(value);
            args = args.map(deProxy);
            return fn.apply(self.renderContext, args);
          }, unfilteredValue);
          developer.currentFilterStack = null;
          return result;
        } else {
          return deProxy(unfilteredValue);
        }
      },
      set: function(_, newValue) {
        return this.set('unfilteredValue', newValue);
      }
    });
    AbstractBinding.accessor('unfilteredValue', {
      get: function() {
        var k;
        if (k = this.get('key')) {
          return this.get("keyContext." + k);
        } else {
          return this.get('value');
        }
      },
      set: function(_, value) {
        var k, keyContext;
        if (k = this.get('key')) {
          keyContext = this.get('keyContext');
          if (keyContext !== Batman.container) {
            return this.set("keyContext." + k, value);
          }
        } else {
          return this.set('value', value);
        }
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
        return property.die();
      }) : void 0;
    };
    AbstractBinding.prototype.parseFilter = function() {
      var args, filter, filterName, filterString, filters, key, keyPath, orig, split, _results;
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
        _results = [];
        while (filterString = filters.shift()) {
          split = filterString.indexOf(' ');
          if (~split) {
            filterName = filterString.substr(0, split);
            args = filterString.substr(split);
          } else {
            filterName = filterString;
          }
          _results.push((function() {
            if (filter = Batman.Filters[filterName]) {
              this.filterFunctions.push(filter);
              if (args) {
                try {
                  return this.filterArguments.push(this.parseSegment(args));
                } catch (e) {
                  return developer.error("Bad filter arguments \"" + args + "\"!");
                }
              } else {
                return this.filterArguments.push([]);
              }
            } else {
              return developer.error("Unrecognized filter '" + filterName + "' in key \"" + this.keyPath + "\"!");
            }
          }).call(this));
        }
        return _results;
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
        return this.set('filteredValue', this.node.value);
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
      return this.set('filteredValue', Batman.DOM.attrReaders._parseAttribute(node.getAttribute(this.attributeName)));
    };
    return AttributeBinding;
  })();
  Batman.DOM.NodeAttributeBinding = (function() {
    __extends(NodeAttributeBinding, Batman.DOM.AbstractAttributeBinding);
    function NodeAttributeBinding() {
      NodeAttributeBinding.__super__.constructor.apply(this, arguments);
    }
    NodeAttributeBinding.prototype.dataChange = function(value) {
      if (value == null) {
        value = "";
      }
      return this.node[this.attributeName] = value;
    };
    NodeAttributeBinding.prototype.nodeChange = function(node) {
      return this.set('filteredValue', Batman.DOM.attrReaders._parseAttribute(node[this.attributeName]));
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
          return $setStyleProperty(this.node, 'display', 'none', 'important');
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
      return typeof (_base = Batman._data(this.node.parentNode, 'updateBinding')) === "function" ? _base() : void 0;
    };
    function CheckedBinding() {
      CheckedBinding.__super__.constructor.apply(this, arguments);
      Batman._data(this.node, this.attributeName, this);
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
  Batman.DOM.DeferredRenderingBinding = (function() {
    __extends(DeferredRenderingBinding, Batman.DOM.AbstractBinding);
    DeferredRenderingBinding.prototype.rendered = false;
    function DeferredRenderingBinding() {
      DeferredRenderingBinding.__super__.constructor.apply(this, arguments);
      this.node.removeAttribute("data-renderif");
    }
    DeferredRenderingBinding.prototype.nodeChange = function() {};
    DeferredRenderingBinding.prototype.dataChange = function(value) {
      if (value && !this.rendered) {
        return this.render();
      }
    };
    DeferredRenderingBinding.prototype.render = function() {
      new Batman.Renderer(this.node, null, this.renderContext);
      return this.rendered = true;
    };
    return DeferredRenderingBinding;
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
        return this.set('filteredValue', this.node.value);
      }
    };
    RadioBinding.prototype.nodeChange = function(node) {
      return this.set('filteredValue', Batman.DOM.attrReaders._parseAttribute(node.value));
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
        return this.set('filteredValue', Array.prototype.slice.call(node.files));
      } else {
        return this.set('filteredValue', node.value);
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
    SelectBinding.prototype.firstBind = true;
    function SelectBinding() {
      this.updateOptionBindings = __bind(this.updateOptionBindings, this);
      this.updateSelectBinding = __bind(this.updateSelectBinding, this);
      this.nodeChange = __bind(this.nodeChange, this);
      this.dataChange = __bind(this.dataChange, this);      SelectBinding.__super__.constructor.apply(this, arguments);
      this.renderer.on('rendered', __bind(function() {
        if (this.node != null) {
          Batman._data(this.node, 'updateBinding', this.updateSelectBinding);
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
        if (typeof newValue === 'undefined' && this.firstBind) {
          this.firstBind = false;
          this.set('unfilteredValue', this.node.value);
        } else {
          Batman.DOM.valueForNode(this.node, newValue);
        }
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
      this.set('unfilteredValue', selections);
      return true;
    };
    SelectBinding.prototype.updateOptionBindings = function() {
      var child, selectedBinding, _i, _len, _ref;
      _ref = this.node.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        child = _ref[_i];
        if (selectedBinding = Batman._data(child, 'selected')) {
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
      var colonSplitCSSValues, cssName, key, keyValue, keypathContext, keypathValue, style, _i, _len, _ref, _ref2, _ref3, _results;
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
          _ref2 = style.split(":"), cssName = _ref2[0], colonSplitCSSValues = 2 <= _ref2.length ? __slice.call(_ref2, 1) : [];
          this.setStyle(cssName, colonSplitCSSValues.join(":"));
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
      this.setStyle(newKey, this.collection.get(newKey));
    };
    StyleBinding.prototype.handleItemsWereRemoved = function(oldKey) {
      this.setStyle(oldKey, '');
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
    function IteratorBinding(sourceNode, iteratorName, key, context, parentRenderer) {
      var previousSiblingNode;
      this.iteratorName = iteratorName;
      this.key = key;
      this.context = context;
      this.parentRenderer = parentRenderer;
      this.handleArrayChanged = __bind(this.handleArrayChanged, this);
      this.handleItemsWereRemoved = __bind(this.handleItemsWereRemoved, this);
      this.handleItemsWereAdded = __bind(this.handleItemsWereAdded, this);
      this.nodeMap = new Batman.SimpleHash;
      this.actionMap = new Batman.SimpleHash;
      this.rendererMap = new Batman.SimpleHash;
      this.actions = [];
      this.prototypeNode = sourceNode.cloneNode(true);
      this.prototypeNode.removeAttribute("data-foreach-" + this.iteratorName);
      this.parentNode = sourceNode.parentNode;
      previousSiblingNode = sourceNode.nextSibling;
      this.siblingNode = document.createComment("end " + this.iteratorName);
      this.siblingNode[Batman.expando] = sourceNode[Batman.expando];
      if (Batman.canDeleteExpando) {
        delete sourceNode[Batman.expando];
      }
      $insertBefore(this.parentNode, this.siblingNode, previousSiblingNode);
      this.parentRenderer.on('parsed', __bind(function() {
        $removeNode(sourceNode);
        return this.bind();
      }, this));
      this.parentRenderer.prevent('rendered');
      IteratorBinding.__super__.constructor.call(this, this.siblingNode, this.iteratorName, this.key, this.context, this.parentRenderer);
      this.fragment = document.createDocumentFragment();
    }
    IteratorBinding.prototype.destroy = function() {
      IteratorBinding.__super__.destroy.apply(this, arguments);
      return this.destroyed = true;
    };
    IteratorBinding.prototype.unbindCollection = function() {
      if (this.collection) {
        this.nodeMap.forEach(__bind(function(item) {
          return this.cancelExistingItem(item);
        }, this));
        return IteratorBinding.__super__.unbindCollection.apply(this, arguments);
      }
    };
    IteratorBinding.prototype.dataChange = function(newCollection) {
      var key, value, _ref;
      if (this.collection !== newCollection) {
        this.removeAll();
      }
      this.bindCollection(newCollection);
      if (this.collection) {
        if (this.collection.toArray) {
          this.handleArrayChanged();
        } else if (this.collection.forEach) {
          this.collection.forEach(__bind(function(item) {
            return this.addOrInsertItem(item);
          }, this));
        } else {
          _ref = this.collection;
          for (key in _ref) {
            if (!__hasProp.call(_ref, key)) continue;
            value = _ref[key];
            this.addOrInsertItem(key);
          }
        }
      } else {
        developer.warn("Warning! data-foreach-" + this.iteratorName + " called with an undefined binding. Key was: " + this.key + ".");
      }
      return this.processActionQueue();
    };
    IteratorBinding.prototype.handleItemsWereAdded = function() {
      var item, items, _i, _len;
      items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        this.addOrInsertItem(item, {
          fragment: false
        });
      }
    };
    IteratorBinding.prototype.handleItemsWereRemoved = function() {
      var item, items, _i, _len;
      items = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        item = items[_i];
        this.removeItem(item);
      }
    };
    IteratorBinding.prototype.handleArrayChanged = function() {
      var item, newItemsInOrder, nodesToRemove, _i, _len;
      newItemsInOrder = this.collection.toArray();
      nodesToRemove = (new Batman.SimpleHash).merge(this.nodeMap);
      for (_i = 0, _len = newItemsInOrder.length; _i < _len; _i++) {
        item = newItemsInOrder[_i];
        this.addOrInsertItem(item, {
          fragment: false
        });
        nodesToRemove.unset(item);
      }
      return nodesToRemove.forEach(__bind(function(item, node) {
        return this.removeItem(item);
      }, this));
    };
    IteratorBinding.prototype.addOrInsertItem = function(item, options) {
      var existingNode;
      if (options == null) {
        options = {};
      }
      existingNode = this.nodeMap.get(item);
      if (existingNode) {
        return this.insertItem(item, existingNode, $mixin(options, {
          actionNumber: this.queuedActionNumber++
        }));
      } else {
        return this.addItem(item, options);
      }
    };
    IteratorBinding.prototype.addItem = function(item, options) {
      var childRenderer, finish, self;
      if (options == null) {
        options = {
          fragment: true
        };
      }
      this.parentRenderer.prevent('rendered');
      if (this.actionMap.get(item) != null) {
        this.cancelExistingItemActions(item);
      }
      self = this;
      options.actionNumber = this.queuedActionNumber++;
      childRenderer = new Batman.Renderer(this._nodeForItem(item), (function() {
        self.rendererMap.unset(item);
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
        this.actions[options.actionNumber] = false;
        finish();
        return this.processActionQueue();
      }, this));
      return item;
    };
    IteratorBinding.prototype.removeItem = function(item) {
      var hideFunction, oldNode;
      if (this.destroyed || !(item != null)) {
        return;
      }
      oldNode = this.nodeMap.unset(item);
      this.cancelExistingItem(item);
      if (oldNode) {
        if (hideFunction = Batman.data(oldNode, 'hide')) {
          return hideFunction.call(oldNode);
        } else {
          return $removeNode(oldNode);
        }
      }
    };
    IteratorBinding.prototype.removeAll = function() {
      return this.nodeMap.forEach(__bind(function(item) {
        return this.removeItem(item);
      }, this));
    };
    IteratorBinding.prototype.insertItem = function(item, node, options) {
      var existingActionNumber;
      if (options == null) {
        options = {};
      }
      if (this.destroyed) {
        return;
      }
      existingActionNumber = this.actionMap.get(item);
      if (existingActionNumber > options.actionNumber) {
        this.actions[options.actionNumber] = function() {};
      } else {
        if (existingActionNumber) {
          this.cancelExistingItemActions(item);
        }
        this.actionMap.set(item, options.actionNumber);
        this.actions[options.actionNumber] = function() {
          var show;
          show = Batman.data(node, 'show');
          if (typeof show === 'function') {
            return show.call(node, {
              before: this.siblingNode
            });
          } else {
            if (options.fragment) {
              return this.fragment.appendChild(node);
            } else {
              return $insertBefore(this.parentNode, node, this.siblingNode);
            }
          }
        };
        this.actions[options.actionNumber].item = item;
      }
      return this.processActionQueue();
    };
    IteratorBinding.prototype.cancelExistingItem = function(item) {
      this.cancelExistingItemActions(item);
      return this.cancelExistingItemRender(item);
    };
    IteratorBinding.prototype.cancelExistingItemActions = function(item) {
      var oldActionNumber;
      oldActionNumber = this.actionMap.get(item);
      if ((oldActionNumber != null) && oldActionNumber >= this.currentActionNumber) {
        this.actions[oldActionNumber] = false;
      }
      return this.actionMap.unset(item);
    };
    IteratorBinding.prototype.cancelExistingItemRender = function(item) {
      var oldRenderer;
      oldRenderer = this.rendererMap.get(item);
      if (oldRenderer) {
        oldRenderer.stop();
        $removeNode(oldRenderer.node);
      }
      return this.rendererMap.unset(item);
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
          while ((f = this.actions[this.currentActionNumber]) != null) {
            delete this.actions[this.currentActionNumber];
            this.actionMap.unset(f.item);
            if (f) {
              f.call(this);
            }
            this.currentActionNumber++;
            if (this.deferEvery && (new Date - startTime) > this.deferEvery) {
              return this.processActionQueue();
            }
          }
          if (this.fragment && this.rendererMap.length === 0 && this.fragment.hasChildNodes()) {
            $insertBefore(this.parentNode, this.fragment, this.siblingNode);
            this.fragment = document.createDocumentFragment();
          }
          if (this.currentActionNumber === this.queuedActionNumber) {
            return this.parentRenderer.allowAndFire('rendered');
          }
        }, this));
      }
    };
    IteratorBinding.prototype._nodeForItem = function(item) {
      var newNode;
      newNode = this.prototypeNode.cloneNode(true);
      this.nodeMap.set(item, newNode);
      return newNode;
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
    has: function(set, item) {
      if (set == null) {
        return false;
      }
      return Batman.contains(set, item);
    },
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
      var cache, getByName, id, internalKey, ret, thisCache;
      if (!Batman.acceptData(elem)) {
        return;
      }
      internalKey = Batman.expando;
      getByName = typeof name === "string";
      cache = Batman.cache;
      id = elem[Batman.expando];
      if ((!id || (pvt && id && (cache[id] && !cache[id][internalKey]))) && getByName && data === void 0) {
        return;
      }
      if (!id) {
        if (elem.nodeType !== 3) {
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
        thisCache[internalKey] || (thisCache[internalKey] = {});
        thisCache = thisCache[internalKey];
      }
      if (data !== void 0) {
        thisCache[name] = data;
      }
      if (getByName) {
        ret = thisCache[name];
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
      cache = Batman.cache;
      id = elem[Batman.expando];
      if (!cache[id]) {
        return;
      }
      if (name) {
        thisCache = pvt ? cache[id][internalKey] : cache[id];
        if (thisCache) {
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
      } else {
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
  Batman.container = typeof exports !== "undefined" && exports !== null ? (module.exports = Batman, global) : (window.Batman = Batman, window);
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
    return Batman.exportHelpers(Batman.container);
  };
}).call(this);

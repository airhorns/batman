(function() {
  
/*!
  * Reqwest! A x-browser general purpose XHR connection manager
  * copyright Dustin Diaz 2011
  * https://github.com/ded/reqwest
  * license MIT
  */
!function(context){function reqwest(a,b){return new Reqwest(a,b)}function init(o,fn){function error(a){o.error&&o.error(a),complete(a)}function success(resp){o.timeout&&clearTimeout(self.timeout)&&(self.timeout=null);var r=resp.responseText;switch(type){case"json":resp=eval("("+r+")");break;case"js":resp=eval(r);break;case"html":resp=r}fn(resp),o.success&&o.success(resp),complete(resp)}function complete(a){o.complete&&o.complete(a)}this.url=typeof o=="string"?o:o.url,this.timeout=null;var type=o.type||setType(this.url),self=this;fn=fn||function(){},o.timeout&&(this.timeout=setTimeout(function(){self.abort(),error()},o.timeout)),this.request=getRequest(o,success,error)}function setType(a){if(/\.json$/.test(a))return"json";if(/\.js$/.test(a))return"js";if(/\.html?$/.test(a))return"html";if(/\.xml$/.test(a))return"xml";return"js"}function Reqwest(a,b){this.o=a,this.fn=b,init.apply(this,arguments)}function getRequest(a,b,c){var d=xhr();d.open(a.method||"GET",typeof a=="string"?a:a.url,!0),setHeaders(d,a),d.onreadystatechange=readyState(d,b,c),a.before&&a.before(d),d.send(a.data||null);return d}function setHeaders(a,b){var c=b.headers||{};c.Accept="text/javascript, text/html, application/xml, text/xml, */*";if(b.data){c["Content-type"]="application/x-www-form-urlencoded";for(var d in c)c.hasOwnProperty(d)&&a.setRequestHeader(d,c[d],!1)}}function readyState(a,b,c){return function(){a&&a.readyState==4&&(twoHundo.test(a.status)?b(a):c(a))}}var twoHundo=/^20\d$/,xhr="XMLHttpRequest"in window?function(){return new XMLHttpRequest}:function(){return new ActiveXObject("Microsoft.XMLHTTP")};Reqwest.prototype={abort:function(){this.request.abort()},retry:function(){init.call(this,this.o,this.fn)}};var old=context.reqwest;reqwest.noConflict=function(){context.reqwest=old;return this},context.reqwest=reqwest}(this)
;
  /*
  Batman
  */  var $bind, $event, Batman, camelize_rx, escapeRegExp, global, helpers, namedOrSplat, namedParam, splatParam, toString, underscore_rx1, underscore_rx2;
  var __slice = Array.prototype.slice, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  $bind = function(me, f) {
    return function() {
      return f.apply(me, arguments);
    };
  };
  Batman = function() {
    var objects;
    objects = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    return (function(func, args, ctor) {
      ctor.prototype = func.prototype;
      var child = new ctor, result = func.apply(child, args);
      return typeof result === "object" ? result : child;
    })(Batman.Object, objects, function() {});
  };
  toString = Object.prototype.toString;
  Batman.typeOf = function(obj) {
    return toString.call(obj).slice(8, -1);
  };
  Batman.mixin = function() {
    var key, object, objects, set, to, value, _i, _len;
    to = arguments[0], objects = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    set = to.set ? $bind(to, to.set) : null;
    for (_i = 0, _len = objects.length; _i < _len; _i++) {
      object = objects[_i];
      if (Batman.typeOf(object) !== 'Object') {
        continue;
      }
      for (key in object) {
        value = object[key];
        if (set) {
          set(key, value);
        } else {
          to[key] = value;
        }
      }
      if (typeof object.initialize === 'function') {
        object.initialize.call(to);
      }
    }
    return to;
  };
  Batman.unmixin = function() {
    var from, key, object, objects, _i, _len;
    from = arguments[0], objects = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    for (_i = 0, _len = objects.length; _i < _len; _i++) {
      object = objects[_i];
      for (key in object) {
        from[key] = null;
        delete from[key];
      }
    }
    return from;
  };
  $event = Batman.event = function(original) {
    var f;
    f = function(handler) {
      var observer, observers, result, _i, _len;
      observers = f._observers;
      if (Batman.typeOf(handler) === 'Function') {
        if (observers.indexOf(handler) === -1) {
          observers.push(handler);
        }
        return this;
      } else {
        result = original.apply(this, arguments);
        if (result === false) {
          return false;
        }
        for (_i = 0, _len = observers.length; _i < _len; _i++) {
          observer = observers[_i];
          observer.apply(this, arguments);
        }
        return result;
      }
    };
    f.isEvent = true;
    f.action = original;
    f._observers = [];
    return f;
  };
  $event.oneShot = $event;
  Batman.Observable = {
    initialize: function() {
      return this._observers = {};
    },
    get: function(key) {
      var index, next, nextKey, results, thisKey, value;
      if (arguments.length > 1) {
        results = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = arguments.length; _i < _len; _i++) {
            thisKey = arguments[_i];
            _results.push(this.get(thisKey));
          }
          return _results;
        }).apply(this, arguments);
        return results;
      }
      index = key.indexOf('.');
      if (index !== -1) {
        next = this.get(key.substr(0, index));
        nextKey = key.substr(index + 1);
        if (next && next.get) {
          return next.get(key.substr(index + 1));
        } else {
          return this.methodMissing(key.substr(0, key.indexOf('.', index + 1)));
        }
      }
      value = this[key];
      if (typeof value === 'undefined') {
        return this.methodMissing(key);
      } else if (typeof value === 'function') {
        return value.call(this);
      } else {
        return value;
      }
    },
    set: function(key, value) {
      var index, next, oldValue, results, thisKey, thisValue;
      if (arguments.length > 2) {
        results = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = arguments.length; _i < _len; _i++) {
            thisKey = arguments[_i];
            thisValue = arguments[++_i];
            _results.push(this.set(thisKey, thisValue));
          }
          return _results;
        }).apply(this, arguments);
        return results;
      }
      index = key.indexOf('.');
      if (index !== -1) {
        next = this.get(key.substr(0, index));
        if (next && next.set) {
          return next.set(key.substr(index + 1), value);
        } else {
          return this.methodMissing(key.substr(0, key.indexOf('.', index + 1)));
        }
      }
      oldValue = this[key];
      if (oldValue !== value) {
        this.fire("" + key + ":before", value, oldValue);
        if (typeof oldValue === 'undefined') {
          this.methodMissing(key, value);
        } else if (typeof oldValue === 'function') {
          oldValue.call(this, value);
        } else {
          this[key] = value;
        }
        this.fire(key, value, oldValue);
      }
      return value;
    },
    observe: function(key, fireImmediately, callback) {
      var array, index, recursiveObserver, thisKey, thisObject, _base, _i, _len, _ref;
      if (typeof fireImmediately === 'function') {
        callback = fireImmediately;
        fireImmediately = false;
      }
      index = key.indexOf('.');
      if (index === -1) {
        array = (_base = this._observers)[key] || (_base[key] = []);
        array.push(callback);
      } else {
        thisObject = this;
        callback._recursiveObserver = recursiveObserver = __bind(function() {
          this.forget(key, callback);
          return this.observe(key, true, callback);
        }, this);
        _ref = key.split('.');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          thisKey = _ref[_i];
          if (!thisObject || !thisObject.observe) {
            break;
          }
          thisObject.observe(thisKey, recursiveObserver);
          thisObject = thisObject.get(thisKey);
        }
      }
      if (fireImmediately) {
        callback(this.get(key));
      }
      return this;
    },
    forget: function(key, callback) {
      var array, index, recursiveObserver, thisKey, thisObject, _i, _len, _ref;
      index = key.indexOf('.');
      if (index === -1) {
        array = this._observers[key];
        array.splice(array.indexOf(callback), 1);
      } else {
        thisObject = this;
        recursiveObserver = callback._recursiveObserver;
        _ref = key.split('.');
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          thisKey = _ref[_i];
          if (!thisObject || !thisObject.forget) {
            break;
          }
          thisObject.forget(thisKey, recursiveObserver);
          thisObject = thisObject.get(thisKey);
        }
      }
      return this;
    },
    fire: function(key, value, oldValue) {
      var callback, observers, _i, _len;
      observers = this._observers[key];
      if (observers) {
        for (_i = 0, _len = observers.length; _i < _len; _i++) {
          callback = observers[_i];
          callback.call(this, value, oldValue);
        }
      }
      return this;
    },
    methodMissing: function(key, value) {
      if (arguments.length > 1) {
        this[key] = value;
      }
      return this[key];
    }
  };
  Batman.Object = (function() {
    Object.property = function(defaultValue) {
      var f;
      f = function(value) {
        if (arguments.length) {
          f.value = value;
        }
        return f.value;
      };
      f.isProperty = true;
      f._observers = [];
      f.observe = function(observer) {
        var observers;
        observers = f._observers;
        if (observers.indexOf(observer) === -1) {
          observers.push(observer);
        }
        return f;
      };
      return f;
    };
    Object.global = function(isGlobal) {
      if (isGlobal === false) {
        return;
      }
      return global[this.name] = this;
    };
    function Object() {
      var key, observer, observers, properties, value, _i, _len;
      properties = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      Batman.Observable.initialize.call(this);
      for (key in this) {
        value = this[key];
        if (value && value.isProperty) {
          observers = value._observers;
          for (_i = 0, _len = observers.length; _i < _len; _i++) {
            observer = observers[_i];
            this.observe(key, observer);
          }
        } else if (value && value.isEvent) {
          this[key] = $event(value.action);
        }
      }
      Batman.mixin.apply(Batman, [this].concat(__slice.call(properties)));
    }
    Batman.mixin(Object.prototype, Batman.Observable);
    return Object;
  })();
  Batman.property = function(orig) {
    return orig;
  };
  Batman.DataStore = (function() {
    function DataStore() {
      DataStore.__super__.constructor.apply(this, arguments);
      this._data = {};
    }
    __extends(DataStore, Batman.Object);
    DataStore.prototype.query = function(conditions, options) {
      var id, key, limit, match, numResults, record, results, value, _ref;
      conditions || (conditions = {});
      options || (options = {});
      limit = options.limit;
      results = {};
      numResults = 0;
      _ref = this._data;
      for (id in _ref) {
        record = _ref[id];
        match = true;
        for (key in conditions) {
          value = conditions[key];
          if (record[key] !== value) {
            match = false;
            break;
          }
        }
        if (match) {
          results[id] = record;
          numResults++;
          if (limit && numResults >= limit) {
            return results;
          }
        }
      }
      return results;
    };
    DataStore.prototype.methodMissing = function(key, value) {
      if (arguments.length > 1) {
        this._data[key] = value;
      }
      return this._data[key];
    };
    return DataStore;
  })();
  namedParam = /:([\w\d]+)/g;
  splatParam = /\*([\w\d]+)/g;
  namedOrSplat = /[:|\*]([\w\d]+)/g;
  escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g;
  Batman.App = (function() {
    App.match = function(url, action) {
      var array, match, namedArguments, regexp, routes;
      routes = this.prototype._routes || (this.prototype._routes = []);
      match = url.replace(escapeRegExp, '\\$&');
      regexp = new RegExp('^' + match.replace(namedParam, '([^\/]*)').replace(splatParam, '(.*?)') + '$');
      namedArguments = [];
      while ((array = namedOrSplat.exec(match)) != null) {
        if (array[1]) {
          namedArguments.push(array[1]);
        }
      }
      return routes.push({
        match: match,
        regexp: regexp,
        namedArguments: namedArguments,
        action: action
      });
    };
    __extends(App, Batman.Object);
    App.root = function(action) {
      return this.match('/', action);
    };
    App.global = function(isGlobal) {
      var instance;
      if (isGlobal === false) {
        return;
      }
      Batman.Object.global.apply(this, arguments);
      instance = new this;
      this.sharedApp = instance;
      return global.BATMAN_APP = instance;
    };
    function App() {
      var layout, _ref;
      App.__super__.constructor.apply(this, arguments);
      this.dataStore = new Batman.DataStore;
      if ((_ref = this._routes) != null ? _ref.length : void 0) {
        this.startRouting();
      }
      layout = __bind(function() {
        return new Batman.View({
          context: global,
          node: document.body
        });
      }, this);
      setTimeout(layout, 0);
    }
    App.prototype.startRouting = function() {
      var parseUrl;
      if (typeof window === 'undefined') {
        return;
      }
      parseUrl = __bind(function() {
        var hash;
        hash = window.location.hash.replace(this.routePrefix, '');
        if (hash === this._cachedRoute) {
          return;
        }
        this._cachedRoute = hash;
        return this.dispatch(hash);
      }, this);
      if (!window.location.hash) {
        window.location.hash = this.routePrefix + '/';
      }
      setTimeout(parseUrl, 0);
      if ('onhashchange' in window) {
        this._routeHandler = parseUrl;
        return window.addEventListener('hashchange', parseUrl);
      } else {
        return this._routeHandler = setInterval(parseUrl, 100);
      }
    };
    App.prototype.stopRouting = function() {
      if ('onhashchange' in window) {
        window.removeEventListener('hashchange', this._routeHandler);
        return this._routeHandler = null;
      } else {
        return this._routeHandler = clearInterval(this._routeHandler);
      }
    };
    App.prototype.match = function(url, action) {
      return Batman.App.match.apply(this.constructor, arguments);
    };
    App.prototype.routePrefix = '#!';
    App.prototype.redirect = function(url) {
      window.location.hash = this._cachedRoute = this.routePrefix + url;
      return this.dispatch(url);
    };
    App.prototype.dispatch = function(url) {
      var action, actionName, components, controller, controllerName, params, route;
      route = this._matchRoute(url);
      if (!route) {
        if (url !== '/404') {
          this.redirect('/404');
        }
        return;
      }
      params = this._extractParams(url, route);
      action = route.action;
      if (!action) {
        return;
      }
      if (Batman.typeOf(action) === 'String') {
        components = action.split('.');
        controllerName = helpers.camelize(components[0] + 'Controller');
        actionName = helpers.camelize(components[1], true);
        controller = this.controller(controllerName);
        return controller[actionName](params);
      }
    };
    App.prototype._matchRoute = function(url) {
      var route, routes, _i, _len;
      routes = this._routes;
      for (_i = 0, _len = routes.length; _i < _len; _i++) {
        route = routes[_i];
        if (route.regexp.test(url)) {
          return route;
        }
      }
      return null;
    };
    App.prototype._extractParams = function(url, route) {
      var array, param, params, _i, _len;
      array = route.regexp.exec(url).slice(1);
      params = {
        url: url
      };
      for (_i = 0, _len = array.length; _i < _len; _i++) {
        param = array[_i];
        params[route.namedArguments[_i]] = param;
      }
      return params;
    };
    App.prototype.controller = function(className) {
      var controller, controllerClass, controllers;
      controllers = this._controllers || (this._controllers = {});
      controller = controllers[className];
      if (!controller) {
        controllerClass = this.constructor[className];
        controller = controllers[className] = new controllerClass;
        controllerClass.sharedInstance = controller;
      }
      return controller;
    };
    return App;
  })();
  Batman.redirect = function(url) {
    return BATMAN_APP.redirect(url);
  };
  Batman.Controller = (function() {
    function Controller() {
      Controller.__super__.constructor.apply(this, arguments);
    }
    __extends(Controller, Batman.Object);
    Controller.match = function(url, action) {
      return BATMAN_APP.match(url, helpers.camelize(this.name.replace('Controller', ''), true) + '.' + action);
    };
    Controller.beforeFilter = function(action, options) {};
    Controller.prototype.render = function(options) {
      return options || (options = {});
    };
    return Controller;
  })();
  Batman.View = (function() {
    function View() {
      View.__super__.constructor.apply(this, arguments);
    }
    __extends(View, Batman.Object);
    View.prototype.source = View.property().observe(function(path) {
      if (path) {
        return new Batman.Request({
          url: path
        }).success(__bind(function(data) {
          var node;
          this._cachedSource = data;
          node = document.createElement('div');
          node.innerHTML = data;
          return this.set('node', node);
        }, this));
      }
    });
    View.prototype.node = View.property().observe(function(node) {
      if (node) {
        Batman.DOM.parseNode(node, this.context || this);
        return this.ready();
      }
    });
    View.prototype.ready = $event.oneShot(function() {});
    return View;
  })();
  Batman.Model = (function() {
    Model._makeRecords = function(ids) {
      var id, record, _results;
      _results = [];
      for (id in ids) {
        record = ids[id];
        _results.push(new this({
          id: id
        }, record));
      }
      return _results;
    };
    __extends(Model, Batman.Object);
    Model.hasMany = function(relation) {
      var inverse, model;
      model = helpers.camelize(helpers.singularize(relation));
      inverse = helpers.camelize(this.name, true);
      return this.prototype[relation] = function() {
        var query;
        query = {
          model: model
        };
        query[inverse + 'Id'] = this.id;
        return BATMAN_APP[model]._makeRecords(BATMAN_APP.dataStore.query(query));
      };
    };
    Model.hasOne = function(relation) {};
    Model.belongsTo = function(relation) {
      var key, model;
      model = helpers.camelize(helpers.singularize(relation));
      key = helpers.camelize(model, true) + 'Id';
      return this.prototype[relation] = function(value) {
        if (arguments.length) {
          this[key] = value && value.id ? '' + value.id : '' + value;
        }
        return BATMAN_APP[model]._makeRecords(BATMAN_APP.dataStore.query({
          model: model,
          id: this[key]
        }))[0];
      };
    };
    Model.timestamps = function(useTimestamps) {
      if (useTimestamps === false) {
        return;
      }
      this.prototype.createdAt = null;
      return this.prototype.updatedAt = null;
    };
    Model.all = function() {
      return this._makeRecords(BATMAN_APP.dataStore.query({
        model: this.name
      }));
    };
    Model.one = function() {
      return this._makeRecords(BATMAN_APP.dataStore.query({
        model: this.name
      }, {
        limit: 1
      }))[0];
    };
    Model.find = function(id) {
      return new this(BATMAN_APP.dataStore.get(id));
    };
    function Model() {
      this._data = {};
      Model.__super__.constructor.apply(this, arguments);
    }
    Model.prototype.id = '';
    Model.prototype.set = function(key, value) {
      if (arguments.length > 2) {
        return Model.__super__.set.apply(this, arguments);
      }
      return this._data[key] = Model.__super__.set.apply(this, arguments);
    };
    Model.prototype.reload = function() {};
    Model.prototype.save = function() {
      this.id || (this.id = '' + Math.floor(Math.random() * 1000));
      BATMAN_APP.dataStore.set(this.id, Batman.mixin(this.toJSON(), {
        id: this.id,
        model: this.constructor.name
      }));
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
  Batman.Request = (function() {
    function Request() {
      Request.__super__.constructor.apply(this, arguments);
    }
    __extends(Request, Batman.Object);
    Request.prototype.method = 'get';
    Request.prototype.data = '';
    Request.prototype.url = function(url) {
      if (url) {
        this._url = url;
        setTimeout($bind(this, this.send), 0);
      }
      return this._url;
    };
    Request.prototype.send = function(data) {
      this._request = reqwest({
        url: this.get('url'),
        method: this.get('method'),
        success: __bind(function(resp) {
          this.set('data', resp);
          return this.success(resp);
        }, this),
        failure: __bind(function(error) {
          this.set('data', error);
          return this.error(error);
        }, this)
      });
      return this;
    };
    Request.prototype.success = $event(function(data) {});
    Request.prototype.error = $event(function(error) {});
    return Request;
  })();
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
    pluralize: function(string) {
      if (string.substr(-1) === 'y') {
        return "" + (string.substr(0, string.length - 1)) + "ies";
      } else {
        return "" + string + "s";
      }
    }
  };
  Batman.DOM = {
    attributes: {
      bind: function(key, node, context) {
        context.observe(key, true, function(value) {
          return Batman.DOM.valueForNode(node, value);
        });
        return Batman.DOM.events.change(node, function(value) {
          return context.set(key, value);
        });
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
      }
    },
    parseNode: function(node, context) {
      var attribute, binding, child, key, value, _i, _j, _len, _len2, _ref, _ref2, _results;
      if (!node) {
        return;
      }
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
          binding = Batman.DOM.attributes[key];
          if (binding) {
            binding(value, node, context);
          }
        }
      }
      _ref2 = node.childNodes;
      _results = [];
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        child = _ref2[_j];
        _results.push(Batman.DOM.parseNode(child, context));
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
      } else {
        if (isSetting) {
          return node.innerHTML = value;
        } else {
          return node.innerHTML;
        }
      }
    },
    addEventListener: function(node, eventName, callback) {
      if (node.addEventListener) {
        node.addEventListener(eventName, callback);
      } else {
        node.attachEvent("on" + eventName, callback);
      }
      return callback;
    }
  };
  global = typeof exports !== "undefined" && exports !== null ? exports : this;
  global.Batman = Batman;
  global.$mixin = Batman.mixin;
  global.$bind = $bind;
  global.$event = $event;
}).call(this);

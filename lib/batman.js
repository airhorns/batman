(function() {
  if (typeof window !== 'undefined') {
/*!
  * Reqwest! A x-browser general purpose XHR connection manager
  * copyright Dustin Diaz 2011
  * https://github.com/ded/reqwest
  * license MIT
  */
!function(context){function reqwest(a,b){return new Reqwest(a,b)}function init(o,fn){function error(a){o.error&&o.error(a),complete(a)}function success(resp){o.timeout&&clearTimeout(self.timeout)&&(self.timeout=null);var r=resp.responseText;switch(type){case"json":resp=eval("("+r+")");break;case"js":resp=eval(r);break;case"html":resp=r}fn(resp),o.success&&o.success(resp),complete(resp)}function complete(a){o.complete&&o.complete(a)}this.url=typeof o=="string"?o:o.url,this.timeout=null;var type=o.type||setType(this.url),self=this;fn=fn||function(){},o.timeout&&(this.timeout=setTimeout(function(){self.abort(),error()},o.timeout)),this.request=getRequest(o,success,error)}function setType(a){if(/\.json$/.test(a))return"json";if(/\.js$/.test(a))return"js";if(/\.html?$/.test(a))return"html";if(/\.xml$/.test(a))return"xml";return"js"}function Reqwest(a,b){this.o=a,this.fn=b,init.apply(this,arguments)}function getRequest(a,b,c){var d=xhr();d.open(a.method||"GET",typeof a=="string"?a:a.url,!0),setHeaders(d,a),d.onreadystatechange=readyState(d,b,c),a.before&&a.before(d),d.send(a.data||null);return d}function setHeaders(a,b){var c=b.headers||{};c.Accept="text/javascript, text/html, application/xml, text/xml, */*";if(b.data){c["Content-type"]="application/x-www-form-urlencoded";for(var d in c)c.hasOwnProperty(d)&&a.setRequestHeader(d,c[d],!1)}}function readyState(a,b,c){return function(){a&&a.readyState==4&&(twoHundo.test(a.status)?b(a):c(a))}}var twoHundo=/^20\d$/,xhr="XMLHttpRequest"in window?function(){return new XMLHttpRequest}:function(){return new ActiveXObject("Microsoft.XMLHTTP")};Reqwest.prototype={abort:function(){this.request.abort()},retry:function(){init.call(this,this.o,this.fn)}};var old=context.reqwest;reqwest.noConflict=function(){context.reqwest=old;return this},context.reqwest=reqwest}(this)

//Lightweight JSONP fetcher - www.nonobtrusive.com
var JSONP=(function(){var a=0,c,f,b,d=this;function e(j){var i=document.createElement("script"),h=false;i.src=j;i.async=true;i.onload=i.onreadystatechange=function(){if(!h&&(!this.readyState||this.readyState==="loaded"||this.readyState==="complete")){h=true;i.onload=i.onreadystatechange=null;if(i&&i.parentNode){i.parentNode.removeChild(i)}}};if(!c){c=document.getElementsByTagName("head")[0]}c.appendChild(i)}function g(h,j,k){f="?";j=j||{};for(b in j){if(j.hasOwnProperty(b)){f+=encodeURIComponent(b)+"="+encodeURIComponent(j[b])+"&"}}var i="json"+(++a);d[i]=function(l){k(l);d[i]=null;try{delete d[i]}catch(m){}};e(h+f+"callback="+i);return i}return{get:g}}());
};
  /*
  batman
  */  var $bind, $event, $mixin, Batman, FIXME_id, camelize_rx, global, helpers, toString, underscore_rx1, underscore_rx2;
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
  $mixin = Batman.mixin = function() {
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
      } else if (value && value.isProperty) {
        return value.call(this);
      } else {
        return value;
      }
    },
    set: function(key, value) {
      var FIXME_firstObject, FIXME_lastPath, i, index, l, oldValue, results;
      if ((l = arguments.length) > 2) {
        results = (function() {
          var _results;
          _results = [];
          for (i = 0; 0 <= l ? i < l : i > l; i += 2) {
            _results.push(this.set(arguments[i], arguments[i + 1]));
          }
          return _results;
        }).apply(this, arguments);
        return results;
      }
      index = key.lastIndexOf('.');
      if (index !== -1) {
        FIXME_firstObject = this.get(key.substr(0, index));
        FIXME_lastPath = key.substr(index + 1);
        return FIXME_firstObject.set(FIXME_lastPath, value);
      }
      oldValue = this[key];
      if (oldValue !== value) {
        this.fire("" + key + ":before", value, oldValue);
        if (typeof oldValue === 'undefined') {
          this.methodMissing(key, value);
        } else if (oldValue && oldValue.isProperty) {
          oldValue.call(this, value);
        } else {
          this[key] = value;
        }
        this.fire(key, value, oldValue);
      }
      return value;
    },
    unset: function(key) {
      if (typeof this[key] === 'undefined') {
        return this.methodMissing('unset:' + key);
      } else {
        this[key] = null;
        return delete this[key];
      }
    },
    observe: function(key, fireImmediately, callback) {
      var FIXME_firstPath, FIXME_lastPath, FIXME_object, array, index, recursiveObserver, thisKey, thisObject, _base, _i, _len, _ref;
      if (typeof fireImmediately === 'function') {
        callback = fireImmediately;
        fireImmediately = false;
      }
      if ((index = key.lastIndexOf('.')) === -1) {
        array = (_base = this._observers)[key] || (_base[key] = []);
        array.push(callback);
      } else if (false) {
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
      } else {
        FIXME_firstPath = key.substr(0, index);
        FIXME_lastPath = key.substr(index + 1);
        FIXME_object = this.get(FIXME_firstPath);
        if (FIXME_object != null) {
          FIXME_object.observe(FIXME_lastPath, callback);
        }
      }
      if (fireImmediately) {
        callback(this.get(key));
      }
      return this;
    },
    forget: function(key, callback) {
      var FIXME_object, array, index, recursiveObserver, thisKey, thisObject, _i, _len, _ref;
      index = key.lastIndexOf('.');
      if (index === -1) {
        array = this._observers[key];
        array.splice(array.indexOf(callback), 1);
      } else if (false) {
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
      } else {
        FIXME_object = this.get(key.substr(0, index));
        FIXME_object.forget(key.substr(index + 1), callback);
      }
      return this;
    },
    fire: function(key, value, oldValue) {
      var callback, observers, _i, _len;
      observers = this._observers[key];
      if (observers) {
        for (_i = 0, _len = observers.length; _i < _len; _i++) {
          callback = observers[_i];
          if (callback) {
            callback.call(this, value, oldValue);
          }
        }
      }
      return this;
    },
    methodMissing: function(key, value) {
      if (key.indexOf('unset:') !== -1) {
        key = key.substr(6);
        this[key] = null;
        delete this[key];
      } else if (arguments.length > 1) {
        this[key] = value;
      }
      return this[key];
    }
  };
  Batman.Object = (function() {
    Object.property = function(original) {
      var f;
      f = function(value) {
        var result;
        if (typeof original === 'function') {
          result = original.apply(this, arguments);
        }
        if (arguments.length) {
          f.value = result || value;
        }
        return result || f.value;
      };
      if (typeof original !== 'function') {
        f.value = original;
      }
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
      Batman.mixin(this, Batman.Observable);
      this.isClass = true;
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
  Batman.DataStore = (function() {
    function DataStore() {
      DataStore.__super__.constructor.apply(this, arguments);
      this._data = {};
      if (typeof now !== "undefined" && now !== null) {
        now.receiveSync = __bind(function(data) {
          this._data = data;
          return this._syncing = false;
        }, this);
      }
    }
    __extends(DataStore, Batman.Object);
    DataStore.prototype.needsSync = function() {
      if (this._syncing) {
        return;
      }
      if (this._syncTimeout) {
        clearTimeout(this._syncTimeout);
      }
      return this._syncTimeout = setTimeout($bind(this, this.sync), 1000);
    };
    DataStore.prototype.sync = function() {
      if (this._syncing) {
        return;
      }
      if (this._syncTimeout) {
        this._syncTimeout = clearTimeout(this._syncTimeout);
      }
      this._syncing = true;
      return typeof now !== "undefined" && now !== null ? now.sendSync(this._data) : void 0;
    };
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
      if (key.indexOf('unset:') === 0) {
        key = key.substr(6);
        this._data[key] = null;
        delete this._data[key];
      } else if (arguments.length > 1) {
        this._data[key] = value;
      }
      return this._data[key];
    };
    return DataStore;
  })();
  Batman.App = (function() {
    var escapeRegExp, namedOrSplat, namedParam, splatParam;
    namedParam = /:([\w\d]+)/g;
    __extends(App, Batman.Object);
    splatParam = /\*([\w\d]+)/g;
    namedOrSplat = /[:|\*]([\w\d]+)/g;
    escapeRegExp = /[-[\]{}()+?.,\\^$|#\s]/g;
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
    App.root = function(action) {
      return this.match('/', action);
    };
    App._require = function() {
      var name, names, path, _i, _len;
      path = arguments[0], names = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
      for (_i = 0, _len = names.length; _i < _len; _i++) {
        name = names[_i];
        this._notReady();
        new Batman.Request({
          type: 'html',
          url: "" + path + "/" + name + ".coffee"
        }).success(__bind(function(coffee) {
          this._ready();
          return CoffeeScript.eval(coffee);
        }, this));
      }
      return this;
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
    App.global = function(isGlobal) {
      var instance;
      if (isGlobal === false) {
        return;
      }
      Batman.Object.global.apply(this, arguments);
      instance = new this;
      this.sharedApp = instance;
      return global.App = instance;
    };
    App._notReady = function() {
      this._notReadyCount || (this._notReadyCount = 0);
      return this._notReadyCount++;
    };
    App._ready = function() {
      this._notReadyCount--;
      if (this._ranBeforeReady) {
        return this.run();
      }
    };
    App.run = function() {
      if (this._notReadyCount > 0) {
        this._ranBeforeReady = true;
        return false;
      }
      return global.App.run();
    };
    function App() {
      App.__super__.constructor.apply(this, arguments);
      this.dataStore = new Batman.DataStore;
    }
    App.prototype.run = function() {
      var _ref;
      new Batman.View({
        context: global,
        node: document.body
      });
      if ((_ref = this._routes) != null ? _ref.length : void 0) {
        return this.startRouting();
      }
    };
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
      this._cachedRoute = url;
      window.location.hash = this.routePrefix + url;
      return this.dispatch(url);
    };
    App.prototype.dispatch = function(url) {
      var action, actionName, components, controller, controllerName, params, route, _ref;
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
      } else if (typeof action === 'object') {
        controller = this.controller(((_ref = action.controller) != null ? _ref.name : void 0) || action.controller);
        actionName = action.action;
      }
      controller._actedDuringAction = false;
      controller._currentAction = actionName;
      controller[actionName](params);
      if (!controller._actedDuringAction) {
        controller.render();
      }
      delete controller._actedDuringAction;
      return delete controller._currentAction;
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
    return App.redirect(url);
  };
  Batman.Controller = (function() {
    function Controller() {
      Controller.__super__.constructor.apply(this, arguments);
    }
    __extends(Controller, Batman.Object);
    Controller.match = function(url, action) {
      return App.match(url, {
        controller: this,
        action: action
      });
    };
    Controller.beforeFilter = function(action, options) {};
    Controller.prototype.redirect = function(url) {
      this._actedDuringAction = true;
      return Batman.redirect(url);
    };
    Controller.prototype.render = function(options) {
      var key, m, push, value, view;
      this._actedDuringAction = true;
      options || (options = {});
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
          if (Batman.typeOf(value) === 'Array') {
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
    View.prototype.methodMissing = function(key, value) {
      if (!this.context) {
        return View.__super__.methodMissing.apply(this, arguments);
      }
      if (arguments.length > 1) {
        return this.context.set(key, value);
      } else {
        return this.context.get(key);
      }
    };
    return View;
  })();
  FIXME_id = 0;
  Batman.Model = (function() {
    Model._makeRecords = function(ids) {
      var cached, id, r, record, _results;
      cached = this._cachedRecords || (this._cachedRecords = {});
      _results = [];
      for (id in ids) {
        record = ids[id];
        r = cached[id] || (cached[id] = new this({
          id: id
        }));
        _results.push($mixin(r, record));
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
    Model.validate = function(f) {};
    Model.validatesLengthOf = function(key, options) {
      return this.validate(__bind(function() {}, this));
    };
    Model.timestamps = function(useTimestamps) {
      if (useTimestamps === false) {
        return;
      }
      this.prototype.createdAt = null;
      return this.prototype.updatedAt = null;
    };
    Model.persist = function(mixin) {
      var f;
      if (mixin === Batman) {
        f = __bind(function() {
          return FIXME_id = (+(this.last().get('id')) || 0) + 1;
        }, this);
        return setTimeout(f, 1000);
      }
    };
    Model.all = Model.property(function() {
      return this._makeRecords(App.dataStore.query({
        model: this.name
      }));
    });
    Model.first = Model.property(function() {
      return this._makeRecords(App.dataStore.query({
        model: this.name
      }, {
        limit: 1
      }))[0];
    });
    Model.last = Model.property(function() {
      var array;
      array = this._makeRecords(App.dataStore.query({
        model: this.name
      }));
      return array[array.length - 1];
    });
    Model.find = function(id) {
      return this._makeRecords(App.dataStore.query({
        model: this.name,
        id: '' + id
      }))[0];
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
      this.destroy = __bind(this.destroy, this);;
      this.save = __bind(this.save, this);;
      this.reload = __bind(this.reload, this);;      this._data = {};
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
      var oldAll;
      if (!this.id) {
        this.id = '' + (FIXME_id++);
        oldAll = this.constructor.get('all');
      } else {
        this.id += '';
      }
      App.dataStore.set(this.id, Batman.mixin(this.toJSON(), {
        id: this.id,
        model: this.constructor.name
      }));
      App.dataStore.needsSync();
      if (oldAll) {
        this.constructor.fire('all', this.constructor.get('all'), oldAll);
      }
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
  Batman.Request = (function() {
    function Request() {
      Request.__super__.constructor.apply(this, arguments);
    }
    __extends(Request, Batman.Object);
    Request.prototype.method = 'get';
    Request.prototype.data = '';
    Request.prototype.response = '';
    Request.prototype.url = Request.property(function(url) {
      if (url) {
        this._url = url;
        setTimeout($bind(this, this.send), 0);
      }
      return this._url;
    });
    Request.prototype.send = function(data) {
      var options, type;
      options = {
        url: this.get('url'),
        method: this.get('method'),
        success: __bind(function(resp) {
          this.set('response', resp);
          return this.success(resp);
        }, this),
        failure: __bind(function(error) {
          this.set('response', error);
          return this.error(error);
        }, this)
      };
      data || (data = this.get('data'));
      if (data) {
        options.data = data;
      }
      type = this.get('type');
      if (type) {
        options.type = type;
      }
      this._request = reqwest(options);
      return this;
    };
    Request.prototype.success = $event(function(data) {});
    Request.prototype.error = $event(function(error) {});
    return Request;
  })();
  Batman.JSONPRequest = (function() {
    function JSONPRequest() {
      JSONPRequest.__super__.constructor.apply(this, arguments);
    }
    __extends(JSONPRequest, Batman.Request);
    JSONPRequest.prototype.send = function(data) {
      return JSONP.get(this.get('url'), this.get('data') || {}, __bind(function(data) {
        this.set('response', data);
        return this.success(data);
      }, this));
    };
    return JSONPRequest;
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
      content = (_ref = Batman.DOM._yieldContents) != null ? _ref[name] : void 0;
      node.innerHTML = '';
      if (content) {
        return node.appendChild(content);
      }
    },
    contentFor: function(name, node) {
      var contents, yield, _base, _ref;
      contents = (_base = Batman.DOM)._yieldContents || (_base._yieldContents = {});
      contents[name] = node;
      yield = (_ref = Batman.DOM._yields) != null ? _ref[name] : void 0;
      yield.innerHTML = '';
      if (yield) {
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
  Batman.mixins = {
    animation: {
      initialize: function() {
        return this.style.display = 'block';
      },
      show: function(appendTo) {
        var cachedHeight, cachedWidth, f, style;
        style = this.style;
        cachedWidth = this.scrollWidth;
        cachedHeight = this.scrollHeight;
        style.webkitTransition = '';
        style.width = 0;
        style.height = 0;
        style.opacity = 0;
        style.webkitTransition = 'all 0.5s ease-in-out';
        style.opacity = 1;
        style.width = cachedWidth + 'px';
        style.height = cachedHeight + 'px';
        f = __bind(function() {
          style.webkitTransition = '';
          if (appendTo) {
            return appendTo.appendChild(this);
          }
        }, this);
        return setTimeout(f, 450);
      },
      hide: function(remove) {
        var f, style;
        style = this.style;
        style.overflow = 'hidden';
        style.webkitTransition = 'all 0.5s ease-in-out';
        style.opacity = 0;
        style.width = 0;
        style.height = 0;
        f = __bind(function() {
          style.webkitTransition = '';
          if (remove) {
            return this.parentNode.removeChild(this);
          }
        }, this);
        return setTimeout(f, 450);
      }
    },
    editable: {
      initialize: function() {
        return Batman.DOM.addEventListener(this, 'click', $bind(this, this.startEditing));
      },
      startEditing: function() {
        var editor;
        if (this.isEditing) {
          return;
        }
        if (!this.editor) {
          editor = this.editor = document.createElement('input');
          editor.type = 'text';
          editor.className = 'editor';
          Batman.DOM.events.submit(editor, __bind(function() {
            this.commit();
            return this.stopEditing();
          }, this));
        }
        this._originalDisplay = this.style.display;
        this.style.display = 'none';
        this.isEditing = true;
        this.editor.value = Batman.DOM.valueForNode(this);
        this.parentNode.insertBefore(this.editor, this);
        this.editor.focus();
        this.editor.select();
        return this.editor;
      },
      stopEditing: function() {
        if (!this.isEditing) {
          return;
        }
        this.style.display = this._originalDisplay;
        this.editor.parentNode.removeChild(this.editor);
        return this.isEditing = false;
      },
      commit: function() {
        var _ref;
        return (_ref = this._bindingContext) != null ? typeof _ref.set === "function" ? _ref.set(this._bindingKey, this.editor.value) : void 0 : void 0;
      }
    }
  };
  global = typeof exports !== "undefined" && exports !== null ? exports : this;
  global.Batman = Batman;
  global.$mixin = Batman.mixin;
  global.$bind = $bind;
  global.$event = $event;
  $mixin(global, Batman.Observable);
}).call(this);

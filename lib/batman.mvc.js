if (!exports)
    var exports = {};

(function() {
    
    // App
    
    var appRequire = function(prefix) {
        return function(array) {
            if (!Array.isArray(array))
                array = [array];
            
            if (!array.length)
                return;
            
            if (this[prefix + 'Path'])
                prefix = this[prefix + 'Path'];
            else if (this.requirePath)
                prefix = this.requirePath + '/' + prefix;
            
            if (prefix.substr(-1) !== '/')
                prefix += '/';
            
            var i = array.length;
            while (i--)
                array[i] = prefix + array[i] + '.js';
            
            var ready = this.ready;
            ready.prevent();
            
            setTimeout(function() {
                Batman.require(array, function() {
                    ready.allow();
                    
                    if (ready.allowed())
                        ready();
                });
            }, 0);
        };
    };
    
    Batman.App = Batman.Mixin({
        isApp: true,
        controllers: Batman.binding([]).observeForever(appRequire('controllers')),
        models: Batman.binding([]).observeForever(appRequire('models')),
        views: Batman.binding([]).observeForever(appRequire('views')),
        
        ready: Batman.event(null, true),
        
        run: Batman.event(function() {
            if (!this.controllers && !this.models && !this.views)
                this.ready();
            
            if (!this.ready.allowed()) {
                this.ready(function(){this.run();}.bind(this));
                return false;
            }
            
            if (typeof this.mainView === 'undefined' && document && document.body)
                this.mainView = Batman.View({node: document.body});
            
            this.route();
            
            if (this.AppController && this.AppController.appDidRun)
                this.AppController.appDidRun();
        }),
        
        route: Batman.event(function() {
            function hashChanged(e) {
                var hash = window.location.hash;
                hash = hash.substr(Batman.Controller.routePrefix.length);
                
                Batman.Controller.route(hash || '/');
            }
            
            var oldHash = window.location.hash;
            function checkHashChange() {
                var hash = window.location.hash;
                
                if (hash !== oldHash) {
                    oldHash = hash;
                    hashChanged();
                }
            }
            
            if ('onhashchange' in window)
                window.addEventListener('hashchange', hashChanged);
            else
                setInterval(checkHashChange, 250);
            
            if (Batman.Controller.routes.length)
                hashChanged();
        }),
    });
    
    // Controller
    
    // route matching courtesy of Backbone
    var namedParam    = /:([\w\d]+)/g;
    var splatParam    = /\*([\w\d]+)/g;
    var namedOrSplat  = /[:|\*]([\w\d]+)/g;
    var escapeRegExp  = /[-[\]{}()+?.,\\^$|#\s]/g;

    
    Batman.Controller = Batman.Mixin({
        isController: true,
        
        initialize: function() {
            if (this.identifier)
                Batman.Controller.controllers[this.identifier] = this;
        },
        
        render: function(options) {
            options = options || {};
            
            if (options.template)
                options.view = Batman.View({template: options.template});
            else if (options.text) {
                var node = document.createElement('div');
                node.innerHTML = options.text;
                
                options.view = Batman.View({node: node});
            }
            
            if (!options.view && this.currentRoute) {
                var cached = this.currentRoute._cachedView;
                if (cached)
                    options.view = cached;
            }
            
            if (!options.view)
                options.view = Batman.View({template: [this.identifier, this.action].join('/')});
            
            if (this.currentRoute)
                this.currentRoute._cachedView = options.noCache ? null : options.view;
            
            options.view.ready(function() {
                Batman.DOM.bindings.contentFor('main', options.view.node());
            });
        }
    }).mixin({
        controllers: {},
        
        routePrefix: '#!',
        ignoreInvalidRoutes: false,
        
        route: Batman.binding().observe(function(match) {
            window.location.hash = this.routePrefix + match;
            
            if (!this._routeFunctionCalled) {
                var route = this.matchRoute(match);
                if (route)
                    route.dispatch(this.extractParams(match, route));
                
                else if (!this.ignoreInvalidRoutes)
                    this.route('/404');
            }
            
            this._routeFunctionCalled = false;
        }),
        
        _routeFunctionCalled: false,
        
        routes: [],
        addRoute: function(match, route) {
            Batman.Route.applyTo(route);
            route.match = match = match.replace(escapeRegExp, '\\$&');
            route.regexp = new RegExp('^' + match.replace(namedParam, '([^\/]*)').replace(splatParam, '(.*?)') + '$');
            
            var array, paramNames = route.paramNames;
            while ((array = namedOrSplat.exec(match)) !== null)
                array[1] && paramNames.push(array[1]);
            
            this.routes.push(route);
            return route;
        },
        
        matchRoute: function(match) {
            var routes = this.routes, route;
            for (var i = -1, count = routes.length; ++i < count;) {
                route = routes[i];
                
                if (route.regexp.test(match))
                    return route;
            }
        },
        
        extractParams: function(match, route) {
            var array = route.regexp.exec(match).slice(1),
                params = {};
            
            for (var i = -1, count = array.length; ++i < count;)
                params[route.paramNames[i]] = array[i];
            
            return params;
        }
    });
    
    Batman.route = function(match, func) {
        var route = function(params) {
            var string = route.match;
            if (params)
                for (var key in params)
                    string = string.replace(new RegExp('[:|\*]' + key), params[key]);
            
            Batman.Controller._routeFunctionCalled = true;
            Batman.Controller.route(string);
            
            return route.dispatch(params);
        };
        
        if (func && func.isModel)
            func.identifier = match;
        
        Batman.Controller.addRoute(match, route);
        route.action = func;
        
        return route;
    };
    
    Batman.currentRoute = Batman.Controller.route;
    var currentRoute;
    
    Batman.Route = Batman.Mixin({
        _configureOnMixin: true,
        configure: function(object, key) {
            delete this._configureOnMixin;
            
            this.context = object;
            return this;
        },
        
        isRoute: true,
        isCurrent: $binding(false),
        
        action: null,
        match: '',
        regexp: null,
        
        paramNames: [],
        
        dispatch: function(params) {
            currentRoute && currentRoute.isCurrent(false);
            
            currentRoute = this;
            currentRoute.isCurrent(true);
            
            var context = this.context;
            if (context && context.isController) {
                context.currentRoute = this;
                
                for (var key in context)
                    if (context[key] === this) {
                        context.action = key;
                        break;
                    }
            }
            
            if (typeof this.action === 'function')
                return this.action.apply(context || this, arguments);
        },
        
        url: function(params) {
            return this.bind(this, params);
        },
        
        toString: function() {
            return this.match;
        }
    });
    
    if (typeof $C === 'undefined')
        $C = Batman.Controller;
    
    if (typeof $route === 'undefined')
        $route = Batman.route;
    
    // Model
    
    Batman.Model = Batman.mixin(function(identifier) {
        var mixin = Batman.Mixin(Batman.Record, Array.toArray(arguments)).mixin(Batman._Model);
        mixin.enhance({model: mixin});
        
        if (typeof identifier === 'string') {
            mixin.identifier = identifier;
            Batman.Model.models[identifier] = mixin;
        }
        
        return mixin;
    }, {
        models: {},
        
        hasOne: function(relation) {
            var binding = Batman.binding();
            binding._copy.hasOne = relation;
            
            return binding;
        },
        
        hasMany: function(relation) {
            return Batman.binding([]);
        }
    });
    
    Batman._Model = Batman.Mixin({
        initialize: function() {
            this.dataStore = {};
        },
        
        all: $binding([]),
        
        first: $binding(function() {
            return this.all()[0];
        }),
        
        last: $binding(function() {
            var all = this.all();
            return all[all.length - 1];
        }),
        
        exists: function(id) {
            return ''+id in this.dataStore;
        },
        
        find: function(id) {
            return this.dataStore[''+id];
        },
        
        findOrCreate: function(id) {
            if (this.exists(id))
                return this.find(id);
            
            return this.create({id: ''+id});
        },
        
        select: function(callback) {
            var all = this.all();
            for (var i = -1, count = all.length; ++i < count;) {
                var record = all[i];
                if (callback(record))
                    return record;
            }
        },
        
        beforeLoad: Batman.event(),
        load: Batman.event(function() {
            if (this._isLoading)
                return;
            
            this._isLoading = true;
            
            this.beforeLoad();
            this.readAllFromStore(function() {
                this.load.fire.apply(this.load, arguments);
                
                var all = this.all(), i = all.length;
                while (i--)
                    all[i]._lastLoad = new Date();
                
                delete this._isLoading;
            }.bind(this));
            
            return false;
        }),
        
        fromJSON: function(record, json) {
            for (var key in record) {
                var binding = record[key];
                if (binding && binding._copy && binding._copy.hasOne) {
                    var foreignKey = Batman.helpers.underscore(key) + '_id',
                        id = json[foreignKey];
                    
                    if (typeof id !== 'undefined') {
                        var foreignModel = Batman.Model.models[binding._copy.hasOne],
                            foreignRecord = foreignModel.findOrCreate(id);
                        
                        record[key](foreignRecord);
                        foreignRecord.loadIfNeeded();
                        
                        delete json[foreignKey];
                    }
                }
            }
        }
    });
    
    Batman.Record = Batman.Mixin({
        isRecord: true,
        model: null,
        
        id: $binding().observeForever(function(id) {
            var all = this.model.all(),
                dataStore = this.model.dataStore;
            
            if (id) {
                dataStore[''+id] = this;
                if (Array.indexOf(all, this) === -1)
                    this.model.all.push(this);
            } else {
                if (Array.indexOf(all, this) !== -1) {
                    this.model.all.removeObject(this);
                    for (var key in dataStore) {
                        var value = dataStore[key];
                        if (value === this) {
                            dataStore[key] = null;
                            break;
                        }
                    }
                }
            }
        }),
        
        beforeLoad: Batman.event(),
        load: Batman.event(function() {
            if (this._isLoading)
                return;
            
            this._isLoading = true;
            
            this.beforeLoad();
            this.model.readFromStore(this, function() {
                this.load.fire.apply(this.load, arguments);
                
                this._lastLoad = new Date();
                delete this._isLoading;
            }.bind(this));
            
            return false;
        }),
        
        loadIfNeeded: function() {
            if (!this._lastLoad || (new Date()) - this._lastLoad > 10000)
                this.load();
        },
        
        beforeSave: Batman.event(),
        save: Batman.event(function() {
            if (this._isSaving)
                return false;
            
            this._isSaving = true;
            this.saveLater(true);
            
            if (!this.isValid())
                throw "Record is invalid";
            
            this.beforeSave();
            this.model.writeToStore(this, function() {
                this.save.fire.apply(this.save, arguments);
                delete this._isSaving;
            }.bind(this));
            
            return false;
        }),
        
        saveLater: function(cancel) {
            if (this._saveTimeout)
                this._saveTimeout = clearTimeout(this._saveTimeout);
            
            if (this._isSaving)
                return;
            
            if (!cancel)
                this._saveTimeout = setTimeout(this.save.bind(this), 1000);
        },
        
        isValid: function() {
            for (var key in this) {
                var binding = this[key];
                if (binding && binding.isBinding)
                    if (!binding.performValidation(binding.value))
                        return false;
            }
            
            return true;
        },
        
        toJSON: function() {
            var obj = {};
            for (var key in this) {
                var binding = this[key];
                if (binding && binding.isBinding)
                    obj[key] = binding();
            }
            
            return obj;
        },
        
        fromJSON: function(json) {
            this.model.fromJSON(this, json);
            
            for (var key in json) {
                if (key.indexOf('_') !== -1) {
                    json[Batman.helpers.camelize(key, true)] = json[key];
                    delete json[key];
                }
            }
            
            Batman.mixin(this, json);
        }
    });
    
    if (typeof $M === 'undefined')
        $M = Batman.Model;
    
    // View
    
    Batman.View = Batman.Mixin({
        isView: true,
        
        initialize: function() {
            if (this.identifier)
                Batman.View.views[this.identifier] = this;
        },
        
        context: null,
        
        node: Batman.binding(null).observeForever(function(node) {
            if (!node)
                return;
            
            Batman.require(Batman.LIB_PATH + 'batman.dom.js', function() {
                Batman.DOM.view(this);
                this.ready();
            }.bind(this));
        }),
        
        template: Batman.binding(null).observeForever(function(template) {
            if (!template)
                return;
            
            Batman.Request({url: 'views/' + template + '.html'}).success(function(html) {
                this._template = html;
                
                var node = this.node() || document.createElement('div');
                node.innerHTML = html;
                
                this.node.value = null;
                this.node(node);
            }.bind(this));
        }),
        
        ready: Batman.event(null, true)
    }).mixin({
        views: {}
    });
    
    if (typeof $V === 'undefined')
        $V = Batman.View;
    
})();

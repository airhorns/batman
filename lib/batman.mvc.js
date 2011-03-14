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
            if (this.defaultRoute)
                this.defaultRoute();
        })
    });
    
    // Controller
    
    Batman.Controller = Batman.Mixin({
        isController: true
    });
    
    Batman.Controller.route = function(match, func) {
        var route = function() {
            window.location.hash = '#' + match;
            
            var result;
            if (typeof func === 'function')
                result = func.apply(this, arguments);
            
            if (result && result.isView) {
                result.ready(function() {
                    // FIXME: What if there's no node at all?
                    Batman.DOM.bindings.contentFor('main', result.node);
                });
                
                if (!result.node && !result.template)
                    result.ready();
            }
            
            return result;
        };
        
        if (func && func.isModel) {
            func.identifier = match;
        }
        
        Batman.Controller.Route.applyTo(route);
        return route;
    };
    
    Batman.Controller.Route = Batman.Mixin({
        isRoute: true
    });
    
    if (typeof $C === 'undefined')
        $C = Batman.Controller;
    
    // Model
    
    Batman.Model = Batman.Mixin({
        isModel: true,
        
        all: Batman.binding([]),
        first: Batman.binding(function() {
            return this.all()[0];
        }),
        last: Batman.binding(function() {
            var all = this.all();
            return all[all.length - 1];
        }),
        
        // record instantiation via model; adds to all array
        create: function() {
            var array = arguments[0];
            if (Array.isArray(array)) {
                var records = [];
                for (var i = -1, count = array.length; ++i < count;)
                    records.push(this.create(array[i]));
                
                return records;
            }
            
            var record = Batman.Mixin.prototype.create.apply(this, arguments);
            record.model = this;
            
            record.destroy(function() {
                this.all.removeObject(record);
            }.bind(this));
            
            this.all.push(record);
            return record;
        },
        
        find: function(selector) {
            var all = this.all();
            
            if (!selector)
                return;
            
            if (typeof selector === 'string' || typeof selector === 'number') {
                for (var i = -1, count = all.length; ++i < count;) {
                    if (all[i].id() == selector) return all[i];
                }
                
                return;
            }
            
            for (var i = -1, count = all.length; ++i < count;) {
                var record = all[i];
                if (!record)
                    continue;
                
                for (var key in selector) {
                    if (!(key in record)) {
                        record = null;
                        break;
                    }
                    
                    var left = record[key];
                    var right = selector[key];
                    
                    if (left && left.isBinding) {
                        if (left() !== right) {
                            record = null;
                            break;
                        }
                    }
                    else if (left !== right) {
                        record = null;
                        break;
                    }
                }
                
                if (record)
                    return record;
            }
        }
    }).mixin({
        // creating a new model, returns custom record mixin
        create: function() {
            return Batman.Mixin(Batman.Record, Array.toArray(arguments)).mixin(Batman.Model);
        },
        
        Singleton: function() {
            return this.create.apply(this, arguments).create();
        }
    });
    
    Batman.Record = Batman.Mixin(Batman.Transactionable, {
        isRecord: true,
        id: $binding(null),
        
        commitLater: function() {
            if (this._commitTimeout)
                clearTimeout(this._commitTimeout);
            
            this._commitTimeout = setTimeout(this.commit.bind(this), Batman.Record.commitTimeout);
        },
        
        commit: Batman.event(function(cancel) {
            if (this._commitTimeout)
                clearTimeout(this._commitTimeout);
            
            if (cancel)
                return;
        }),
        
        destroy: Batman.event(function() {
            // FIXME: send to data store
        }),
        
        update: Batman.event(function() {
            // FIXME: send to data store
        })
    }).mixin({
        commitTimeout: 1000
    });
    
    Batman.Model.mixin({
        hasMany: function(model) {
            
        },
        
        hasOne: function(model) {
            
        },
        
        belongsTo: function(model, key) {
            
        },
        
        timestamps: function() {
            return {
                createdAt: Batman.binding(null),
                updatedAt: Batman.binding(null)
            }
        }
    });
    
    if (typeof $M === 'undefined')
        $M = Batman.Model;
    
    // View
    
    Batman.View = Batman.Mixin({
        isView: true,
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
    });
    
    if (typeof $V === 'undefined')
        $V = Batman.View;
    
    // Globals
    
    if (typeof $route === 'undefined')
        $route = Batman.Controller.route;
    
    // Helpers
    // FIXME: Should this go here? Should this even be part of Batman?
    
    var textHelper = function(formatter) {
        return function(bindingOrText, options) {
            if (bindingOrText && bindingOrText.isBinding) {
                var binding = Batman.binding(function() {
                    return formatter(bindingOrText(), options);
                });
                
                binding.observeDependencies();
                return binding;
            }
            
            return formatter(bindingOrText, options);
        }
    };
    
    Batman.View.helpers = {
        simple_format: textHelper(function(string, options) {
            return '<p>' + string
                .replace(/\r\n?/g, '\n')
                .replace(/\n\n+/g, '</p>\n\n<p>')
                .replace(/([^\n]\n)(?=[^\n])/g, '\1<br />') + // FIXME: Removes last letter
                '</p>';
        }),
        
        auto_link: textHelper(function(string, options) {
            return string; // FIXME
        })
    }
    
})();

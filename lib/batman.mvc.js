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
        
        beforeLoad: Batman.event(),
        load: Batman.event(function() {
            this.beforeLoad();
            this.prototype.readAllFromStore(function() {
                this.load.fire.apply(this.load, arguments);
            }.bind(this));
            
            return false;
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
                    if (all[i].id() == selector)
                        return all[i];
                }
                
                return this({id: selector});
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
        create: function(identifier) {
            var model = Batman.Record.copy(typeof identifier === 'string' && identifier).mixin(Batman.Model);
            model.prototype.model = model;
            
            model.enhance.apply(model, arguments);
            model.load();
            
            return model;
        },
        
        Singleton: function() {
            return this.create.apply(this, arguments).create();
        }
    });
    
    Batman.Record = Batman.Mixin(Batman.Transactionable, {
        isRecord: true,
        model: null,
        
        id: $binding(null),
        
        autosaveInterval: 1000,
        saveLater: function(cancel) {
            if (this._isSaving)
                return;
            
            if (this._saveTimeout)
                this._saveTimeout = clearTimeout(this._saveTimeout);
            
            if (!cancel)
                this._saveTimeout = setTimeout(this.save.bind(this), this.autosaveInterval);
        },
        
        beforeSave: Batman.event(),
        save: Batman.event(function() {
            if (this._isSaving)
                return;
            
            if (this._saveTimeout)
                this._saveTimeout = clearTimeout(this._saveTimeout);
            
            this._isSaving = true;
            
            this.beforeSave();
            this.writeToStore(function() {
                this.save.fire.apply(this.save, arguments);
                delete this._isSaving;
            }.bind(this));
            
            return false;
        }),
        
        beforeLoad: Batman.event(),
        load: Batman.event(function() {
            if (this._isLoading)
                return;
            
            this._isLoading = true;
            
            this.beforeLoad();
            this.readFromStore(function() {
                this.load.fire.apply(this.load, arguments);
                delete this._isLoading;
            }.bind(this));
            
            return false;
        }),
        
        destroy: Batman.event(function() {
            this.removeFromStore(function() {
                this.destroy.fire.apply(this.destroy, arguments);
            }.bind(this));
            
            return false;
        }),
        
        serialize: function() {
            var obj = {};
            for (var key in this) {
                var binding = this[key];
                if (binding && binding.isBinding && !binding._preventAutocommit) {
                    var value = binding();
                    if (typeof value !== 'undefined')
                        obj[key] = value;
                }
            }
            
            return obj;
        },
        
        unserialize: function(data) {
            // FIXME camelCase
            Batman.mixin(this, data);
        },
        
        readAllFromStore: function(callback) { callback && callback(); },
        readFromStore: function(callback) { callback && callback(); },
        writeToStore: function(callback) { callback && callback(); },
        removeFromStore: function(callback) { callback && callback(); }
    }).mixin({
        enhance: function() {
            Batman.Mixin.prototype.enhance.apply(this, arguments);
            
            var proto = this.prototype, key;
            for (key in proto) {
                var binding = proto[key];
                if (binding && binding.isBinding && !binding._preventAutosave)
                    binding.observeDeferred(function() {
                        this.saveLater();
                    });
            }
            
            return this;
        }
    });
    
    Batman.Binding.enhance({
        preventAutosave: function() {
            this._preventAutosave = true;
            return this;
        },
        
        preventAutocommit: function() {
            this._preventAutocommit = true;
            return this;
        }
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

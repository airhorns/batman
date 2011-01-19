(function() {
    
    // App
    
    var appRequire = function(prefix) {
        return function(array) {
            if (!Array.isArray(array))
                array = [array];
            
            if (this[prefix + 'Path'])
                prefix = this[prefix + 'Path'];
            else if (this.requirePath)
                prefix = this.requirePath + prefix;
            
            var i = array.length;
            while (i--)
                array[i] = prefix + '/' + array[i];
            
            var ready = this.ready;
            ready.prevent();
            
            setTimeout(function() {
                Batman.require(array, function() {
                    ready.allow();
                    
                    if (ready.isAllowed())
                        ready();
                });
            });
        };
    };
    
    Batman.App = Batman.Mixin({
        isApp: true,
        
        ready: Batman.event(null, true),
        
        run: Batman.event(function() {
            if (!this.controllers && !this.models && !this.views)
                this.ready();
            
            if (!this.ready.isAllowed()) {
                this.onready(function(){this.run();}.bind(this));
                return false;
            }
            
            if (!this.mainView && document && document.body)
                this.mainView = Batman.View({node: document.body});
        })
    }).use({
        controllers: appRequire('controllers'),
        models: appRequire('models'),
        views: appRequire('views')
    });
    
    // Controller
    
    Batman.Controller = Batman.Mixin({
        isController: true
    });
    
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
            var record = Batman.Mixin.prototype.create.apply(this, arguments);
            record.model = this;
            record.reloadSerialization();
            
            // Observe after the end of this loop, to allow for object init
            setTimeout(function() { // FIXME: Tobi says we don't want to do this
                record.serialized.observe(record.commitLater);
            }, 0);
            
            record.ondestroy(function() {
                this.all.removeObject(this);
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
                    // debugger;
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
            var recordMixin = Batman.Mixin(Batman.Record, Array.toArray(arguments)).mixin(Batman.Model);
            
            for (var key in recordMixin.prototype) {
                var binding = recordMixin.prototype[key];
                if (binding && binding.isBinding && !('_serialize' in binding))
                    binding.serialize(true);
            }
            
            return recordMixin;
        }
    });
    
    Batman.Record = Batman.Mixin({
        isRecord: true,
        id: $binding(null),
        
        transaction: function() {
            var obj = {};
            for (var key in this)
                if (!(key in Batman.Record.prototype))
                    obj[key] = this[key];
            
            return Batman.Transaction(obj, {isRecord: this}, Array.toArray(arguments));
        },
        
        serialized: Batman.binding(function() {
            var data = {};
            
            if (typeof Batman.Record === 'undefined')
                return;
            
            for (var key in this) {
                if (key in Batman.Record.prototype)
                    continue;
                
                var binding = this[key];
                if (binding && binding.isBinding && binding.serialize)
                    data[key] = binding();
            }
            
            return data;
        }),
        
        reloadSerialization: function() {
            return this.serialized.observeDependencies();
        },
        
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
    
    Batman.Transaction = Batman.Mixin({
        isTransaction: true,
        isRecord: null, // FIXME: are we sure we want to duck type this?
        
        commit: function() {
            var obj = {};
            for (var key in this) {
                if (key in Batman.Transaction.prototype)
                    continue;
                
                var value = this[key];
                if (value && value.isBinding)
                    value = value();
                
                obj[key] = value;
            }
            
            Batman.mixin(this.isRecord, obj);
            this.isRecord.commit();
        }
    });
    
    // FIXME: Don't do this
    Batman.Binding.prototype.serialize = function(flag) {
        this._serialize = flag;
    };
    
    // View
    
    Batman.View = Batman.Mixin({
        isView: true,
        context: null,
        
        ready: Batman.event(null, true)
    }).use({
        node: {require: 'batman.dom.js', callback: function() { Batman.DOM.view(this); this.ready(); }}
    });
    
})();

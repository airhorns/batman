(function() {
    
    // Batman.require
    
    var requiredFiles = typeof BATMAN_REQUIRED_FILES !== 'undefined' ? BATMAN_REQUIRED_FILES : {};
    var require = function(files, callback) {
        if (!files)
            return;
        
        if (!Array.isArray(files))
            files = [files];
        
        var scriptCallback = function(file) {
            return function() {
                requiredFiles[file] = true;
                
                var i = files.length;
                while (i--)
                    if (requiredFiles[files[i]].nodeName)
                        return;
                
                Batman.execute(callback);
            };
        };
        
        var i = files.length, script;
        while (i--) {
            var file = files[i];
            if (requiredFiles[file]) {
                if (!requiredFiles[file].nodeName)
                    continue;
                
                script = requiredFiles[file];
            }
            else {
                script = document.createElement('script');
                script.type = 'text/javascript';
                script.charset = 'utf-8';
                script.async = true;
                
                var url;
                if (file.substr(file.length - 3) === '.js')
                    url = BATMAN_BASE_URL + file;
                else
                    url = file + '.js';
                
                script.src = url;
                
                requiredFiles[file] = script;
            }
            
            if (script.addEventListener)
                script.addEventListener('load', scriptCallback(file), false);
            else
                script.attachEvent('onreadystatechange', scriptCallback(file));
            
            if (!script.parentNode)
                document.head.appendChild(script);
        }
        
        if (!script)
            Batman.execute(callback);
    };
    
    if (typeof BATMAN_BASE_URL === 'undefined') {
        var scripts = document.getElementsByTagName('script');
        for (var i = -1, count = scripts.length; ++i < count;) {
            var script = scripts[i];
            if (!script || !script.src)
                continue;
            
            var index = script.src.indexOf('batman.js');
            if (index !== -1) {
                BATMAN_BASE_URL = script.src.substr(0, index);
                break;
            }
        }
    }
    
    // Utilities
    
    if (!Array.isArray)
        Array.isArray = function(object) { return Object.prototype.toString.call(object) === '[object Array]'; };
    
    if (!Array.toArray)
        Array.toArray = function(object) { return Array.prototype.slice.call(object); };
    
    if (!Array.indexOf)
        Array.indexOf = function(array, object) {
            if (Array.prototype.indexOf)
                return Array.prototype.indexOf.call(array, object);
            
            for (var i = -1, count = array.length; ++i < count;)
                if (array[i] === object)
                    return i;
        }
    
    var extendPrototype = function(prototype, key, func) {
        if (prototype.prototype)
            prototype = prototype.prototype;
        
        if (Object.defineProperty)
            Object.defineProperty(prototype, key, {value: func, writable: true, configurable: true, enumerable: false});
        else
            prototype[key] = func;
    };
    
    if (!Function.prototype.bind)
        extendPrototype(Function, 'bind', function(context) {
            var original = this;
            return function() { return original.apply(context, arguments); };
        });
    
    if (!Function.prototype.curry)
        extendPrototype(Function, 'curry', function(argBlob) {
            var original = this, args = Array.toArray(arguments);
            return function() { return original.apply(this, args); };
        });
    
    Batman = function() {
        return Batman.mixin({}, Array.toArray(arguments));
    };
    
    Batman.require = require;
    
    Batman.execute = function(func) {
        if (!func)
            return;
        
        var args = Array.toArray(arguments).splice(1);
        
        if (Array.isArray(func))
            for (var i = -1, count = func.length; ++i < count;)
                func[i].apply(this, args);
        else
            func.apply(this, args);
    };
    
    // Mixins
    
    Batman.mixin = function(to) {
        if (!to)
            return;
        
        for (var i = 0, count = arguments.length; ++i < count;) {
            var arg = arguments[i];
            if (!arg)
                continue;
            
            if (arg.isMixin && arg.prototype)
                arg.applyTo(to);
            
            else if (Array.isArray(arg)) {
                var array = Array.toArray(arg);
                array.unshift(to);
                
                Batman.mixin.apply(Batman, array);
            }
            
            else if (typeof arg === 'object')
                for (var key in arg) {
                    var value = arg[key];
                    if (value && value.mixinPrototype) {
                        if (Array.isArray(value.mixinPrototype))
                            value = Array.toArray(value.mixinPrototype);
                        else if (value.mixinPrototype.copy)
                            value = value.mixinPrototype.copy();
                    }
                    
                    if (value && value._configureOnMixin)
                        value.configure(to, key);
                    
                    var binding = to[key];
                    if (binding && binding.isBinding && !(value && value.isBinding))
                        binding(value);
                    else
                        to[key] = value;
                }
            
            var use = to._use;
            if (use)
                for (var key in use)
                    if (to[key]) {
                        Batman.Mixin._use(to, use[key], key);
                        delete use[key];
                    }
        }
        
        return to;
    };
    
    Batman.unmixin = function(from) {
        
    };
    
    // Batman.Mixin
    
    Batman.mixins = {};
    
    // Global constructor
    Batman.Mixin = function(identifier) {
        
        // Instance constructor
        var constructor = function() {
            return constructor.create.apply(constructor, arguments);
        };
        
        Batman.mixin(constructor, Batman.Mixin.prototype, {prototype: {}});
        constructor.enhance.apply(constructor, arguments);
        
        if (typeof identifier === 'string') {
            constructor.isMixin = identifier;
            Batman.mixins[identifier] = constructor;
        }
        
        return constructor;
    };
    
    Batman.Mixin.prototype = {
        isMixin: true,
        
        // mixin properties to the prototype
        enhance: function() {
            Batman.mixin(this.prototype, Array.toArray(arguments));
            
            for (var key in this.prototype) {
                var value = this.prototype[key];
                if (value && (value.isBinding || Array.isArray(value)))
                    value.mixinPrototype = value;
            }
            
            return this;
        },
        
        // Instance factory
        create: function() {
            return Batman(this, Array.toArray(arguments));
        },
        
        applyTo: function(to) {
            Batman.mixin(to, this.prototype);
            
            if (this._uses) {
                if (!to._use)
                    to._use = {};
                
                for (var key in this._uses)
                    to._use[key] = this._uses[key];
            }
            
            return this;
        },
        
        removeFrom: function(from) {
            Batman.unmixin(from, this.prototype);
            return this;
        },
        
        // mixin properties to the Mixin object itself
        mixin: function() {
            return Batman.mixin(this, Array.toArray(arguments));
        },
        
        // tell the Mixin object to detect certain properties after mixin
        use: function(object) {
            if (!this._uses)
                this._uses = {};
            
            for (var key in object)
                this._uses[key] = object[key];
            
            return this;
        },
        
        toObject: function() {
            var obj = {prototype: this.prototype};
            
            for (var key in this)
                obj[key] = this[key];
            
            return obj;
        }
    };
    
    Batman.Mixin._use = function(object, action, key) {
        if (action.require)
            require(action.require, function() {
                if (action.callback)
                    Batman.Mixin._use(object, action.callback, key);
            });
        else if (typeof action === 'function')
            action.call(object, object[key]);
    };
    
    // Bindings
    
    Batman.binding = function(valueOrFunction) {
        var binding = Batman.Binding();
        if (typeof valueOrFunction === 'function') {
            binding.get = valueOrFunction;
            binding.set = valueOrFunction;
            
            binding._needsToObserveDependencies = true;
        } else
            binding(valueOrFunction);
        
        return binding;
    }
    
    Batman.Binding = function(getter, setter) {
        var binding = function(value) {
            if (arguments.length > 0) {
                var oldValue = binding.value;
                if (oldValue === value)
                    return;
                
                binding.value = value;
                
                if (binding.set)
                    binding.set.apply(binding.context || binding, arguments);
                
                binding.valueDidChange(oldValue, binding.value);
                binding.fire(binding.value);
            } else {
                var evalBinding = Batman.Binding._eval;
                if (evalBinding && evalBinding !== binding)
                    evalBinding.observes(binding);
                
                if (binding.get)
                    binding.value = binding.get.apply(binding.context || binding, arguments);
            }
            
            return binding.value;
        };
        
        binding.observers = []; // FIXME: These should be in the prototype
        binding.keysFromValue = [];
        
        Batman.mixin(binding, Batman.Binding.prototype);
        
        if (getter)
            binding.get = getter;
        if (setter)
            binding.set = setter;
        
        return binding;
    };
    
    Batman.Binding.prototype = {
        isBinding: true,
        
        _configureOnMixin: true,
        configure: function(object, key) {
            delete this._configureOnMixin;
            
            this.context = object;
            
            if (this._needsToObserveDependencies)
                this.observeDependencies();
            
            return this;
        },
        
        // whenever the value of the binding changes, your function will be called
        // pass fireImmediately to fire the function immediately
        observe: function(func, fireImmediately) {
            if (Array.indexOf(this.observers, func) === -1)
                this.observers.push(func);
            
            if (fireImmediately)
                func.call(this.context || Batman, this.value);
            
            return this;
        },
        
        // remove your function as an observer (must be the same function pointer)
        forget: function(func) {
            var index = Array.indexOf(this.observers, func);
            if (index !== -1)
                this.observers.splice(index, 1);
            
            return this;
        },
        
        // alias to observe
        on: function() {
            // we put these in a closure because observe may change
            return this.observe.apply(this, arguments);
        },
        
        // alias to observe
        when: function() {
            return this.observe.apply(this, arguments);
        },
        
        // called internally when the value changes to fire all observers.
        // still public, so use it if you need to
        fire: function(value) {
            if (arguments.length < 1)
                value = this();
            
            var context = this.context || Batman,
                observers = this.observers;
            
            for (var i = -1, count = observers.length; ++i < count;) {
                var observer = observers[i];
                if (observer.isBinding)
                    observer.fire();
                else
                    observer.call(context, value, context);
            }
            
            return this;
        },
        
        // for a computed binding, this will call the binding and then walk the dependency tree and observe all dependent bindings.
        // this will be called automatically if you use $binding
        observeDependencies: function() {
            this.forgetDependencies();
            
            Batman.Binding._eval = this;
            var result = this();
            Batman.Binding._eval = null;
            
            return result;
        },
        
        // stops observing all dependent bindings
        forgetDependencies: function() {
            var i = this._dependencies ? this._dependencies.length : 0
            while (i--)
                this._dependencies[i].forget(this);
            
            this._dependencies = [];
        },
        
        // manually add a dependent binding. whenever that binding changes, this binding will fire
        observes: function(binding) {
            if (!this._dependencies)
                this._dependencies = [];
            
            if (Array.indexOf(binding) === -1)
                this._dependencies.push(binding);
            
            binding.observe(this);
        },
        
        toString: function() {
            return this.identifier || (this.value && this.value.toString ? this.value.toString() : Object.prototype.toString.call(this.value)) || 'empty binding';
        },
        
        toObject: function() {
            var obj = {};
            
            for (var key in this)
                obj[key] = this[key];
            
            return obj;
        },
        
        copy: function() {
            var binding = Batman.Binding(this.get, this.set);
            if (this.mixinPrototype)
                binding.mixinPrototype = this.mixinPrototype;
            
            if (Array.isArray(this.value))
                binding.value = Array.toArray(this.value);
            else
                binding.value = this.value;
            
            binding.valueDidChange(null, binding.value);
            
            return binding;
        },
        
        // when the value changes, this function will introspect it and apply certain properties to the binding based on the type of the value.
        // most commonly, this applies array-like properties for an array value.
        valueDidChange: function(oldValue, value) {
            if (!value)
                return this.removeKeysForValue();
            
            if (Array.isArray(value)) {
                if (Array.isArray(oldValue))
                    return;
                
                this.removeKeysForValue();
                
                var arrayMethod = function(method) {
                    var binding = this; // just to eek out a tiny bit of performance
                    return function() {
                        var result = method.apply(value, arguments);
                        binding.fire(value);
                        
                        return result;
                    };
                };
                
                var methods = Object.getOwnPropertyNames(Array.prototype), // FIXME
                    i = methods.length;
                
                while (i--) {
                    var methodName = methods[i],
                        method = Array.prototype[methodName];
                    
                    if (this[methodName] || typeof method !== 'function' || ['constructor', 'toString'].indexOf(methodName) !== -1)
                        continue;
                    
                    this[methodName] = arrayMethod.call(this, method);
                    this.keysFromValue.push(this);
                }
                
                this.count = Batman.binding(function() {
                    return this().length;
                }.bind(this));
                
                this.keysFromValue.push('count');
                
                Batman.Binding.Array.applyTo(this);
                for (var key in Batman.Binding.Array.prototype)
                    this.keysFromValue.push(key);
            }
        },
        
        // remove all keys added by introspecting the value
        removeKeysForValue: function() {
            var keys = this.keysFromValue,
                i = keys.length;
            
            while (i--) {
                var key = keys[i];
                this[key] = null;
                delete this[key];
            }
            
            this.keysFromValue = [];
            return this;
        }
    };
    
    Batman.Binding.Array = Batman.Mixin({
        remove: function(index) {
            this.splice(index, 1);
        },
        
        removeObject: function(object) {
            this.remove(this.value.indexOf(object));
        },
        
        removeAll: function() {
            this([]);
        }
    });
    
    // Events
    
    Batman.event = function(func, fireOnce) {
        var emitter = Batman.Binding(function() {
            emitter.fire(typeof func === 'function' ? func.apply(this, arguments) : null);
        });
        
        emitter.isEvent = true;
        emitter.identifier = 'event';
        
        emitter.configure = function(object, key) {
            delete this._configureOnMixin;
            
            this.context = object;
            this.identifier = 'event: ' + key;
            
            object['on' + key.toLowerCase()] = this.on.bind(this);
            
            return this;
        };
        
        if (fireOnce) {
            emitter.fired = false;
            
            emitter.fire = function() {
                if (emitter.fired)
                    return;
                
                emitter.fired = true;
                Batman.Binding.prototype.fire.apply(emitter, arguments);
            };
            
            emitter.observe = function(func) {
                var args = Array.toArray(arguments);
                emitter.fired && args.push(true);
                
                Batman.Binding.prototype.observe.apply(emitter, args);
            };
        }
        
        return emitter;
    };
    
    // Globals
    
    if (typeof window.require === 'undefined')
        window.require = require;
    
    if (typeof $mixin === 'undefined')
        $mixin = Batman.mixin;
    
    if (typeof $unmixin === 'undefined')
        $unmixin = Batman.unmixin;
    
    if (typeof $binding === 'undefined')
        $binding = Batman.binding;
    
    if (typeof $event === 'undefined')
        $event = Batman.event;
    
    Batman.mixin(Batman, {ready: Batman.event(null, true)});
    Batman.require('batman.mvc.js', Batman.ready);
    
})();

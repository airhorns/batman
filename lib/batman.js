/* 
 * batman.js
 * 
 * Batman
 * Copyright Shopify, 2011
 */

if (!exports)
    var exports = {};

(function() {
    
    // Require
    
    if (typeof require === 'undefined') {
        /*! $script.js v1.2
            https://github.com/polvero/script.js
            Copyright: @ded & @fat - Dustin Diaz, Jacob Thornton 2011
            License: CC Attribution: http://creativecommons.org/licenses/by/3.0/
        */
        !function(a,b,c){function u(a){h.test(b[n])?c(function(){u(a)},50):a()}var d=b.getElementsByTagName("script")[0],e={},f={},g={},h=/in/,i={},j="string",k=!1,l="push",m="DOMContentLoaded",n="readyState",o="addEventListener",p="onreadystatechange",q=function(){return Array.every||function(a,b){for(var c=0,d=a.length;c<d;++c)if(!b(a[c],c,a))return 0;return 1}}(),r=function(a,b){q(a,function(c,d){return!b(c,d,a)})};!b[n]&&b[o]&&(b[o](m,function s(){b.removeEventListener(m,s,k),b[n]="complete"},k),b[n]="loading");var t=function(a,j,k){a=a[l]?a:[a];var m=j.call,o=m?j:k,s=m?a.join(""):j,u=a.length,v=function(a){return a.call?a():e[a]},w=function(){if(!--u){e[s]=1,o&&o();for(var a in g)q(a.split("|"),v)&&!r(g[a],v)&&(g[a]=[])}};if(!f[s]){c(function(){r(a,function(a){if(!i[a]){i[a]=f[s]=1;var c=b.createElement("script"),e=0;c.onload=c[p]=function(){c[n]&&!!h.test(c[n])||e||(c.onload=c[p]=null,e=1,w())},c.async=1,c.src=a,d.parentNode.insertBefore(c,d)}})},0);return t}};t.ready=function(a,b,c){a=a[l]?a:[a];var d=[];!r(a,function(a){e[a]||d[l](a)})&&q(a,function(a){return e[a]})?b():!function(a){g[a]=g[a]||[],g[a][l](b),c&&c(d)}(a.join("|"));return t},a.$script=t}(this,document,setTimeout)
        require = $script;
        
        var scripts = document.getElementsByTagName('script');
        for (var i = -1, count = scripts.length; ++i < count;) {
            var src = scripts[i].src,
                index = src && src.indexOf('batman.js');
            
            if (index && index !== -1) {
                Batman.LIB_PATH = src.substr(0, index);
                break;
            }
        }
        
        Batman.LIB_PATH = Batman.LIB_PATH || '';
    }
    else
        Batman.LIB_PATH = './';
    
    var requiredFiles = {};
    
    if (typeof INCLUDED_FILES !== 'undefined') {
        var i = INCLUDED_FILES.length;
        while (i--)
            requiredFiles[INCLUDED_FILES[i]] = {status: 'complete', callbacks: []};
    }
    
    Batman.require = function(files, callback) {
        if (!Array.isArray(files))
            files = [files];
        
        var onload = function() {
            var i = files.length;
            while (i--) {
                var status = requiredFiles[files[i]];
                if (status.status !== 'complete')
                    return;
            }
            
            callback && callback();
        };
        
        for (var i = -1, count = files.length; ++i < count;) {
            var file = files[i],
                status = requiredFiles[file];
            
            if (!status) {
                status = requiredFiles[file] = {status: 'loading', callbacks: [onload]};
                require(file, function(file) {
                    var status = requiredFiles[file];
                    status.status = 'complete';
                    
                    if (typeof module === 'undefined' && typeof exports !== 'undefined') {
                        status.module = exports;
                        globalizeExports();
                    }
                    
                    Batman.execute(status.callbacks);
                }.curry(file));
            }
            else if (status.status === 'loading')
                status.callbacks.push(onload);
            else if (status.status === 'complete')
                onload();
        }
    };
    
    // Utilities
    
    if (!Array.isArray)
        Array.isArray = function(object) { return Object.prototype.toString.call(object) === '[object Array]'; };
    
    if (!Array.toArray)
        Array.toArray = function(object) { return Array.prototype.slice.call(object); };
    
    if (!Array.indexOf)
        Array.indexOf = function(array, object) {
            if (!array)
                return -1;
            
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
    
    Batman.execute = function(func) {
        if (!func)
            return;
        
        var args = Array.toArray(arguments).splice(1),
            result;
        
        if (Array.isArray(func))
            for (var i = -1, count = func.length; ++i < count;)
                result = func[i].apply(this, args);
        else
            result = func.apply(this, args);
        
        return result;
    };
    
    // Mixins
    
    function Batman() {
        return Batman.mixin({}, Array.toArray(arguments));
    };
    
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
            
            else if (typeof arg === 'object') {
                var bindingsToSet = {};
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
                        bindingsToSet[key] = value;
                    else
                        to[key] = value;
                }
                
                for (var key in bindingsToSet)
                    to[key](bindingsToSet[key]);
            }
        }
        
        return to;
    };
    
    Batman.unmixin = function(from) {
        if (!from)
            return;
        
        for (var i = 0, count = arguments.length; ++i < count;) {
            var arg = arguments[i];
            if (!arg)
                continue;
            
            if (arg.isMixin && arg.prototype)
                arg.removeFrom(from);
            
            else if (Array.isArray(arg)) {
                var array = Array.toArray(arg);
                array.unshift(from);
                
                Batman.unmixin.apply(Batman, array);
            }
            
            else if (typeof arg === 'object') {
                for (var key in arg) {
                    from[key] = null;
                    delete from[key];
                }
            }
        }
        
        return from;
    };
    
    // Batman.Mixin
    
    Batman.mixins = {};
    
    // Global constructor
    var initializeMixin = function(mixin, identifier, args) {
        Batman.mixin(mixin, Batman.Mixin.prototype, {prototype: {}});
        mixin.enhance.apply(mixin, args);
        
        if (typeof identifier === 'string') {
            mixin.isMixin = identifier;
            Batman.mixins[identifier] = mixin;
        }
        
        return mixin;
    };
    
    Batman.Mixin = function(identifier) {
        
        // Instance constructor
        var constructor = function() {
            return constructor.create.apply(constructor, arguments);
        };
        
        return initializeMixin(constructor, identifier, Array.toArray(arguments));
    };
    
    Batman.Mixin.Abstract = function(identifier) {
        var mixin = initializeMixin({}, identifier, Array.toArray(arguments));
        return Batman.unmixin(mixin, {create: null});
    };
    
    Batman.Mixin.Singleton = function(identifier) {
        var mixin = initializeMixin({}, identifier, Array.toArray(arguments));
        
        var key = 'shared';
        if (typeof identifier === 'string')
            key += identifier.substr(0,1).toUpperCase() + identifier.substr(1);
        
        mixin[key] = mixin.create();
        
        return Batman.unmixin(mixin, {create: null});
    };
    
    Batman.Mixin.prototype = {
        isMixin: true,
        
        // mixin properties to the prototype
        enhance: function() {
            Batman.mixin(this.prototype, Array.toArray(arguments));
            
            for (var key in this.prototype) {
                var value = this.prototype[key];
                if (value && ((!value.isMixin && typeof value.copy === 'function') || Array.isArray(value)))
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
            Batman.execute.call(this, this.onapply, to); // FIXME: Should this just be an event?
            
            return this;
        },
        
        removeFrom: function(from) {
            Batman.unmixin(from, this.prototype);
            Batman.execute.call(this, this.onremove, from);
            
            return this;
        },
        
        // mixin properties to the Mixin object itself
        mixin: function() {
            return Batman.mixin(this, Array.toArray(arguments));
        },
        
        // returns a hash of functions that simply point to this prototype
        inherit: function(keys) {
            if (arguments.length > 1)
                keys = Array.toArray(arguments);
            else if (!Array.isArray(keys))
                keys = [keys];
            
            var result = {},
                i = keys.length;
            
            while (i--) {
                var key = keys[i];
                result[key] = inheritPrototypeMethod(this.prototype, key);
            }
            
            return result;
        },
        
        copy: function() {
            var copy = Batman.Mixin(this.prototype, Array.toArray(arguments)),
                obj = this.toObject();
            
            Batman.unmixin(obj, {prototype: null, isMixin: null});
            
            return copy.mixin(obj);
        },
        
        toObject: function() {
            var obj = {prototype: this.prototype};
            
            for (var key in this)
                obj[key] = this[key];
            
            return obj;
        },
        
        toString: function() {
            var string = 'mixin';
            return typeof this.isMixin === 'string' ? string + ': ' + this.isMixin : string;
        }
    };
    
    var inheritPrototypeMethod = function(prototype, key) {
        return function() {
            return prototype[key].apply(this, arguments);
        };
    };
    
    // Bindings
    
    Batman.binding = function(defaultValueOrGetter, setter) {
        var binding = function(value) {
            if (arguments.length > 0) {
                var oldValue = binding.value;
                if (oldValue === value)
                    return; // if you want to force everything to refire, just set binding.value to null before you set the binding
                
                binding.value = binding.performValidation(value, oldValue);
                
                if (binding.set)
                    binding.value = binding.set.apply(binding.context || binding, arguments);
                
                value = binding.value;
                binding.valueDidChange(oldValue, value);
                binding.fire(value);
            } else {
                var evalBinding = Batman.Binding._eval;
                if (evalBinding && evalBinding !== binding) {
                    evalBinding.observes(binding);
                    return binding.value
                }
                
                if (binding.get)
                    binding.value = binding.get.apply(binding.context || binding, arguments);
            }
            
            return binding.value;
        };
        
        Batman.Binding.applyTo(binding);
        
        if (typeof defaultValueOrGetter === 'function') {
            binding.get = defaultValueOrGetter;
            binding.set = setter || defaultValueOrGetter;
            
            binding._needsToObserveDependencies = true;
        }
        
        else if (typeof setter === 'function')
            binding.set = setter;
        
        else
            binding(defaultValueOrGetter);
        
        return binding;
    };
    
    Batman.Binding = Batman.Mixin({
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
            if (!this._observers)
                this._observers = [];
            
            if (Array.indexOf(this._observers, func) === -1)
                this._observers.push(func);
            
            if (fireImmediately)
                func.call(this.context || Batman, this.value);
            
            return this;
        },
        
        observeLater: function(func) {
            setTimeout(this.observe.bind(this).curry(func), 0);
            return this;
        },
        
        // observes this binding and all copies
        observeForever: function(func, fireImmediately) {
            func._observeForever = true;
            return this.observe.apply(this, arguments);
        },
        
        observeDeferred: function(func) {
            func._observeDeferred = true;
            return this.observeForever(func);
        },
        
        // remove your function as an observer (must be the same function pointer)
        forget: function(func) {
            var index = Array.indexOf(this._observers, func);
            if (index !== -1)
                this._observers.splice(index, 1);
            
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
            if (this.preventCount > 0)
                return false;
            
            if (this.isBinding && arguments.length < 1)
                value = this();
            
            var context = this.context || Batman,
                observers = this._observers || [],
                args = Array.toArray(arguments);
            
            args[0] = value;
            args.push(context);
            
            for (var i = -1, count = observers.length; ++i < count;) {
                var observer = observers[i];
                if (observer.isBinding)
                    observer.fire();
                else
                    observer.apply(context, args);
            }
            
            return this;
        },
        
        prevent: function() {
            if (typeof this.preventCount === 'undefined')
                this.preventCount = 0;
            
            this.preventCount++;
            return this;
        },
        
        allow: function() {
            if (this.preventCount > 0)
                this.preventCount--;
            
            return this;
        },
        
        allowed: function() {
            return (this.preventCount || 0) == 0;
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
            return this;
        },
        
        // manually add a dependent binding. whenever that binding changes, this binding will fire
        observes: function(binding) {
            if (!this._dependencies)
                this._dependencies = [];
            
            if (Array.indexOf(binding) === -1)
                this._dependencies.push(binding);
            
            binding.observe(this);
            return this;
        },
        
        toString: function() {
            return "binding: " + (this.identifier || (this.value && this.value.toString ? this.value.toString() : Object.prototype.toString.call(this.value)) || 'empty binding');
        },
        
        toObject: function() {
            var obj = {};
            
            for (var key in this)
                obj[key] = this[key];
            
            return obj;
        },
        
        copy: function() {
            var binding = Batman.binding(this.get, this.set);
            if (this.mixinPrototype)
                binding.mixinPrototype = this.mixinPrototype;
            
            if (this._needsToObserveDependencies)
                binding._needsToObserveDependencies = this._needsToObserveDependencies;
            
            if (this._validators)
                binding._validators = Array.toArray(this._validators);
            
            if (this._observers) {
                var newObservers = [],
                    deferredObservers = [],
                    observers = this._observers;
                
                for (var i = -1, count = observers.length; ++i < count;) {
                    var observer = observers[i];
                    if (observer._observeDeferred)
                        deferredObservers.push(observer);
                    
                    else if (observer._observeForever)
                        newObservers.push(observer);
                }
                
                if (deferredObservers.length) {
                    setTimeout(function() {
                        for (var i = -1, count = deferredObservers.length; ++i < count;)
                            newObservers.push(deferredObservers[i]);
                    }, 0);
                }
                
                (newObservers.length || deferredObservers.length) && (binding._observers = newObservers);
            }
            
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
            
            if (value === oldValue)
                return this;
            
            if (!this._keysFromValue)
                this._keysFromValue = [];
            
            if (Array.isArray(value)) {
                if (Array.isArray(oldValue))
                    return this;
                
                this.removeKeysForValue();
                
                var arrayMethod = function(method) {
                    var binding = this; // just to eek out a tiny bit of performance
                    return function() {
                        var result = method.apply(value, arguments);
                        binding.count.fire();
                        binding.fire(value);
                        
                        return result;
                    };
                };
                
                var methods;
                if (Object.getOwnPropertyNames)
                    methods = Object.getOwnPropertyNames(Array.prototype);
                else
                    methods = ['push', 'pop', 'shift', 'unshift', 'splice', 'slice', 'reverse', 'sort', 'concat', 'join'];
                
                var i = methods.length;
                while (i--) {
                    var methodName = methods[i],
                        method = Array.prototype[methodName];
                    
                    if (this[methodName] || typeof method !== 'function' || Array.indexOf(['constructor', 'toString'], methodName) !== -1)
                        continue;
                    
                    this[methodName] = arrayMethod.call(this, method);
                    this._keysFromValue.push(methodName);
                }
                
                this.count = Batman.binding(function() {
                    return this().length;
                }.bind(this));
                
                this._keysFromValue.push('count');
                
                Batman.Binding.Array.applyTo(this);
                for (var key in Batman.Binding.Array.prototype)
                    this._keysFromValue.push(key);
            }
            
            return this;
        },
        
        // remove all keys added by introspecting the value
        removeKeysForValue: function() {
            if (!this._keysFromValue)
                return;
            
            var keys = this._keysFromValue,
                i = keys.length;
            
            while (i--) {
                var key = keys[i];
                this[key] = null;
                delete this[key];
            }
            
            this._keysFromValue = [];
            return this;
        },
        
        validate: function(func, validateImmediately) {
            if (!this._validators)
                this._validators = [];
            
            if (Array.indexOf(this._validators, func) === -1)
                this._validators.push(func);
            
            if (validateImmediately) {
                var value = func.call(this.context, this.value);
                if (value !== this.value)
                    this(value);
            }
            
            return this;
        },
        
        forgetValidator: function(func) {
            var index = Array.indexOf(this._validators, func);
            if (index !== -1)
                this._validators.splice(index, 1);
            
            return this;
        },
        
        performValidation: function(value, oldValue) {
            if (!this._validators)
                return value;
            
            if (arguments.length < 2)
                oldValue = this.value;
            
            if (this._validators && this._validators.length)
                return Batman.execute.call(this.context, this._validators, value, oldValue);
            
            return value;
        }
    });
    
    Batman.Binding.Array = Batman.Mixin({
        item: function(index) {
            return this()[index];
        },
        
        remove: function(index) {
            this.splice(index, 1);
        },
        
        removeObject: function(object) {
            this.remove(Array.indexOf(this.value, object));
        },
        
        removeAll: function() {
            this([]);
        }
    });
    
    // Transactions
    
    Batman.transaction = function(object, options___) {
        var t = Batman.Transaction({_target: object});
        for (var key in object) {
            var value = object[key];
            t[key] = (value && value.isBinding) ? value() : value;
        }
        
        return t;
    };
    
    Batman.change = function(object, options___) {
        var t = Batman.transaction.apply(Batman, arguments);
        setTimeout(function() {
            t.commit();
        }, 0);
        
        return t;
    };
    
    Batman.Transaction = Batman.Mixin({
        isTransaction: true,
        
        commit: function() {
            var obj = {};
            
            for (var key in this) {
                if (key === "_target")
                    continue;
                
                var value = this[key];
                if (value == Batman.Transaction.prototype[key])
                    continue;
                
                obj[key] = value;
            }
            
            Batman.mixin(this._target, obj);
        }
    });
    
    // Batman.Event
    
    Batman.event = function(func, fireOnce) {
        var handler = function(observer) {
            if (typeof observer === 'function') {
                handler.observe.apply(handler, arguments);
                return handler.context || handler;
            }
            
            return handler.dispatch.apply(handler, arguments);
        };
        
        handler._func = func;
        
        return Batman.mixin(handler, fireOnce ? Batman.EventOneShot : Batman.Event);
    };
    
    Batman.Event = Batman.Mixin({
        isEvent: true,
        _configureOnMixin: true,
        
        dispatch: function() {
            var result = typeof this._func === 'function' ? this._func.apply(this.context || this, arguments) : void 0;
            if (result !== false) {
                var args = Array.toArray(arguments);
                if (typeof result !== 'undefined')
                    args.unshift(result);
                
                this.fire.apply(this, args);
            }
            
            return this.context || this;
        },
        
        copy: function() {
            var handler = Batman.event(this._func, this.isOneShot);
            if (this.mixinPrototype)
                handler.mixinPrototype = this.mixinPrototype;
            
            if (this._observers) {
                var newObservers = [],
                    observers = this._observers;
                
                for (var i = -1, count = observers.length; ++i < count;) {
                    var observer = observers[i];
                    if (observer._observeForever)
                        newObservers.push(observer);
                }
                
                newObservers.length && (handler._observers = newObservers);
            }
            
            return handler;
        },
        
        toString: function() {
            return 'event';
        }
    }, Batman.Binding.inherit('fire', 'observe', 'forget', 'observeForever', 'configure', 'allow', 'prevent', 'allowed', 'toObject'));
    
    Batman.EventOneShot = Batman.Mixin(Batman.Event, {
        isOneShot: true,
        hasFired: false,
        
        observe: function(observer) {
            if (this.hasFired)
                return observer.call(this.context || Batman, this.value);
            
            return Batman.Binding.prototype.observe.apply(this, arguments);
        },
        
        fire: function() {
            if (this.hasFired)
                return;
            
            this.hasFired = true;
            return Batman.Binding.prototype.fire.apply(this, arguments);
        }
    });
    
    // Batman.Promise
    
    Batman.Promise = Batman.Mixin({
        isPromise: true,
        
        done: Batman.event(),
        fail: Batman.event(),
        
        then: function(done, fail) {
            if (done)
                this.done.apply(this, done);
            
            if (fail)
                this.fail.apply(this, fail);
        }
    });
    
    Batman.when = function() {
        var promise = Batman.Promise(),
            args = Array.toArray(arguments);
            
        
        for (var i = -1, count = args.length; ++i < count;) {
            var arg = args[i];
            if (arg.isPromise)
                arg.done(function() {
                    var i = args.length;
                    while (i--) {
                        
                    }
                });
            else {
                
            }
        }
        
        return promise;
    };
    
    // Batman.Request
    
    Batman.Request = Batman.Mixin({
        isRequest: true,
        
        url: Batman.binding('').observeForever(function(url) {
            if (url) {
                this.isLocal(window.location.protocol === 'file:' && url.indexOf('http:') === -1);
                this.sendLater();
            }
        }),
        isLocal: Batman.binding(false),
        
        method: Batman.binding('get').observeForever(function(method) {
            if (method.toLowerCase() !== 'get' && !this.contentType())
                this.contentType('application/json');
        }),
        
        headers: {},
        contentType: Batman.binding(''),
        accept: Batman.binding('application/json'),
        
        body: Batman.binding('').observeForever(function(body) {
            if (!body)
                return;
            
            if (this.method().toLowerCase() === 'get')
                this.method('post');
        }),
        
        data: Batman.binding(''),
        
        success: Batman.event(function() {
            this.done();
        }),
        
        error: Batman.event(function() {
            this.fail();
        }),
        
        complete: Batman.event(),
        
        send: Batman.event(function() {
            if (this._request || this._timeout)
                this.cancel();
            
            if (!this.url())
                return false;
            
            var request = window.XMLHttpRequest && (window.location.protocol !== "file:" || !window.ActiveXObject) ? new XMLHttpRequest() : new window.ActiveXObject("Microsoft.XMLHTTP");
            request.onreadystatechange = function() {
                if (request.cancelled || request.readyState != 4)
                    return;
                
                this.complete(request);
                
                if (window.location.protocol === "file:" || request.statusCode == 200)
                    this.success(request);
                else
                    this.error(request);
            }.bind(this);
            
            request.open(this.method().toUpperCase(), this.url());
            
            if (!this.isLocal()) {
                var headers = this.headers,
                    contentType = this.contentType(),
                    accept = this.accept(),
                    requestHeaders = {};
                
                if (contentType)
                    requestHeaders['Content-type'] = contentType;
                
                if (accept)
                    requestHeaders['Accept'] = accept;
                
                for (var key in headers)
                    requestHeaders[key] = headers[key];
                
                for (var key in requestHeaders)
                    request.setRequestHeader(key, requestHeaders[key]);
            }
            
            var body = this.body();
            if (typeof body === 'object')
                body = JSON.stringify(body);
            
            request.send(body || null);
            
            return this;
        }),
        
        sendLater: function() {
            if (this._timeout)
                clearTimeout(this._timeout);
            
            this._timeout = setTimeout(this.send.bind(this), 0);
            return this;
        },
        
        cancel: function() {
            if (this._timeout)
                this._timeout = clearTimeout(this._timeout);
            
            if (this._request) {
                this._request.cancelled = true;
                this._request = null;
            }
            
            return this;
        }
    }, Batman.Promise).mixin({
        create: function(url, method) {
            var args = Array.toArray(arguments);
            
            if (typeof url === 'string') {
                var option = {url: url};
                if (typeof method === 'string')
                    option.method = method;
                
                args.unshift(option);
            }
            
            return Batman.Mixin.prototype.create.apply(Batman.Request, args);
        }
    });
    
    // Transactions
    
    Batman.transaction = function(object) {
        var t = Batman.Transaction({_target: object});
        
        for (var i = 0, count = arguments.length; ++i < count;)
            Batman.mixin(t, arguments[i]);
        
        return t;
    };
    
    // automatically commits a transaction at the end of the run loop
    Batman.change = function(object) {
        var t = Batman.transaction.apply(Batman, arguments);
        
        t._timeout = setTimeout(function() {
            t.commit();
        }, 0);
        
        return t;
    };
    
    Batman.Transaction = Batman.Mixin({
        _target: null,
        isTransaction: true,
        
        commit: function() {
            var target = this._target;
            Batman.Transaction.removeFrom(this);
            
            return Batman.mixin(target, this);
        }
    });
    
    Batman.Transactionable = Batman.Mixin.Abstract({
        transaction: function() {
            var args = Array.toArray(arguments);
            args.unshift(this);
            
            return Batman.transaction.apply(Batman, args);
        },
        
        change: function() {
            var args = Array.toArray(arguments);
            args.unshift(this);
            
            return Batman.change.apply(Batman, args);
        }
    });
    
    // String Parsing
    
    Batman.functionFromString = function(string, contexts) {
        contexts = contexts || [];
        contexts = Array.toArray(contexts);
        
        var withStart = [],
            withEnd = [];
        
        for (var i = -1, count = contexts.length; ++i < count;) {
            withStart.push('with(contexts[' + i + ']){');
            withEnd.push('}');
        }
        
        var f = new Function('contexts', withStart.join('') + 'return ' + string + withEnd.join(''));
        return function() { return f.call(contexts[contexts.length - 1], contexts); };
    };
    
    Batman.bindingFromString = function(string, contexts) {
        var f = Batman.functionFromString(string, contexts),
            binding = f();
        
        if (!binding || !binding.isBinding) {
            binding = Batman.binding(f);
            binding.observeDependencies();
        }
        
        return binding;
    };
    
    Batman.hashFromString = function(string, contexts) {
        return Batman.functionFromString('{' + string + '}', contexts)();
    };
    
    Batman.arrayFromString = function(string, contexts) {
        return Batman.functionFromString('[' + string + ']', contexts)();
    };
    
    // Globals
    exports.Batman = Batman;
    
    exports.$mixin = Batman.mixin;
    exports.$binding = Batman.binding;
    exports.$event = Batman.event;
    
    var globalizeExports = function() {
        for (var key in exports)
            if (typeof this[key] === 'undefined')
                this[key] = exports[key];
    };
    
    globalizeExports();
    
    // Bootstrap
    
    Batman.mixin(Batman, {ready: Batman.event(null, true)});
    Batman.require([Batman.LIB_PATH + 'batman.mvc.js', Batman.LIB_PATH + 'batman.store.js'], Batman.ready);
    
})();

/* 
 * batman.js
 * 
 * Batman
 * Copyright Shopify, 2011
 */

(function() {
    
    /* load.js
     * http://github.com/chriso/load.js
     * Copyright (c) 2010 Chris O'Hara <cohara87@gmail.com>. MIT Licensed */
    function loadScript(a,b,c){var d=document.createElement("script");d.type="text/javascript",d.src=a,d.onload=b,d.onerror=c,d.onreadystatechange=function(){var a=this.readyState;if(a==="loaded"||a==="complete")d.onreadystatechange=null,b()},head.insertBefore(d,head.firstChild)}(function(a){a=a||{};var b={},c,d;c=function(a,d,e){var f=a.halt=!1;a.error=function(a){throw a},a.next=function(c){c&&(f=!1);if(!a.halt&&d&&d.length){var e=d.shift(),g=e.shift();f=!0;try{b[g].apply(a,[e,e.length,g])}catch(h){a.error(h)}}return a};for(var g in b){if(typeof a[g]==="function")continue;(function(b){a[b]=function(){var e=Array.prototype.slice.call(arguments);e.unshift(b);if(!d)return c({},[e],b);a.then=a[b],d.push(e);return f?a:a.next()}})(g)}e&&(a.then=a[e]),a.call=function(b,c){c.unshift(b),d.unshift(c),a.next(!0)};return a.next()},d=a.addMethod=function(d){var e=Array.prototype.slice.call(arguments),f=e.pop();for(var g=0,h=e.length;g<h;g++)typeof e[g]==="string"&&(b[e[g]]=f);--h||(b["then"+d[0].toUpperCase()+d.substr(1)]=f),c(a)},d("run",function(a,b){var c=this,d=function(){c.halt||(--b||c.next(!0))};for(var e=0,f=b;!c.halt&&e<f;e++)null!=a[e].call(c,d,c.error)&&d()}),d("defer",function(a){var b=this;setTimeout(function(){b.next(!0)},a.shift())}),d("onError",function(a,b){var c=this;this.error=function(d){c.halt=!0;for(var e=0;e<b;e++)a[e].call(c,d)},this.next(!0)})})(this),addMethod("load",function(a,b){for(var c=[],d=0;d<b;d++)(function(b){c.push(function(c,d){loadScript(a[b],c,d)})})(d);this.call("run",c)});var head=document.getElementsByTagName("head")[0]||document.documentElement;
    
    // Batman.require
    
    var require = function(files, extensionOrCallback, callback) {
        if (!Array.isArray(files))
            files = [files];
        
        var extension = '.' + (typeof extensionOrCallback === 'string' ? extensionOrCallback : 'js');
        typeof extensionOrCallback === 'function' && (callback = extensionOrCallback);
        
        var i = files.length;
        while (i--) {
            var file = files[i];
            if (require.files[file])
                files[i] = null;
            else if (file.substr(file.length - extension.length) === extension)
                files[i] = BATMAN_BASE_URL + file;
            else
                files[i] = (require.base || '') + file + extension;
        }
        
        var chain = load.apply(load, files);
        callback && chain.thenRun(function() { callback(); });
        
        return chain;
    };
    require.files = {};
    
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
    
    Batman = function() {
        return Batman.mixin({}, Array.toArray(arguments));
    };
    
    Batman.require = require;
    
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
                if (value && (typeof value.copy === 'function' || Array.isArray(value)))
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
        
        toObject: function() {
            var obj = {prototype: this.prototype};
            
            for (var key in this)
                obj[key] = this[key];
            
            return obj;
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
                    binding.set.apply(binding.context || binding, arguments);
                
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
        } else
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
        
        // observes this binding and all copies
        observeForever: function(func, fireImmediately) {
            func._observeForever = true;
            return this.observe.apply(this, arguments);
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
                    observers = this._observers;
                
                for (var i = -1, count = observers.length; ++i < count;) {
                    var observer = observers[i];
                    if (observer._observeForever)
                        newObservers.push(observer);
                }
                
                newObservers.length && (binding._observers = newObservers);
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
            var result = typeof this._func === 'function' ? this._func.apply(this.context || this, arguments) : void 0,
                args = Array.toArray(arguments);
            
            if (typeof result !== 'undefined')
                args.unshift(result);
            
            this.fire.apply(this, args);
            
            return this;
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
                
                for (var key in requestHeaders) {
                    console.log(request.setRequestHeader)
                    request.setRequestHeader(key, requestHeaders[key]);
                }
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
    }
    
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
    
    if (typeof window.require === 'undefined')
        window.require = require;
    
    if (typeof $mixin === 'undefined')
        $mixin = Batman.mixin;
    
    if (typeof $binding === 'undefined')
        $binding = Batman.binding;
    
    if (typeof $event === 'undefined')
        $event = Batman.event;
    
    Batman.mixin(Batman, {ready: Batman.event(null, true)});
    Batman.require('batman.mvc.js', Batman.ready);
    
})();

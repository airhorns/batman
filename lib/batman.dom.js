(function() {
    
    Batman.DOM = {
        bind: {
            attribute: function(bindingName, node, attribute, context) {
                var binding = Batman.getBindingFromString(bindingName, context);
                if (!binding)
                    return;
                
                if (!node._setAttribute) {
                    var bindings = {};
                    
                    node._setAttribute = node.setAttribute;
                    node.setAttribute = function(name, value) { this._setAttribute(name, value); bindings[name] && bindings[name](value); };
                    
                    node._removeAttribute = node.removeAttribute;
                    node.removeAttribute = function(name) { this._removeAttribute(name); bindings[name] && bindings[name](null); }
                }
                
                bindings[attribute] = binding;
                binding.observe(function(value) {
                    if (!value)
                        node.removeAttribute(attribute);
                    else
                        node.setAttribute(attribute, value);
                }, true);
            },
            
            value: function(bindingName, node, context) {
                var binding = Batman.getBindingFromString(bindingName, context);
                if (!binding)
                    return;
                
                binding.observe(function(value) { Batman.DOM.valueForNode(node, value); }, true);
                Batman.DOM.observeNode(node, 'change', function(value) { binding(value); });
            },
            
            visible: function(bindingName, node, context) {
                var binding = Batman.getBindingFromString(bindingName, context, node);
                if (!binding)
                    return;
                
                binding.observe(function(value) {
                    if (typeof node.show === 'function')
                        value ? node.show('fast') : node.hide('fast');
                    else
                        node.style.display = value ? 'block' : 'none';
                }, true);
            },
            
            each: function(bindingName, node, context) {
                var binding = Batman.getBindingFromString(bindingName, context);
                if (!binding)
                    return;
                
                var prototype = node.cloneNode(true);
                prototype.removeAttribute('data-each');
                
                var placeholder = document.createElement('span');
                placeholder.style.display = 'none';
                node.parentNode.replaceChild(placeholder, node);
                
                var existingNodes = [];
                
                binding.observe(function(array) {
                    var i = existingNodes.length;
                    while (i--) {
                        var oldNode = existingNodes[i];
                        Batman.DOM.unbindNode(oldNode);
                        
                        oldNode.parentNode.removeChild(oldNode);
                    }
                    
                    existingNodes = [];
                    
                    var binder = function(node, context) {
                        return function() {
                            Batman.DOM.bindNode(node, context);
                        };
                    };
                    
                    for (var i = -1, count = array.length; ++i < count;) {
                        var newNode = prototype.cloneNode(true);
                        existingNodes.push(newNode);
                        
                        placeholder.parentNode.insertBefore(newNode, placeholder);
                        setTimeout(binder(newNode, array[i]), 0);
                    }
                }, true);
            },
            
            loc: function(binding, node, context) {
                var value = Batman.DOM.valueForNode(node);
                console.log(value);
            },
            
            events: function(events, node, context) {
                var hash = typeof events === 'string' ? Batman.getHashFromString(events, context, node) : events;
                for (var key in hash)
                    if (typeof hash[key] === 'function')
                        if (key === 'ready')
                            setTimeout(hash[key].bind(node), 0);
                        else
                            Batman.DOM.addEventListener(node, key, hash[key].bind(context));
            },
            
            mixin: function(mixins, node, context) {
                var array = typeof mixins === 'string' ? Batman.getArrayFromString(mixins, context, Batman.mixins) : mixins,
                    i = array.length;
                
                while (i--) {
                    var mixin = array[i];
                    if (mixin && mixin.isMixin)
                        mixin.applyTo(node);
                }
            },
            
            mixinProperties: function(binding, node, mixin, context) {
                var properties = Batman.getHashFromString(binding, node, context),
                    mixin = Batman.getObjectFromString();
                
                // if (mixin && mixin.isMixin)
                    // mixin.applyTo(node, )
            }
        },
        
        bindNode: function(node, context) {
            if (!node)
                return;
            
            if (typeof node === 'string')
                node = document.getElementById(node);
            
            if (typeof node.getAttribute === 'function') {
                var each = node.getAttribute('data-each');
                if (each)
                    return Batman.DOM.bind.each(each, node, context);
                
                var attributes = node.dataAttributes || node.attributes;
                for (var i = -1, count = attributes.length; ++i < count;) {
                    var attribute = attributes[i],
                        name = attribute.nodeName,
                        bindingName = name.substr(0,5) === 'data-' && name.substr(5),
                        bindAttribute = bindingName && bindingName.substr(0,5) === 'bind-' && bindingName.substr(5),
                        bindMixin = bindingName && bindingName.substr(0,6) === 'mixin-' && bindingName.substr(6),
                        binding = bindingName && attribute.value;
                    
                    if (bindAttribute)
                        Batman.DOM.bind.attribute(binding, node, bindAttribute, context);
                    else if (bindMixin)
                        Batman.DOM.bind.mixinProperties(binding, node, bindMixin, context);
                    else if (Batman.DOM.bind[bindingName])
                        Batman.DOM.bind[bindingName](binding, node, context);
                }
            }
            
            var children = node.childNodes;
            for (var i = -1, count = children.length; ++i < count;)
                Batman.DOM.bindNode(children[i], context);
        },
        
        unbindNode: function() {
            // FIXME
        },
        
        valueForNode: function(node, value) {
            if (!node || !node.tagName)
                return;
            
            var tagName = node.tagName.toUpperCase(),
                isSetting = arguments.length > 1;
            
            if (tagName === 'INPUT')
                return isSetting ? (node.value = value) : node.value;
            else
                return isSetting ? (node.innerHTML = value) : node.innerHTML;
        },
        
        observeNode: function(node, attr, func) {
            if (!node || !node.tagName)
                return;
            
            var tagName = node.tagName.toUpperCase();
            
            if (attr === 'change') {
                if (tagName === 'INPUT') {
                    var type = node.type.toUpperCase();
                    if (type === 'TEXT')
                        Batman.DOM.addEventListener(node, 'keyup', function(e) { func(node.value); });
                    else if (type === 'CHECKBOX')
                        Batman.DOM.addEventListener(node, 'change', function(e) { func(node.checked); });
                }
            }
        },
        
        addEventListener: function(node, e, func) {
            if (!node || !e || !func)
                return;
            
            if (node.addEventListener)
                node.addEventListener(e, function(e) { func(node, e); e.preventDefault(); });
            else if (node.attachEvent)
                node.attachEvent('on' + e, function(e) { func(node, e); e.preventDefault(); });
        }
    };
    
    Batman.Animation = Batman.Mixin('animation', {
        animatable: true
    }).mixin({
        applyTo: function(node) {
            require('jquery.js', function() {
                var jq = $(node),
                    jqueryMethod = function(method) {
                        node[method] = function() {
                            jq[method].apply(jq, arguments);
                            return node;
                        };
                    };
                
                var methods = ['show', 'hide', '_toggle', 'toggle', 'fadeTo', 'animate', 'stop', 'slideDown', 'slideUp', 'slideToggle', 'fadeIn', 'fadeOut', 'speed', 'easing', 'timers', 'fx'],
                    i = methods.length;
                
                while (i--)
                    jqueryMethod(methods[i]);
            });
            
            Batman.Mixin.prototype.applyTo.apply(this, arguments);
        }
    });
    
})();

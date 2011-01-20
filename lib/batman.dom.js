(function() {
    
    Batman.DOM = {
        view: function(view) {
            var node = view.node,
                contexts = [Batman.View.helpers, view, {view: view}];
            
            if (view.context)
                contexts.push(view.context);
            
            Batman.DOM.node(node, contexts);
        },
        
        node: function(node, contexts) {
            if (typeof node === 'string')
                node = document.getElementById(node);
            
            if (!node)
                return;
            
            contexts = contexts || [];
            
            var result;
            if (typeof node.getAttribute === 'function') {
                contexts.push({node: node}, node);
                
                var attributes = Array.toArray(node.attributes);
                for (var i = -1, count = attributes.length; ++i < count;) {
                    var attribute = attributes[i],
                        attributeName = attribute.nodeName,
                        attributeValue = attribute.nodeValue;
                    
                    if (attributeName.substr(0,5) !== 'data-')
                        continue;
                    
                    var binding = attributeName.substr(5);
                    if (binding.substr(0,5) === 'bind-')
                        result = Batman.DOM.bindAttribute(binding.substr(5), attributeValue, node, contexts);
                    
                    else if (binding.substr(0,5) === 'each-')
                        result = Batman.DOM.bindEach(binding.substr(5), attributeValue, node, contexts);
                    
                    else if (binding.substr(0,6) === 'mixin-')
                        result = Batman.DOM.bindMixin(binding.substr(6), attributeValue, node, contexts);
                    
                    else if (Batman.DOM.bindings[binding])
                        result = Batman.DOM.bindings[binding](attributeValue, node, contexts);
                    
                    else
                        continue;
                    
                    node.removeAttribute(attributeName);
                    
                    if (result === false)
                        break;
                }
                
                contexts.splice(contexts.indexOf(node) - 1);
            }
            
            if (result !== false) {
                var children = node.childNodes;
                for (var i = -1, count = children.length; ++i < count;)
                    Batman.DOM.node(children[i], contexts);
                
                if (node.onBatmanLoad) {
                    var i = node.onBatmanLoad.length;
                    while (i--)
                        node.onBatmanLoad[i].call(node, node);
                }
            }
        },
        
        forgetNode: function(node) {
            
        },
        
        bindings: {
            bind: function(string, node, contexts) {
                var binding = Batman.bindingFromString(string, contexts);
                binding.observe(function(value) { Batman.DOM.valueForNode(node, value); }, true);
                Batman.DOM.onchange(node, function(value) { binding(value); });
            },
            
            visible: function(string, node, contexts) {
                var originalDisplay = node.style.display,
                    binding = Batman.bindingFromString(string, contexts),
                    needsBind = false,
                    children;
                
                binding.observe(function(value) {
                    var visible = !!value;
                    
                    if (visible) {
                        if (children) {
                            for (var i = -1, count = children.length; ++i < count;)
                                node.appendChild(children[i]);
                            
                            children = null;
                        }
                        
                        if (needsBind) {
                            Batman.DOM.node(node, needsBind);
                            needsBind = false;
                        }
                    } else {
                        children = Array.toArray(node.childNodes);
                        node.innerHTML = '';
                    }
                    
                    if (typeof node.show === 'function' && typeof node.hide === 'function')
                        visible ? node.show() : node.hide();
                    else
                        node.style.display = visible ? originalDisplay : 'none';
                }, true);
                
                if (!binding()) {
                    needsBind = Array.toArray(contexts);
                    return false;
                }
            },
            
            events: function(string, node, contexts) {
                var events = Batman.hashFromString(string, contexts);
                for (var key in events)
                    Batman.DOM.events[key](node, events[key]);
            },
            
            mixin: function(string, node, contexts) {
                
            },
            
            view: function(string, node, contexts) {
                
            }
        },
        
        bindEach: function(attribute, string, node, contexts) {
            var binding = Batman.bindingFromString(string, contexts);
            if (!binding)
                return false;
            
            var prototype = node.cloneNode(true);
            prototype.removeAttribute('data-each-' + attribute);
            
            var placeholder = document.createElement('span');
            placeholder.style.display = 'none';
            node.parentNode.replaceChild(placeholder, node);
            
            var existingNodes = [];
            
            contexts = Array.toArray(contexts);
            binding.observe(function(array) {
                var i = existingNodes.length;
                while (i--) {
                    var oldNode = existingNodes[i];
                    Batman.DOM.forgetNode(oldNode);
                    
                    if (typeof oldNode.hide === 'function')
                        oldNode.hide(true);
                    else
                        oldNode.parentNode.removeChild(oldNode);
                }
                
                existingNodes = [];
                
                var values = [];
                for (var i = -1, count = array.length; ++i < count;) {
                    var value = array[i];
                    if (!value)
                        continue;
                    
                    var newNode = prototype.cloneNode(true);
                    existingNodes.push(newNode);
                    values.push(value);
                }
                
                var binder = function(node, value) {
                    var context = {};
                    context[attribute] = value;
                    
                    return function() {
                        if (!node.parentNode)
                            return;
                        
                        contexts.push(context, value);
                        Batman.DOM.node(node, contexts);
                        contexts.splice(contexts.indexOf(context));
                    }
                }
                
                setTimeout(function() {
                    for (var i = -1, count = values.length; ++i < count;) {
                        var node = existingNodes[i],
                            value = values[i];
                        
                        placeholder.parentNode.insertBefore(node, placeholder);
                        if (typeof node.show === 'function')
                            node.show();
                        
                        setTimeout(binder(node, value), 0);
                    }
                }, 0);
            }, true);
            
            return false;
        },
        
        bindAttribute: function(attribute, string, node, contexts) {
            Batman.bindingFromString(string, contexts).observe(function(value) {
                if (value)
                    node.setAttribute(attribute, value);
                else
                    node.removeAttribute(attribute);
            }, true);
        },
        
        bindMixin: function(attribute, string, node, contexts) {
            
        },
        
        events: {
            change: function(node, callback) {
                if (node.nodeName.toUpperCase() === 'INPUT') {
                    var type = node.type.toUpperCase();
                    if (type === 'TEXT')
                        return Batman.DOM.addEventListener(node, 'keyup', function(node, e) { callback(node.value, node, e); });
                }
            },
            
            click: function(node, callback) {
                return Batman.DOM.addEventListener(node, 'click', function(node, e) { callback(node, e); e.preventDefault(); })
            },
            
            load: function(node, callback) {
                if (!node.onBatmanLoad)
                    node.onBatmanLoad = [];
                
                node.onBatmanLoad.push(callback);
            }
        },
        
        addEventListener: function(node, eventName, callback) {
            var func = function(e) { callback(node, e); };
            
            if (node.addEventListener)
                node.addEventListener(eventName, func);
            else
                node.attachEvent('on' + eventName, func);
            
            return func;
        },
        
        valueForNode: function(node) {
            if (!node)
                return;
            
            var isSetting = arguments.length > 1,
                value = arguments[1];
            
            if (node.nodeName.toUpperCase() === 'INPUT') {
                var type = node.type.toUpperCase();
                if (type === 'TEXT')
                    return isSetting ? (node.value = value) : node.value;
            }
            
            return isSetting ? (node.innerHTML = value) : node.innerHTML;
        }
    };
    
    for (var key in Batman.DOM.events)
        Batman.DOM['on' + key] = Batman.DOM.events[key];
    
})();

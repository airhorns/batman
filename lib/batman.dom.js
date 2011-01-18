(function() {
    
    Batman.DOM = {
        view: function(view) {
            var node = view.node,
                contexts = [view, {view: view}];
            
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
            
            if (typeof node.getAttribute === 'function') {
                contexts.push({node: node}, node);
                
                var attributes = node.attributes;
                for (var i = -1, count = attributes.length; ++i < count;) {
                    var attribute = attributes[i],
                        attributeName = attribute.nodeName,
                        attributeValue = attribute.nodeValue;
                    
                    if (attributeName.substr(0,5) !== 'data-')
                        continue;
                    
                    var binding = attributeName.substr(5);
                    
                    if (binding.substr(0,5) === 'bind-')
                        Batman.DOM.bindAttribute(binding.substr(5), attributeValue, node, contexts);
                    
                    else if (binding.substr(0,6) === 'mixin-')
                        Batman.DOM.bindMixin(binding.substr(6), attributeValue, node, contexts);
                    
                    else if (Batman.DOM.bindings[binding])
                        Batman.DOM.bindings[binding](attributeValue, node, contexts);
                }
                
                contexts.splice(contexts.indexOf(node) - 1);
            }
            
            var children = node.childNodes;
            for (var i = 0, count = children.length; ++i < count;)
                Batman.DOM.node(children[i], contexts);
            
            if (node.onBatmanLoad) {
                var i = node.onBatmanLoad.length;
                while (i--)
                    node.onBatmanLoad[i].call(node, node);
            }
        },
        
        bindings: {
            bind: function(string, node, contexts) {
                var binding = Batman.bindingFromString(string, contexts);
                binding.observe(function(value) { Batman.DOM.valueForNode(node, value); }, true);
                Batman.DOM.onchange(node, function(value) { binding(value); });
            },
            
            visible: function(string, node, contexts) {
                Batman.bindingFromString(string, contexts).observe(function(value) {
                    var visible = !!value;
                    if (typeof node.show === 'function' && typeof node.hide === 'function')
                        visible ? node.show() : node.hide();
                    else
                        node.style.display = visible ? 'block' : 'none';
                }, true);
            },
            
            events: function(string, node, contexts) {
                var events = Batman.hashFromString(string, contexts);
                for (var key in events) {
                    var callback = Batman.functionFromString(events[key], contexts)().bind(contexts[0]);
                    Batman.DOM.events[key](node, callback);
                }
            },
            
            mixin: function(string, node, contexts) {
                
            },
            
            view: function(string, node, contexts) {
                
            }
        },
        
        bindAttribute: function(attribute, string, node, contexts) {
            Batman.bindingFromString(string).observe(function(value) {
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

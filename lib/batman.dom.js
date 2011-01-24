(function() {
    
    Batman.DOM = {
        view: function(view) {
            var node = view.node,
                contexts = [Batman.View.helpers, Batman.mixins, view, {view: view}];
            
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
                var binding = node._valueBinding = Batman.bindingFromString(string, contexts);
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
            
            classes: function(string, node, contexts) {
                var classes = Batman.hashFromString(string, contexts);
                for (var key in classes) {
                    var binding = classes[key];
                    binding.observe(function(value) {
                        var current = node.className;
                        if (!!value) {
                            if (current.indexOf(key) === -1)
                                node.className = current + ' ' + key;
                        } else {
                            if (current.indexOf(key) !== -1)
                                node.className = current.replace(key, '');
                        }
                    }, true);
                }
            },
            
            events: function(string, node, contexts) {
                var events = Batman.hashFromString(string, contexts);
                for (var key in events)
                    Batman.DOM.events[key](node, events[key]);
            },
            
            route: function(string, node, contexts) {
                var route = Batman.bindingFromString(string, contexts),
                    nodeName = node.nodeName.toUpperCase();
                
                if (nodeName === 'A') {
                    node.href = '#';
                    Batman.DOM.onclick(node, route);
                }
            },
            
            mixin: function(string, node, contexts) {
                var mixins = Batman.arrayFromString(string, contexts);
                for (var i = -1, count = mixins.length; ++i < count;) {
                    var mixin = mixins[i];
                    if (mixin && mixin.isMixin)
                        mixin.applyTo(node);
                }
            },
            
            view: function(string, node, contexts) {
                
            },
            
            yield: function(string, node) {
                if (!Batman.View._yields)
                    Batman.View._yields = {};
                
                Batman.View._yields[string] = node;
            },
            
            content: function(string, node, contexts) {
                
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
                var nodesToRemove = [];
                for (var i = -1, count = existingNodes.length; ++i < count;) {
                    var oldNode = existingNodes[i];
                    if (Array.indexOf(array, oldNode._eachItem) === -1) {
                        Batman.DOM.forgetNode(oldNode);
                        nodesToRemove.push(i);
                        
                        if (typeof oldNode.hide === 'function')
                            oldNode.hide(true);
                        else
                            oldNode.parentNode.removeChild(oldNode);
                    }
                }
                
                var i = nodesToRemove.length;
                while (i--)
                    existingNodes.splice(nodesToRemove[i], 1);
                
                var binder = function(node, item) {
                    var context = {};
                    context[attribute] = item;
                    
                    var contextsCopy = Array.toArray(contexts);
                    contextsCopy.push(context);
                    
                    return function() {
                        if (node.parentNode) {
                            Batman.DOM.node(node, contextsCopy);
                            
                            if (typeof node.show === 'function') {
                                node.style.display = 'none';
                                node.show();
                            }
                        }
                    };
                };
                
                for (var i = -1, count = array.length; ++i < count;) {
                    var item = array[i];
                    if (!item)
                        continue;
                    
                    var node = existingNodes[i];
                    if (node && node._eachItem === item)
                        continue;
                    
                    var newNode = prototype.cloneNode(true);
                    existingNodes.splice(i, 0, newNode);
                    newNode._eachItem = item;
                }
                
                setTimeout(function() {
                    for (var i = -1, count = existingNodes.length; ++i < count;) {
                        var node = existingNodes[i];
                        if (node.parentNode)
                            continue;
                        
                        var nextNode, j = i + 1;
                        while (!nextNode) {
                            if (existingNodes.length <= j) {
                                nextNode = placeholder;
                                break;
                            }
                            
                            nextNode = existingNodes[j];
                            j++;
                            
                            if (nextNode && !nextNode.parentNode)
                                nextNode = null;
                        }
                        
                        placeholder.parentNode.insertBefore(node, nextNode);
                        setTimeout(binder(node, node._eachItem), 0);
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
                    else if (type === 'CHECKBOX')
                        return Batman.DOM.addEventListener(node, 'change', function(node, e) { callback(node.checked, node, e); });
                }
            },
            
            submit: function(node, callback) {
                if (node.nodeName.toUpperCase() === 'INPUT') {
                    var type = node.type.toUpperCase();
                    if (type === 'TEXT')
                        return Batman.DOM.addEventListener(node, 'keyup', function(node, e) {
                            if (e.keyCode === 13) {
                                callback(node.value, node, e);
                                e.preventDefault();
                            }
                        });
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
                else if (type === 'CHECKBOX')
                    return isSetting ? (node.checked = !!value) : node.checked;
            }
            
            return isSetting ? (node.innerHTML = value) : node.innerHTML;
        }
    };
    
    for (var key in Batman.DOM.events)
        Batman.DOM['on' + key] = Batman.DOM.events[key];
    
    Batman.Animation = Batman.Mixin('animation', {
        show: function() {
            Batman.require('jquery.js', function() {
                if (!jQuery)
                    throw new Error('Batman.Animation requires jQuery');

                $(this).show(500); // FIXME: requires jQuery
            }.bind(this));
        },

        hide: function(remove) {
            Batman.require('jquery.js', function() {
                if (!jQuery)
                    throw new Error('Batman.Animation requires jQuery');

                $(this).hide(500);

                if (remove)
                    setTimeout(function() { this.parentNode.removeChild(this); }.bind(this), 510);
            }.bind(this));
        }
    });

    Batman.Editor = Batman.Mixin('editor', {
        onclick: function(e) {
            return this.startEditing();
        },

        startEditing: function(node, e) {
            if (this._isEditing)
                return;

            if (!this.editor) {
                var editor = this.editor = document.createElement('input');
                editor.type = 'text';
                editor.className = 'editor';

                Batman.DOM.onsubmit(editor, function() {
                    if (this.commit)
                        this.commit();

                    this.stopEditing();
                }.bind(this));
            }

            this._originalDisplay = this.style.display;
            this.style.display = 'none';

            this._isEditing = true;
            this.editor.value = Batman.DOM.valueForNode(this);

            this.parentNode.insertBefore(this.editor, this);
            this.editor.focus();
            this.editor.select();

            return this.editor;
        },

        stopEditing: function() {
            if (!this._isEditing)
                return;

            this.style.display = this._originalDisplay;
            this.editor.parentNode.removeChild(this.editor);

            this._isEditing = false;
        },

        commit: function() {
            this._valueBinding(this.editor.value);
        }
    });
    
})();

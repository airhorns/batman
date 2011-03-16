(function() {
    
    Batman.LocalStorage = Batman.Mixin({
        usesLocalStorage: true,
        
        readAllFromStore: function(callback) {
            var model = this.model,
                ids = (localStorage[model.isMixin + '.ids'] || '').split(','),
                i = ids.length;
            
            while (i--) {
                var id = ids[i];
                if (!id)
                    continue;
                
                model({id: id}).readFromStore();
            }
            
            callback && callback();
        },
        
        readFromStore: function(callback) {
            var id = this.id();
            if (typeof id === 'undefined' || (typeof id === 'string' && !id))
                throw 'Record must have an ID to load.';
            
            var json = localStorage[this.model.isMixin + ':' + id],
                obj = JSON.parse(json);
            
            Batman.mixin(this, obj);
            
            callback && callback();
        },
        
        writeToStore: function(callback) {
            var model = this.model.isMixin;
            
            if (!this.id() && !this.hasStoreCoordinator) {
                var ids = (localStorage[model + '.ids'] || '').split(','),
                    id = Math.max.apply(Math, ids) + 1;
                
                if (ids.length === 1 && ids[0] === '')
                    ids.splice(0,1);
                
                ids.push(id);
                localStorage[model + '.ids'] = ids.join(',');
                
                this.id(id);
            }
            
            var obj = {};
            for (var key in this) {
                var binding = this[key];
                if (binding && binding.isBinding && !binding._preventAutocommit) {
                    var value = binding();
                    if (typeof value !== 'undefined')
                        obj[key] = value;
                }
            }
            
            localStorage[model + ':' + this.id()] = JSON.stringify(obj);
            callback && callback();
        }
    }).mixin({
        supported: function() {
            try {
                return 'localStorage' in window && window.localStorage !== null;
            } catch (e) {
                return false;
            }
        },
        
        onapply: function(to) {
            if (!this.supported())
                throw "LocalStorage is not supported.";
            
            if (typeof to.model.isMixin !== 'string')
                throw "LocalStorage requires model identifier.";
        }
    });
    
})();

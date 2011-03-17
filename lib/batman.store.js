(function() {
    
    Batman.LocalStorage = Batman.Mixin({
        usesLocalStorage: true,
        
        readAllFromStore: function(callback) {
            var model = this.model,
                ids = (localStorage[model.isMixin + '.ids'] || '').split(',');
            
            for (var i = -1, count = ids.length; ++i < count;) {
                var id = ids[i];
                if (!id)
                    continue;
                
                model.find(id).readFromStore();
            }
            
            callback && callback();
        },
        
        readFromStore: function(callback) {
            var id = this.id();
            if (typeof id === 'undefined' || (typeof id === 'string' && !id))
                throw 'Record must have an ID to load.';
            
            var json = localStorage[this.model.isMixin + ':' + id],
                data = JSON.parse(json);
            
            this.unserialize(data);
            
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
            
            localStorage[model + ':' + this.id()] = JSON.stringify(this.serialize());
            callback && callback();
        },
        
        removeFromStore: function(callback) {
            var id = this.id();
            if (typeof id === 'undefined' || (typeof id === 'string' && !id))
                throw 'Record must have ID to destroy.';
            
            var model = this.model.isMixin,
                key = model + ':' + id;
            
            if (localStorage[key]) {
                localStorage.removeItem(key);
                
                var ids = localStorage[model + '.ids'].split(',');
                ids.splice(ids.indexOf(id.toString()), 1);
                
                localStorage[model + '.ids'] = ids.join(',');
            }
            
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
    
    var stripPrefix = function(record, data) {
        if (record.HAS_PREFIX)
            for (var key in data)
                return data[key];
    };
    
    Batman.RestStorage = Batman.Mixin({
        usesRestStorage: true,
        BASE_URL: '',
        HAS_PREFIX: true,
        
        readAllFromStore: function(callback) {
            var model = this.model,
                url = this.BASE_URL + '/' + model.isMixin + '.json';
            
            Batman.Request(url).success(function(json) {
                try {
                    var records = JSON.parse(json);
                } catch (e) {
                    return console.log(e);
                }
                
                if (Array.isArray(records)) {
                    var oldAll = model.all(),
                        newAll = [];
                    
                    for (var i = -1, count = records.length; ++i < count;) {
                        var data = records[i];
                        data = stripPrefix(this, data);
                        
                        var record = model.find(data.id);
                        data && record.unserialize(data);
                        
                        newAll.push(record);
                    }
                    
                    var removedRecords = [];
                    for (var i = -1, count = oldAll.length; ++i < count;) {
                        var removed = oldAll[i];
                        if (newAll.indexOf(removed) === -1)
                            removedRecords.push(removed);
                    }
                    
                    model.all(newAll);
                    
                    callback && callback(removedRecords);
                }
            }.bind(this));
        },
        
        writeToStore: function(callback) {
            var model = this.model,
                id = this.id(),
                url = this.BASE_URL + '/' + model.isMixin + (id ? '/' + id : '') + '.json';
            
            Batman.Request({
                url: url,
                method: id ? 'put' : 'post',
                body: JSON.stringify(this.serialize())
            }).success(function(json, b) {
                var data = stripPrefix(this, JSON.parse(json));
                data && this.unserialize(data);
                
                callback && callback(this);
            }.bind(this));
        },
        
        removeFromStore: function(callback) {
            var model = this.model,
                id = this.id();
            
            if (!id)
                throw "Cannot destroy record without ID.";
            
            Batman.Request({
                url: this.BASE_URL + '/' + model.isMixin + '/' + id + '.json',
                method: 'delete'
            }).success(function() {
                callback && callback();
            });
        }
    }).mixin({
        create: function(baseURL, hasPrefix) {
            var defaults = {};
            typeof baseURL === 'string' && (defaults.BASE_URL = baseURL);
            typeof hasPrefix === 'boolean' && (defaults.HAS_PREFIX = hasPrefix);
            
            var args = Array.toArray(arguments);
            args.unshift(defaults);
            
            return Batman.Mixin.prototype.create.apply(Batman.RestStorage, args);
        }
    });
    
})();

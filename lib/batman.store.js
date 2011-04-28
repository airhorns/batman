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
    
    function stripPrefix(data) {
        for (var key in data)
            return data[key];
    }
    
    Batman.RestStorage = Batman.Mixin({
        usesRestStorage: true,
        
        url: '',
        
        restIdAttribute: 'id',
        restActions: {
            list: 'GET',
            show: 'GET',
            create: 'POST',
            update: 'PUT',
            destroy: 'DELETE'
        },
        
        collectionPrefix: true,
        recordPrefix: true,
        
        readAllFromStore: function(callback) {
            var url = Batman.RestStorage.BASE_URL + this.url + '.json';
            
            Batman.Request(url).success(function(json) {
                var records = JSON.parse(json);
                if (!Array.isArray(records))
                    records = stripPrefix(records);
                
                if (Array.isArray(records)) {
                    var oldAll = Array.toArray(this.all()),
                        newAll = [];
                    
                    for (var i = -1, count = records.length; ++i < count;) {
                        var recordData = records[i];
                        if (this.collectionPrefix)
                            recordData = stripPrefix(recordData);
                        
                        if (!recordData)
                            continue;
                        
                        var id = recordData[this.restIdAttribute];
                        if (typeof id === 'undefined')
                            continue;
                        
                        var record = this.findOrCreate(id);
                        record.fromJSON(recordData);
                        
                        newAll.push(record);
                    }
                    
                    var removedRecords = [], i = oldAll.length;
                    while (i--) {
                        var removed = oldAll[i];
                        if (Array.indexOf(newAll, removed) === -1) {
                            removedRecords.push(removed);
                            removed.id(null);
                        }
                    }
                }
                
                callback && callback(removedRecords);
            }.bind(this));
        },
        
        readFromStore: function(record, callback) {
            var url = Batman.RestStorage.BASE_URL + this.url + '/' + record.id() + '.json';
            
            Batman.Request(url)
                .success(function(json) {
                    var recordData = JSON.parse(json);
                    if (this.recordPrefix)
                        recordData = stripPrefix(recordData);
                    
                    record.fromJSON(recordData);
                    
                    callback && callback();
                }.bind(this))
                
                .error(function(e) {
                    record.id(null);
                    callback && callback(e);
                }.bind(this));
        }
    }).mixin({
        initialize: function() {
            if (!this.url)
                this.url = '/' + this.identifier + 's';
        },
        
        BASE_URL: ''
    });
    
})();

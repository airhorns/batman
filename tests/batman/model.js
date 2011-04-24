Batman.ready(function() {
    
    module('Batman.Model');
    
    test('construction', function() {
        var model = Batman.Model({
            name: $binding('foo')
        });
        
        equal(model.isModel, true, 'model isModel');
        
        var record = model({name: 'bar'});
        equal(record.isRecord, true, 'record isRecord');
        equal(record.name(), 'bar', 'bindings were set');
        
        var record2 = model();
        equal(model.all.count(), 2, 'model.all count increased');
        strictEqual(model.all()[0], record, 'model.all contains record');
        strictEqual(model.first(), record, 'model.first is record');
        strictEqual(model.last(), record2, 'model.last is second record');
    });
    
    test('create multiple', function() {
        var model = Batman.Model({
            name: $binding()
        });
        
        var users = [
            {name: 'nick'},
            {name: 'tobi'},
            {name: 'chris'}
        ];
        
        var records = model(users);
        equal(records.length, users.length, 'same number of records and users returned');
        deepEqual(records, model.all(), 'records matches model.all');
        
        equal(records[0].name(), 'nick');
        equal(records[2].name(), 'chris');
    });
        
    test('destroy', function() {
        var model = Batman.Model(),
            record = model();
        
        equal(model.all.count(), 1, 'one record in model.all');
        
        record.destroy();
        equal(model.all.count(), 0, 'zero records in model.all');
    });
    
    test('findBySelector', function() {
        var model = Batman.Model({
            name: $binding('')
        });
        
        var a = model({name: 'foo'});
        var b = model({name: 'bar'});
        
        strictEqual(model.find({name: 'foo'}), a);
        strictEqual(model.find({name: 'bar'}), b);
        strictEqual(model.find({}), a); // just finds the first model
        equal(model.find({wtf: 'foo'}), null);
        equal(model.find({name: 'baz'}), null);
    });
    
    test('findById', function() {
        var model = Batman.Model({
            name: $binding('')
        });
        
        var a = model({id: 1});
        
        strictEqual(model.find(1), a);
        strictEqual(model.find("1"), a);
        
        equal(model.find(2).id(), 2);
        equal(model.find("dsaksfa").id(), "dsaksfa");
        equal(model.find(), null);
    });
    
});

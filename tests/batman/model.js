Batman.onready(function() {
    
    module('Batman.Model');
    
    test('construction', function() {
        var model = Batman.Model({
            name: $binding('foo')
        });
        
        equal(model.isModel, true, 'model isModel');
        
        var record = model({name: 'bar'});
        equal(record.isRecord, true, 'record isRecord');
        equal(record.name, 'bar', 'bindings were set');
        
        var record2 = model();
        equal(model.all.count(), 2, 'model.all count increased');
        strictEqual(model.all()[0], record, 'model.all contains record');
        strictEqual(model.first(), record, 'model.first is record');
        strictEqual(model.last(), record2, 'model.last is second record');
    });
    
    test('serialization', 3, function() {
        var model = Batman.Model({
            name: $binding('foo'),
            gender: $binding('male').serialize(false),
            age: $binding(0)
        });
        
        var record = model(),
            data = record.serialized();
        
        equal(data.name, 'foo', 'serialized data is correct');
        equal(typeof data.gender, 'undefined', 'serialize(false) prevents objects from being serialized');
        
        record.serialized.observe(function() {
            ok(true, 'serialized fired');
        });
        
        record.name('bar');
    });
    
    test('transactions', function() {
        var model = Batman.Model({
            name: $binding('foo')
        });
        
        var record = model({name: 'bar'}),
            transaction = record.transaction({name: 'baz'});
        
        var serializeShouldFire = false;
        record.serialized.observe(function() {
            ok(serializeShouldFire, 'serialized fired');
        });
        
        equal(record.name(), 'bar', 'record name is not overwritten');
        equal(transaction.name(), 'baz', 'transaction name is set without affecting the record');
        
        serializeShouldFire = true;
        transaction.commit();
        equal(record.name(), 'baz', 'record name is overwritten when transaction is committed');
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
        equal(model.find(2), null);
        equal(model.find("dsaksfa"), null);
        equal(model.find(), null);
    });
    
});

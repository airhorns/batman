Batman.onready(function(){
    
    module('$mixin');
    
    test('Batman() constructor', function() {
        equal(typeof Batman(), 'object', 'constructs a new object');
    });
    
    test('object arguments', function() {
        var object = Batman({foo: 'bar'});
        equal(object.foo, 'bar', 'properties are applied');
    });
    
    test('array arguments', function() {
        var object = Batman([{foo: 'bar'}, {bar: 'baz'}]);
        deepEqual({foo: object.foo, bar: object.bar}, {foo: 'bar', bar: 'baz'}, 'properties passed in an array are applied');
    });
    
    test('Mixin arguments', function() {
        var object = Batman(Batman.Request);
        equal(object.isRequest, true, 'mixin has been applied to object');
    });
    
    test('bindings', function() {
        var object = Batman({name: $binding('')});
        equal(object.name(), '', 'binding default value is set');
        
        $mixin(object, {name: 'foo'});
        equal(object.name(), 'foo', 'mixing in a value to a binding sets the binding');
        
        var binding = $binding('bar');
        $mixin(object, {name: binding});
        strictEqual(object.name, binding, 'mixing in a value that is a binding replaces the original binding');
    });
    
    module('Batman.Mixin');
    
    test('constructor', function() {
        var mixin = Batman.Mixin();
        equal(typeof mixin, 'function', 'returns a constructor function');
        ok(mixin.isMixin, 'function isMixin');
    });
    
    test('mixin identifier', function() {
        var mixin = Batman.Mixin('test');
        equal(mixin.isMixin, 'test', 'isMixin set to identifier');
        strictEqual(Batman.mixins.test, mixin, 'mixin is stored in built-in list');
    });
    
    test('create()', function() {
        var mixin = Batman.Mixin({foo: 'bar'});
        equal(mixin.create().foo, 'bar', 'mixin properties are present on object');
        equal(mixin().foo, 'bar', 'constructor function calls create()');
        equal(mixin({bar: 'baz'}).bar, 'baz', 'arguments passed to constructor are also mixed into the object');
    });
    
    test('applyTo()', function() {
        var object = {},
            mixin = Batman.Mixin({foo: 'bar'}).applyTo(object);
        
        ok(mixin.isMixin, 'returns mixin');
        equal(object.foo, 'bar', 'mixin properties are present on object');
    });
    
    test('enhance()', function() {
        var mixin = Batman.Mixin({foo: 'bar'}).enhance({bar: 'baz'});
        equal(mixin().bar, 'baz', 'enhanced properties are present on object');
    });
    
    test('mixin()', function() {
        var mixin = Batman.Mixin({foo: 'bar'}).mixin({bar: 'baz'});
        equal(mixin.bar, 'baz', 'mixed in properties are preset on the mixin itself');
    });
    
    test('copying prototype values', function() {
        var mixin = Batman.Mixin({
            foo: $binding(''),
            foobar: $binding(function() {
                return this.foo() + 'bar';
            })
        });
        
        // FIXME: Write better tests
        
        var obj = mixin({foo: 'foo'});
        equal(obj.foobar(), 'foobar', 'mixin still applies value');
        equal(mixin.prototype.foobar(), 'bar', 'mixin prototype does not apply value');
        notStrictEqual(obj.foo, mixin.prototype.foo, 'mixin binding is not the same as object binding')
        
        var obj2 = Batman(mixin, {foo: 'baz'});
        equal(obj2.foobar(), 'bazbar', 'bindings are copied to every object');
    });
    
});

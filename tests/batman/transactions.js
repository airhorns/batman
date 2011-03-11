Batman.ready(function() {
    
    module('Batman.Transaction', {
        setup: function() {
            this.obj = Batman({
                foo: $binding('bar'),
                baz: $binding('qux')
            })
        },
        
        teardown: function() {
            delete this.obj;
        }
    });
    
    test('creation', function() {
        var t = Batman.transaction(this.obj);
        equal(t.isTransaction, true, 'transaction is transaction');
    });
    
    test('creation with arguments', function() {
        var t = Batman.transaction(this.obj, {foo: 'foo'});
        equal(t.foo, 'foo', 'arguments are applied');
    });
    
    test('commit', function() {
        var t = Batman.transaction(this.obj);
        t.foo = 'foo';
        t.newValue = 'pew pew';
        t.commit();
        
        equal(this.obj.foo.isBinding, true, 'binding is still binding');
        equal(this.obj.foo(), 'foo', 'binding value is applied');
        equal(this.obj.newValue, 'pew pew', 'simple value is applied');
    });

    test('transactionable', function() {
        Batman.Transactionable.applyTo(this.obj);
        equal(typeof this.obj.transaction, 'function', 'transaction method added');
        
        var t = this.obj.transaction();
        equal(t.isTransaction, true, 'transaction is a transaction');
        
        t.foo = 'foo';
        t.commit();
        
        equal(this.obj.foo(), 'foo', 'binding value is set');
    });
    
    test('change', function() {
        
    });
    
});

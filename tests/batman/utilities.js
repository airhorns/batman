Batman.ready(function() {
    
    module('Utilities');
    
    test('Array.isArray', function() {
        equal(Array.isArray([]), true, 'returns true for an array');
        equal(Array.isArray(new Array()), true, 'returns true for array constructor');
        equal(Array.isArray({}), false, 'returns false for an object');
    });
    
    test('Array.toArray', function() {
        deepEqual(Array.toArray([1,2,3]), [1,2,3], 'returns copy of array for a regular array');
        
        equal(Array.isArray(Array.toArray(arguments)), true, 'returns an array for arguments');
        equal(Array.toArray(arguments).length, arguments.length, 'arguments array is same length as arguments');
    });
    
    test('Array.indexOf', function() {
        equal(Array.indexOf(['a', 'b', 'c'], 'b'), 1, 'returns correct index for primitives');
        
        var obj1 = {foo: 'bar'},
            obj2 = {bar: 'baz'};
        
        equal(Array.indexOf([obj1, obj2], obj2), 1, 'returns correct index for objects');
    });
    
    test('Function.prototype.bind', function() {
        var context = {foo: 'bar'}, args = ['foo', 'bar', 'baz'],
            func = function() { return {context: this, args: Array.toArray(arguments)}; }.bind(context, 'qux');
        
        strictEqual(func().context, context, 'this inside function is bound context');
        strictEqual(func.call(window).context, context, 'this inside function is still bound context when using .call()');
        
        deepEqual(func.apply(context, args).args, ['qux'].concat(args), 'arguments passed to anonymous function get passed to bound function');
    });
    
    test('Batman.execute', function() {
        expect(5);
        
        Batman.execute(function() { strictEqual(this, Batman, 'context is Batman by default'); });
        Batman.execute(function(foo) { equal(foo, 'bar', 'arguments passed to execute are passed to function'); }, 'bar')
        
        var context = {foo: 'bar'};
        Batman.execute.call(context, function() { strictEqual(this, context, 'context is context of execute'); });
        
        Batman.execute([function(foo) { equal(foo, 'bar', 'function 1 has arguments'); }, function(foo) { equal(foo, 'bar', 'function 2 has arguments'); }], 'bar');
    });
    
    module('Batman.require');
    
    asyncTest('lib files', 1, function() {
        // loaded from Batman lib directory
        Batman.require(Batman.LIB_PATH + 'batman.dom.js', function() {
            ok(Batman.DOM, 'callback executed');
            start();
        });
    });
    
    asyncTest('source files', 1, function() {
        // loaded from local directory
        Batman.require('stubs/require_test.js', function() {
            ok(true, 'callback executed');
            start();
        });
    });
    
    asyncTest('multiple files', 2, function() {
        Batman.require(['stubs/require_test_1.js', 'stubs/require_test_2.js'], function() {
            ok(REQUIRE_TEST_1, 'test 1 included');
            ok(REQUIRE_TEST_2, 'test 2 included');
            start();
        })
    });
    
    test('no callback', function() {
        try {
            Batman.require('stubs/require_test.js');
        } catch (e) {
            ok(false, 'raised error');
        }
    });
    
    module('String Parsing');
    
    // FIXME
    
});

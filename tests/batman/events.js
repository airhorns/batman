Batman.ready(function() {
    
    module('$event', {
        setup: function() {
            this.complete = $event(function() {
                ok(true, 'event fired');
            });
        },
        
        teardown: function() {
            delete this.complete;
        }
    });
    
    test('returns an event', function() {
        ok(this.complete.isEvent, 'event is event');
        ok(this.complete.observe, 'inherits observe');
        ok(this.complete.fire, 'inherits fire');
    });
    
    test('observing and firing', function() {
        var observer = function() {
            ok(true, 'observer fired');
        };
        
        this.complete(observer);
        this.complete();
        
        expect(2);
    });
    
    test('removing an observer', function() {
        var observer = function(){
            ok(true, 'I should not be called');
        }
        
        this.complete(observer);
        this.complete.forget(observer);
        this.complete();
        
        expect(1);
    });
    
    test('dispatch with a function as an argument', function() {
        var success = $event(function(callback) {
            callback();
        }, true);
        
        success(function() { ok(true, 'observer fired'); });
        success.dispatch(function() { ok(true, 'callback fired'); });
        
        expect(2);
    });
    
    test('event function takes arguments', function() {
        // event dispatch -- args should get passed to the event function
        // if the func returns something, that ret val should be sent to all the observers
        // OTHERWISE! the args passed to dispatch should be sent to the observers
        var success = $event();
        
        success(function(foo, bar) {
            equal(foo, 'foo');
            equal(bar, 'bar');
        });
        
        success('foo', 'bar');
    });
    
    test('event function return value is passed to observers', function() {
        var success = $event(function(bar) {
            return 'foo';
        });
        
        success(function(foo) {
            equal(foo, 'foo');
        });
        
        success('bar');
    });
    
});

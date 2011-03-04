Batman.ready(function() {
    
    module('Batman.Request');
    
    test('creation', function() {
        var request = Batman.Request({url: 'stubs.js'});
        ok(request.isRequest, 'request is request');
        equal(request.url(), 'stubs.js', 'url is set');
        equal(request.method(), 'get', 'default method is get');
        
        request.cancel();
    });
    
    test('creation with url passing', function() {
        var request = Batman.Request('stubs.js', 'post');
        equal(request.url(), 'stubs.js');
        equal(request.method(), 'post');
        
        request.cancel();
    });
    
    asyncTest('events', function() {
        var request = Batman.Request({url: 'stubs/stubs.js'})
        .success(function(){
            ok(true, 'request was successful');
        }).error(function() {
            ok(true, 'request failed');
        }).complete(function() {
            start();
        });
        
        expect(1);
    });
    
});

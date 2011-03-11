Batman.ready(function() {
    
    module('Batman.App');
    
    test('construction', function() {
        var app = Batman.App();
        equal(app.isApp, true, 'app isApp');
    });
    
    asyncTest('requires', function() {
        var app = Batman.App({
            controllers: 'controller',
            controllersPath: 'stubs',
            
            models: 'model',
            views: 'view',
            
            requirePath: 'stubs'
        });
        
        app.ready(function() {
            ok(TestController, 'controller loaded');
            ok(TestModel, 'model loaded');
            ok(TestView, 'view loaded');
            start();
        });
        
        expect(3);
    });
    
});

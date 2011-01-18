Batman.onready(function() {
    
    module('Batman.App');
    
    test('construction', function() {
        var app = Batman.App();
        equal(app.isApp, true, 'app isApp');
    });
    
    asyncTest('requires', 3, function() {
        var app = Batman.App({
            controllers: 'controller',
            controllersPath: 'stubs',
            
            models: 'model',
            modelsPath: 'stubs',
            
            views: 'view',
            viewsPath: 'stubs'
        });
        
        app.onrun(function() {
            ok(TestController, 'controller loaded');
            ok(TestModel, 'model loaded');
            ok(TestView, 'view loaded');
            start();
        });
        
        app.run();
    });
    
});

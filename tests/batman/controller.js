Batman.onready(function() {
    
    module('Batman.Controller');
    
    test('construction', function() {
        var controller = Batman.Controller();
        equal(controller.isController, true, 'controller isController');
    });
    
});

Batman.ready(function() {
    
    module('Batman.View', {
        setup: function() {
            this.node = document.createElement('div');
        },
        
        teardown: function() {
            delete this.node;
        }
    });
    
    asyncTest('detecting DOM', 1, function() {
        Batman.View({node: this.node}).ready(function() {
            ok(Batman.DOM, 'loaded Batman.DOM');
            start();
        });
    });
    
});

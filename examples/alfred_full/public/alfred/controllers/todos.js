TodosController = Batman.Controller({
    add: function(text, node) {
        Todo({body: text}).save();
        
        node.value = '';
        node.blur();
    }
});

Todo = Batman.Model('todos', {
    body: $binding().validate(function(value) {
        return value || 'emtpy todo...';
    }),
    
    isDone: $binding(false),
    
    serialize: function() {
        return {
            todo: {
                body: this.body(),
                is_done: this.isDone()
            }
        };
    },
    
    unserialize: function(data) {
        this.body(data.body);
        this.isDone(data.is_done);
    }
}, Batman.RestStorage);

// Fixtures
Todo.load(function() {
    if (!Todo.all().length) {
        Todo({body: 'riddler sent riemann hypothesis'}).save();
        Todo({body: 'bane wants to meet, not worried'}).save();
        Todo({body: 'joker escaped arkham again'}).save();
    }
});

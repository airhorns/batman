developer["do"](function() {
  App.require = function() {
    var base, name, names, path, _i, _len;
    path = arguments[0], names = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    base = this.requirePath + path;
    for (_i = 0, _len = names.length; _i < _len; _i++) {
      name = names[_i];
      this.prevent('run');
      path = base + '/' + name + '.coffee';
      new Batman.Request({
        url: path,
        type: 'html',
        success: __bind(function(response) {
          CoffeeScript.eval(response);
          this.allow('run');
          if (!this.isPrevented('run')) {
            this.fire('loaded');
          }
          if (this.wantsToRun) {
            return this.run();
          }
        }, this)
      });
    }
    return this;
  };
  return {
    controller: function() {
      var names;
      names = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      names = names.map(function(n) {
        return n + '_controller';
      });
      return this.require.apply(this, ['controllers'].concat(__slice.call(names)));
    },
    model: function() {
      return this.require.apply(this, ['models'].concat(__slice.call(arguments)));
    },
    view: function() {
      return this.require.apply(this, ['views'].concat(__slice.call(arguments)));
    }
  };
});

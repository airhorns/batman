(function() {
  #!/usr/bin/env node
;  var Batman, alias, aliases, arg, request, task, tasks;
  Batman = require('../lib/batman.js').Batman;
  Batman.missingArg = function(name) {
    return console.log('why so serious? (please provide ' + name + ')');
  };
  tasks = {};
  aliases = {};
  task = function(name, description, f) {
    if (typeof description === 'function') {
      f = description;
    } else {
      f.description = description;
    }
    f.name = name;
    tasks[name] = f;
    return f;
  };
  alias = function(name, original) {
    var f;
    f = tasks[original];
    if (!f.aliases) {
      f.aliases = [];
    }
    f.aliases.push(name);
    return aliases[name] = f;
  };
  task('server', 'starts the Batman server', function() {
    return require('./server.js');
  });
  alias('s', 'server');
  task('gen', 'generate an app or files inside an app', function() {
    return require('./generator.js');
  });
  alias('g', 'gen');
  task('-T', function() {
    var desc, key, string, _i, _len, _results;
    _results = [];
    for (_i = 0, _len = tasks.length; _i < _len; _i++) {
      key = tasks[_i];
      if (key.substr(0, 1) === '-') {
        continue;
      }
      string = key;
      aliases = tasks[key].aliases;
      if (aliases) {
        string += ' (' + aliases.join(', ') + ')';
      }
      desc = tasks[key].description;
      if (desc) {
        string += ' -- ' + desc;
      }
      _results.push(console.log(string));
    }
    return _results;
  });
  arg = process.argv[2];
  if (arg) {
    request = tasks[arg] || aliases[arg];
    if (request) {
      request();
    } else {
      console.log(arg + ' is not a known task');
    }
  } else {
    Batman.missingArg('task');
  }
}).call(this);

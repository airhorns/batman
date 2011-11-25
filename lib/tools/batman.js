(function() {
  #!/usr/bin/env node

;  (function() {
    var Batman, Commands, cli, noCommandGiven, oldFatal;
    cli = require('./cli');
    Batman = require('../lib/batman.js');
    global.RUNNING_IN_BATMAN = true;
    Commands = ['server', 'generate', 'new'];
    cli.disable('help');
    oldFatal = cli.fatal;
    noCommandGiven = false;
    cli.fatal = function(str) {
      if (str.match('command is required')) {
        noCommandGiven = true;
        cli.enable('help').parse(null, Commands);
        return process.exit();
      } else {
        return oldFatal(str);
      }
    };
    cli.parse(null, Commands);
    cli.fatal = oldFatal;
    cli.enable('help');
    cli.setArgv(process.argv);
    switch (cli.command) {
      case 'serve':
      case 'server':
        return require('./server');
      case 'generate':
      case 'new':
        return require('./generator');
    }
  })();
}).call(this);

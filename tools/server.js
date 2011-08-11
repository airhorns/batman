(function() {
  var cli, connect, fs, path;
  connect = require('connect');
  path = require('path');
  fs = require('fs');
  cli = require('./cli');
  cli.enable('daemon').setUsage('batman server [OPTIONS]').parse({
    port: ['p', "Port to run HTTP server on", "number", 8124]
  });
  cli.main(function(args, options) {
    var Server, code, mainPath;
    Server = connect.createServer(connect.favicon(), connect.logger(), connect.compiler({
      src: process.cwd(),
      enable: ['coffeescript']
    }), connect.static(process.cwd()));
    Server.use('/batman', connect.static(path.join(__dirname, '..', 'lib')));
    Server.listen(options.port, '127.0.0.1');
    mainPath = path.join(process.cwd(), 'main.js');
    if (path.existsSync(mainPath)) {
      code = fs.readFileSync(mainPath, 'utf8');
      eval(code);
    }
    return this.ok('Batman is waiting at http://127.0.0.1:' + options.port);
  });
}).call(this);

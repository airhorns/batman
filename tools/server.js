(function() {
  var cli, connect, fs, path, utils;
  connect = require('connect');
  path = require('path');
  fs = require('fs');
  cli = require('./cli');
  utils = require('./server_utils');
  cli.enable('daemon').setUsage('batman server [OPTIONS]').parse({
    port: ['p', "Port to run HTTP server on", "number", 8124],
    build: ['b', "Build coffeescripts on the fly into the build dir (default ./build) and serve them as js", "boolean", true],
    'build-dir': [false, "Where to store built coffeescript files", "path", './build']
  });
  cli.main(function(args, options) {
    var Server, code, mainPath;
    Server = connect.createServer(connect.favicon(), connect.logger(), connect.static(process.cwd()), connect.directory(process.cwd()));
    if (options.build) {
      Server.use(utils.CoffeeCompiler({
        src: process.cwd(),
        dest: path.join(process.cwd(), options['build-dir'])
      }));
    }
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

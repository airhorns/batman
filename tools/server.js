(function() {
  var Batman, cli, connect, fs, path, utils;
  connect = require('connect');
  path = require('path');
  fs = require('fs');
  cli = require('./cli');
  utils = require('./utils');
  Batman = require('../lib/batman.js');
  cli.enable('daemon').setUsage('batman server [OPTIONS]').parse({
    port: ['p', "Port to run HTTP server on", "number", 8124],
    build: ['b', "Build coffeescripts on the fly into the build dir (default is ./build) and serve them as js", "boolean", true],
    'build-dir': [false, "Where to store built coffeescript files (default is ./build)", "path"]
  });
  cli.main(function(args, options) {
    var Server, code, mainPath;
    Batman.mixin(options, utils.getConfig());
    if (options['build-dir'] != null) {
      options.buildDir = options['build-dir'];
    }
    Server = connect.createServer(connect.favicon(), connect.logger(), connect.static(process.cwd()), connect.directory(process.cwd()));
    if (options.build) {
      Server.use(utils.CoffeeCompiler({
        src: process.cwd(),
        dest: path.join(process.cwd(), options.buildDir)
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

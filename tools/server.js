(function() {
  var Batman, cli, connect, defaultOptions, fs, getServer, path, utils;
  connect = require('connect');
  path = require('path');
  fs = require('fs');
  cli = require('./cli');
  utils = require('./utils');
  Batman = require('../lib/batman.js');
  getServer = function(options) {
    var server;
    server = connect.createServer(connect.favicon(), connect.logger(), connect.static(process.cwd()), connect.directory(process.cwd()));
    if (options.build) {
      server.use(utils.CoffeeCompiler({
        src: process.cwd(),
        dest: path.join(process.cwd(), options.buildDir)
      }));
    }
    server.use('/batman', connect.static(path.join(__dirname, '..', 'lib')));
    server.listen(options.port, options.host);
    return server;
  };
  if (typeof RUNNING_IN_BATMAN !== 'undefined') {
    defaultOptions = utils.getConfig();
    cli.enable('daemon').setUsage('batman server [OPTIONS]').parse({
      host: ['h', "Host to run HTTP server on", "string", "127.0.0.1"],
      port: ['p', "Port to run HTTP server on", "number", 1047],
      build: ['b', "Build coffeescripts on the fly into the build dir (default is ./build) and serve them as js", "boolean", defaultOptions.build],
      'build-dir': [false, "Where to store built coffeescript files (default is ./build)", "path", defaultOptions.buildDir]
    });
    cli.main(function(args, options) {
      var info, server;
      options.buildDir = options['build-dir'];
      options.buildDir || (options.buildDir = './build');
      server = getServer(options);
      info = "Batman is waiting at http://" + options.host + ":" + options.port;
      if (options.build) {
        info += ", and building to " + options.buildDir + ".";
      }
      return this.ok(info);
    });
  } else {
    module.exports = getServer;
  }
}).call(this);

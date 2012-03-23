(function() {
  var glob, path, qqunit;
  var __hasProp = Object.prototype.hasOwnProperty;

  glob = require('glob');

  path = require('path');

  qqunit = require('qqunit');

  qqunit.Environment.jsdom.jQueryify(window, path.join(__dirname, 'lib', 'jquery.js'), function(window, jQuery) {
    var File, Helper, k, tests, v;
    global.jQuery = jQuery;
    global.File = window.File = File = (function() {

      function File() {}

      return File;

    })();
    Helper = require('./batman/test_helper');
    for (k in Helper) {
      if (!__hasProp.call(Helper, k)) continue;
      v = Helper[k];
      global[k] = v;
    }
    global.Batman = require('../src/batman.node');
    Batman.exportGlobals(global);
    Batman.Request.prototype.getModule = function() {
      return {
        request: function() {
          throw new Error("Can't send requests during tests!");
        }
      };
    };
    tests = glob.sync("" + __dirname + "/batman/**/*_test.coffee").map(function(test) {
      return path.resolve(process.cwd(), test);
    });
    console.log("Running Batman test suite. " + tests.length + " files required.");
    return qqunit.Runner.run(tests, function(stats) {
      return process.exit(stats.failed);
    });
  });

}).call(this);

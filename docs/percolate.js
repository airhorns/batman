(function() {
  var coffee, fs, glob, jqueryPath, oldErrorHandler, path, percolate, qqunit, testDir;
  var __hasProp = Object.prototype.hasOwnProperty, __slice = Array.prototype.slice;

  glob = require('glob');

  path = require('path');

  fs = require('fs');

  coffee = require('coffee-script');

  qqunit = require('qqunit');

  oldErrorHandler = window.onerror;

  delete window.onerror;

  percolate = require('percolate');

  testDir = path.resolve(__dirname, '..', 'tests');

  jqueryPath = path.join(testDir, 'lib', 'jquery.js');

  qqunit.Environment.jsdom.jQueryify(window, jqueryPath, function(window, jQuery) {
    var Helper, docs, k, v;
    try {
      global.jQuery = jQuery;
      Helper = require("" + testDir + "/batman/test_helper");
      for (k in Helper) {
        if (!__hasProp.call(Helper, k)) continue;
        v = Helper[k];
        global[k] = v;
      }
      global.Batman = require('../src/batman.node');
      Batman.exportGlobals(global);
      Batman.Request.prototype.send = function() {
        throw new Error("Can't send requests during tests!");
      };
      docs = glob.sync("" + __dirname + "/**/*.percolate").map(function(doc) {
        return path.resolve(process.cwd(), doc);
      });
      console.log("Running Batman doc suite.");
      if (process.argv[2] === '--test-only') {
        return percolate.test.apply(percolate, [__dirname].concat(__slice.call(docs), [function(error, stats) {
          return process.exit(stats.failed);
        }]));
      } else {
        return percolate.generate.apply(percolate, [__dirname].concat(__slice.call(docs), [function(error, stats, output) {
          if (error) throw error;
          if (!(stats.failed > 0)) {
            fs.writeFileSync(path.join(__dirname, 'batman.html'), output);
          }
          console.log("Docs written.");
          return process.exit(stats.failed);
        }]));
      }
    } catch (e) {
      console.error(e.stack);
      return process.exit(1);
    }
  });

}).call(this);

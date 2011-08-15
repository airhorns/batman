(function() {
  var cache, connect, fs, mkdir_p, parse, path;
  connect = require('connect');
  path = require('path');
  fs = require('fs');
  parse = require("url").parse;
  cache = {};
  exports.mkdir_p = mkdir_p = function(path, mode, callback, position) {
    var directory, parts;
    mode = mode || process.umask();
    position = position || 0;
    parts = require("path").normalize(path).split("/");
    if (position >= parts.length) {
      if (callback) {
        return callback();
      } else {
        return true;
      }
    }
    directory = parts.slice(0, position + 1).join("/") || "/";
    return fs.stat(directory, function(err) {
      if (err === null) {
        return mkdir_p(path, mode, callback, position + 1);
      } else {
        return fs.mkdir(directory, mode, function(err) {
          if (err && err.errno !== 17) {
            if (callback) {
              return callback(err);
            } else {
              throw err;
            }
          } else {
            return mkdir_p(path, mode, callback, position + 1);
          }
        });
      }
    });
  };
  exports.CoffeeCompiler = function(options) {
    var destDir, srcDir;
    options = options || {};
    srcDir = options.src || process.cwd();
    destDir = options.dest || srcDir;
    return function(req, res, next) {
      var compile, compiler, dest, pathname, send, src;
      if ("GET" !== req.method) {
        return next();
      }
      pathname = parse(req.url).pathname;
      compiler = {
        match: /\.js$/,
        ext: ".coffee",
        compile: function(str, fn) {
          var coffee;
          coffee = cache.coffee || (cache.coffee = require("coffee-script"));
          try {
            return fn(null, coffee.compile(str));
          } catch (err) {
            return fn(err);
          }
        }
      };
      compile = function(src, dest, next) {
        return fs.readFile(src, "utf8", function(err, str) {
          if (err) {
            return next(err);
          } else {
            return compiler.compile(str, function(err, str) {
              if (err) {
                return next(err);
              } else {
                return mkdir_p(path.dirname(dest), 0755, function(err) {
                  if (err) {
                    return next(err);
                  } else {
                    return fs.writeFile(dest, str, "utf8", function(err) {
                      return next(err);
                    });
                  }
                });
              }
            });
          }
        });
      };
      if (compiler.match.test(pathname)) {
        src = (srcDir + pathname).replace(compiler.match, compiler.ext);
        dest = destDir + pathname;
        send = function(err) {
          if (err != null) {
            return next(err);
          } else {
            return connect.static.send(req, res, next, {
              path: dest
            });
          }
        };
        fs.stat(src, function(err, srcStats) {
          if (err) {
            if ("ENOENT" === err.code) {
              return next();
            } else {
              return next(err);
            }
          } else {
            return fs.stat(dest, function(err, destStats) {
              if (err) {
                if ("ENOENT" === err.code) {
                  return compile(src, dest, send);
                } else {
                  return next(err);
                }
              } else {
                if (srcStats.mtime > destStats.mtime) {
                  return compile(src, dest, send);
                } else {
                  return send();
                }
              }
            });
          }
        });
        return;
      }
      return next();
    };
  };
}).call(this);

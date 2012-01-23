(function() {
  var Batman, cli, exec, fs, path, spawn, util, utils, _ref;

  fs = require('fs');

  path = require('path');

  util = require('util');

  cli = require('./cli');

  utils = require('./utils');

  _ref = require('child_process'), spawn = _ref.spawn, exec = _ref.exec;

  Batman = require('../lib/batman.js');

  cli.setUsage('batman [OPTIONS] generate app|model|controller|view <name>\n  batman [OPTIONS] new <app_name>');

  cli.parse({
    app: ['-n', "The name of your Batman application (if generating an application component). This can also be stored in a .batman file in the project root.", "string"]
  });

  cli.main(function(args, options) {
    var TemplateVars, command, count, destinationPath, replaceVars, source, transforms, walk;
    var _this = this;
    options.appName = options.app;
    command = args.shift();
    if (command === 'new') {
      options.template = 'app';
      if (args[0] == null) {
        this.error("Please provide a name for the application.");
        cli.getUsage();
      }
      options.name = args[0];
    } else if (args.length === 2) {
      options.template = args[0];
      options.name = args[1];
    } else {
      this.error("Please specify a template and a name for batman generate.");
      cli.getUsage();
    }
    source = path.join(__dirname, 'templates', options.template);
    if (!path.existsSync(source)) {
      this.fatal("template " + options.template + " not found");
    }
    TemplateVars = {};
    if (options.template === 'app') {
      if (options.appName != null) {
        options.name = options.appName;
      } else {
        options.appName = options.name;
      }
      destinationPath = path.join(process.cwd(), options.appName);
      if (path.existsSync(destinationPath)) {
        this.fatal('Destination already exists!');
      } else {
        fs.mkdirSync(destinationPath, 0755);
      }
    } else {
      destinationPath = process.cwd();
      Batman.mixin(options, utils.getConfig());
    }
    options.appName = Batman.helpers.camelize(options.appName);
    Batman.mixin(TemplateVars, {
      app: options.appName,
      name: options.name
    });
    transforms = [
      (function(x) {
        return x.toUpperCase();
      }), (function(x) {
        return Batman.helpers.camelize(x);
      }), (function(x) {
        return Batman.helpers.underscore(x).toLowerCase();
      })
    ];
    replaceVars = function(string) {
      var f, templateKey, value, _i, _len;
      for (templateKey in TemplateVars) {
        value = TemplateVars[templateKey];
        if (value == null) {
          console.error("template key " + templateKey + " not defined!");
        }
        string = string.replace(new RegExp("\\$_" + templateKey + "\\$", 'g'), value);
        for (_i = 0, _len = transforms.length; _i < _len; _i++) {
          f = transforms[_i];
          string = string.replace(new RegExp("\\$" + (f(templateKey)) + "\\$", 'g'), f(value));
        }
      }
      return string;
    };
    count = 0;
    walk = function(aPath) {
      var sourcePath;
      if (aPath == null) aPath = "/";
      sourcePath = path.join(source, aPath);
      return fs.readdirSync(sourcePath).forEach(function(file) {
        var destFile, dir, ext, newFile, oldFile, resultName, sourceFile, stat;
        if (file === '.gitignore') return;
        resultName = replaceVars(file);
        sourceFile = path.join(sourcePath, file);
        destFile = path.join(destinationPath, aPath, resultName);
        ext = path.extname(file).toLowerCase().slice(1);
        stat = fs.statSync(sourceFile);
        if (stat.isDirectory()) {
          dir = path.join(destinationPath, aPath, resultName);
          if (!path.existsSync(dir)) fs.mkdirSync(dir, 0755);
          return walk(path.join(aPath, file));
        } else if (ext === 'png' || ext === 'jpg' || ext === 'gif') {
          newFile = fs.createWriteStream(destFile);
          oldFile = fs.createReadStream(sourceFile);
          _this.info("creating " + destFile);
          return util.pump(oldFile, newFile, function(err) {
            if (err != null) throw err;
          });
        } else {
          if (file.charAt(0) === '.') return;
          count++;
          return fs.readFile(sourceFile, 'utf8', function(err, fileContents) {
            if (err != null) throw err;
            _this.info("creating " + destFile);
            return fs.writeFile(destFile, replaceVars(fileContents), function(err) {
              if (err != null) throw err;
              if (--count === 0) {
                return _this.ok("" + options.name + " generated successfully.");
              }
            });
          });
        }
      });
    };
    return walk();
  });

}).call(this);

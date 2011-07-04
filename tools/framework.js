(function() {
  var File, Path, exec;
  File = require('fs');
  Path = require('path');
  exec = require('child_process').exec;
  File.symlinkSync(Path.join(__dirname, '..', 'lib'), Path.join(process.cwd(), 'lib'));
}).call(this);

(function() {
  var File, Path, code, everyone, file, http, ids, mainPath, port, server, stat, _port;
  http = require('http');
  stat = require('node-static');
  Path = require('path');
  File = require('fs');
  _port = process.argv.indexOf('-p');
  port = _port !== -1 ? process.argv[_port + 1] : '8124';
  file = new stat.Server({
    cache: 1
  });
  server = http.createServer(function(req, res) {
    return req.addListener('end', function() {
      return file.serve(req, res);
    });
  });
  server.listen(port, '127.0.0.1');
  ids = {};
  everyone = require('now').initialize(server);
  everyone.now.sendSync = function(data) {
    ids = data;
    return everyone.now.receiveSync(ids);
  };
  everyone.connected(function() {
    return this.now.receiveSync(ids);
  });
  mainPath = Path.join(process.cwd(), 'main.js');
  if (Path.existsSync(mainPath)) {
    code = File.readFileSync(mainPath, 'utf8');
    eval(code);
  }
  console.log('Batman is waiting at http:#127.0.0.1:' + port);
}).call(this);

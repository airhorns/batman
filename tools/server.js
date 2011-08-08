(function() {
  var code, connect, fs, mainPath, path, port, server, _port;
  connect = require('connect');
  path = require('path');
  fs = require('fs');
  _port = process.argv.indexOf('-p');
  port = _port !== -1 ? process.argv[_port + 1] : '8124';
  server = connect.createServer(connect.favicon(), connect.logger(), connect.compiler({
    src: process.cwd(),
    enable: ['coffeescript']
  }), connect.static(process.cwd()));
  server.listen(port, '127.0.0.1');
  mainPath = path.join(process.cwd(), 'main.js');
  if (path.existsSync(mainPath)) {
    code = fs.readFileSync(mainPath, 'utf8');
    eval(code);
  }
  console.log('Batman is waiting at http://127.0.0.1:' + port);
}).call(this);

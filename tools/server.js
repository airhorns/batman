/* 
 * server.js
 * 
 * Batman
 * Copyright Shopify, 2011
 */

var http = require('http')

var _port = process.argv.indexOf('-p')
var port = _port !== -1 ? process.argv[_port + 1] : '8124'

http.createServer(function(req, res) {
	res.writeHead(200, {'Content-Type': 'text/plain'})
	res.end('Batman\n')
}).listen(port, '127.0.0.1')

console.log('Batman is waiting at http://127.0.0.1:' + port)

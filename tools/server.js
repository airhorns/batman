/* 
 * server.js
 * 
 * Batman
 * Copyright Shopify, 2011
 */

var http = require('http')
var stat = require('node-static')

var _port = process.argv.indexOf('-p')
var port = _port !== -1 ? process.argv[_port + 1] : '8124'

var file = new stat.Server({cache: 1})

var server = http.createServer(function(req, res) {
  req.addListener('end', function() {
    file.serve(req, res)
  })
})
server.listen(port, '127.0.0.1')

var ids = {}

var everyone = require('now').initialize(server)
everyone.now.sendSync = function(data) {
  ids = data
  everyone.now.receiveSync(ids)
}

everyone.connected(function() {
  this.now.receiveSync(ids)
})

console.log('Batman is waiting at http://127.0.0.1:' + port)

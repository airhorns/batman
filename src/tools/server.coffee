# server.js
# Batman
# Copyright Shopify, 2011

http = require('http')
stat = require('node-static')
Path = require('path')
File = require('fs')

_port = process.argv.indexOf('-p')
port = if _port != -1 then process.argv[_port + 1] else '8124'

file = new stat.Server
  cache: 1

server = http.createServer (req, res) ->
    req.addListener 'end', () ->
      file.serve(req, res)

server.listen port, '127.0.0.1'

ids = {}

everyone = require('now').initialize(server)
everyone.now.sendSync = (data) ->
  ids = data
  everyone.now.receiveSync(ids)

everyone.connected () ->
  this.now.receiveSync(ids)

mainPath = Path.join(process.cwd(), 'main.js')
if Path.existsSync(mainPath)
  code = File.readFileSync(mainPath, 'utf8')
  eval code

console.log('Batman is waiting at http:#127.0.0.1:' + port)

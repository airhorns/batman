# server.js
# Batman
# Copyright Shopify, 2011

connect = require 'connect'
path    = require 'path'
fs      = require 'fs'
cli     = require './cli'

cli.enable('daemon').setUsage('batman server [OPTIONS]').parse
  port: ['p', "Port to run HTTP server on", "number", 8124]

cli.main (args, options) ->

  # Create a connect server with the
  #  * transparent coffee compilation middleware
  #  * staic file serving middle ware for the current directory
  #  * static file serving at the /batman path for the lib dir of batman
  # and tell it to serve on the passed port.
  Server = connect.createServer(
    connect.favicon(),
    connect.logger(),
    connect.compiler(src: process.cwd(), enable: ['coffeescript']),
    connect.static(process.cwd()),
  )
  Server.use '/batman', connect.static(path.join(__dirname,'..','lib'))
  Server.listen options.port, '127.0.0.1'


  # Execut a main.js if there is one
  mainPath = path.join(process.cwd(), 'main.js')
  if path.existsSync(mainPath)
    code = fs.readFileSync(mainPath, 'utf8')
    eval code

  @ok 'Batman is waiting at http://127.0.0.1:' + options.port

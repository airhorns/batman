#
# server.coffee
# batman.js
#
# Created by Nick Small
# Copyright 2011, Shopify
#

connect = require 'connect'
path    = require 'path'
fs      = require 'fs'
cli     = require './cli'
utils   = require './utils'
Batman  = require '../lib/batman.js'

# Creates a connect server. This file is required by the main batman executable,
# but it can also be required by clients wishing to extend the connect stack for
# their own nefarious purposes.
#
# Options:
#  * `build` - Boolean : if truthy the server will transparently compile requests for a .js file from a .coffee file if the .coffee file exists.
#  * `buildDir` - Path : where to place the built Coffeescript files if `build` is true. Defaults to './build'
#  * `port` - Number   : what port to listen on.
getServer = (options) ->
  # Create a connect server with the
  #  * transparent coffee compilation middleware
  #  * staic file serving middle ware for the current directory
  #  * static file serving at the /batman path for the lib dir of batman
  # and tell it to serve on the passed port.
  server = connect.createServer(
    connect.favicon(),
    connect.logger(),
    connect.static(process.cwd()),
    connect.directory(process.cwd())
  )

  if options.build
    server.use utils.CoffeeCompiler(src: process.cwd(), dest: path.join(process.cwd(), options.buildDir))

  server.use '/batman', connect.static(path.join(__dirname,'..','lib'))
  server.listen options.port, options.host
  return server

if typeof RUNNING_IN_BATMAN isnt 'undefined'
  defaultOptions = utils.getConfig()
  cli.enable('daemon')
     .setUsage('batman server [OPTIONS]')
     .parse
        host: ['h', "Host to run HTTP server on", "string", "127.0.0.1"]
        port: ['p', "Port to run HTTP server on", "number", 1047]
        build: ['b', "Build coffeescripts on the fly into the build dir (default is ./build) and serve them as js", "boolean", defaultOptions.build]
        'build-dir': [false, "Where to store built coffeescript files (default is ./build)", "path", defaultOptions.buildDir]

  cli.main (args, options) ->
    # Switch to JS style
    options.buildDir = options['build-dir']
    options.buildDir ||= './build'

    server = getServer(options)
    info = "Batman is waiting at http://#{options.host}:#{options.port}"
    if options.build
      info += ", and building to #{options.buildDir}."
    @ok info
else
  module.exports = getServer

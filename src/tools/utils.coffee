#
# utils.coffee
# batman.js
#
# Created by Nick Small
# Copyright 2011, Shopify
#

connect = require 'connect'
path    = require 'path'
fs      = require 'fs'
cli     = require './cli'
parse = require("url").parse
cache = {}

# Recursive mkdir (creates all nonexistent path segments)
# Lifted from https://github.com/bpedro/node-fs
# Copyright 2010 Bruno Pedro
# MIT Licensed
exports.mkdir_p = mkdir_p = (path, mode, callback, position) ->
  mode = mode or process.umask()
  position = position or 0
  parts = require("path").normalize(path).split("/")
  if position >= parts.length
    if callback
      return callback()
    else
      return true
  directory = parts.slice(0, position + 1).join("/") or "/"
  fs.stat directory, (err) ->
    if err == null
      mkdir_p path, mode, callback, position + 1
    else
      fs.mkdir directory, mode, (err) ->
        if err and err.errno != 17
          if callback
            callback err
          else
            throw err
        else
          mkdir_p path, mode, callback, position + 1

# CoffeeScript on the fly compiler
# Heavily based on connect/lib/middlewares/compiler.js
# Copyright(c) 2010 Sencha Inc.
# Copyright(c) 2011 TJ Holowaychuk
# MIT Licensed
# Modified to compile to a tertiary location, but still serve from the s/js/coffee path
# Example: /models/user.js is requested.
#  * Compiler will check /build/models/user.js to see if it exists
#  * If so, check the mtime, serve it if its up to date
#  * If not, recompile from /models/user.coffee, and serve it.
# Note that /build/modules/user.js is never requested.
exports.CoffeeCompiler = (options) ->
  options = options or {}
  srcDir = options.src or process.cwd()
  destDir = options.dest or srcDir
  # Return a connect middleware
  return (req, res, next) ->
    return next()  unless "GET" == req.method
    pathname = parse(req.url).pathname

    compiler =
      match: /\.js$/
      ext: ".coffee"
      compile: (str, fn) ->
        coffee = cache.coffee or (cache.coffee = require("coffee-script"))
        try
          fn null, coffee.compile(str)
        catch err
          fn err

    # Function to compile src to dest, no questions asked. Fills in missing directories with `mkdir_p`.
    compile = (src, dest, next) ->
      fs.readFile src, "utf8", (err, str) ->
        if err
          next err
        else
          compiler.compile str, (err, str) ->
            if err
              next err
            else
              mkdir_p path.dirname(dest), 0755, (err) ->
                if err
                  next err
                else
                  fs.writeFile dest, str, "utf8", (err) ->
                    next err

    # Test the path to see if it can be compiled
    if compiler.match.test(pathname)
      src = (srcDir + pathname).replace(compiler.match, compiler.ext)
      dest = destDir + pathname
      # Get a handy function for piping the compiled file out using connect's static middleware. We use this
      # so we get handy things like range support, proper mimetyping, and all the other goodness baked in there.
      send = (err) ->
        if err?
          next(err)
        else
          connect.static.send(req, res, next, {path: dest})

      # See if the source exists. If it doesn't, we aren't going to compile, so just move on to the next middleware
      # in the stack.
      fs.stat src, (err, srcStats) ->
        if err
          if "ENOENT" == err.code
            next()
          else
            next err
        else
          # If the source does exist, check to see if we've compiled it before. If we have, ensure its up to date
          # by checking the modified times of the source and destination. Compile if the source is newer, and then
          # send.
          fs.stat dest, (err, destStats) ->
            if err
              if "ENOENT" == err.code
                compile src, dest, send
              else
                next err
            else
              if srcStats.mtime > destStats.mtime
                compile src, dest, send
              else
                send()
      return

    # Move on to the next middleware if we can't deal with this request.
    next()

exports.getConfig = (->
  try
    json = fs.readFileSync(path.join(process.cwd(), 'package.json')).toString().trim()
    jsonOptions = JSON.parse(json)
    return jsonOptions.batman
  catch e
    if e.code is 'EBADF'
      @fatal 'Couldn\'t find your Batman project configuration! Please put it in your package.json under the batman key.'
    else
      throw e
).bind(cli)

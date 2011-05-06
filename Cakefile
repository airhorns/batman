# Cakefile
# Batman
# Copyright Shopify, 2011


# Watches the src dir of batman and compiles files when they change to the proper directories.

CoffeeScript  = require 'coffee-script'
fs            = require 'fs'
path          = require 'path'
glob          = require 'glob'
exec          = require('child_process').exec

CompilationMap =
  # Relative to src    # Relative to root
  #'tools/batman.coffe' : 'tools/batman'
 'batman.coffee'      : 'lib/batman.js'
 'tools/(.+)\.coffee' : 'tools/$1.js'

getCompilationPairs = ->
  files = glob.globSync('src/**/*')
  map = {}
  for source, dest of CompilationMap
    source = new RegExp("src/#{source}")
    for i, file of files
      if matches = source.exec(file)
        delete files[i]
        map[file] = dest.replace("$1", matches[1])
  map

# Following 3 functions are stolen from Jitter, https://github.com/TrevorBurnham/Jitter/blob/master/src/jitter.coffee
# Watches a script and compiles it whenever it changes
watchScript = (source, target, options) ->
  fs.watchFile source, persistent: true, interval: 250, (curr, prev) ->
    return if curr.mtime.getTime() is prev.mtime.getTime()
    compileScript(source, target, options)

# Compiles a script to a destination
compileScript = (source, target, options) ->
  try
    code = fs.readFileSync(source).toString()
    js = CoffeeScript.compile code, {source, bare: options?.bare}
    fs.writeFileSync target, js
    notify source, "Compiled #{source} to #{target} successfully"
  catch err
    notify source, err.message, true

# Copies and chmods a file
copyFile = (source, target, mode = 0644) ->
  contents = fs.readFileSync source
  fs.writeFileSync target, contents
  fs.chmodSync(target, mode)
  notify source, "Moved #{source} to #{target} successfully"

# Notifies the user of a success or error during compilation
notify = (source, origMessage, error = false) ->
  if error
    basename = source.replace(/^.*[\/\\]/, '')
    if m = origMessage.match /Parse error on line (\d+)/
      message = "Parse error in #{basename}\non line #{m[1]}."
    else
      message = "Error in #{basename}."
    args = ['growlnotify', '-n', 'CoffeeScript', '-p', '2', '-t', "\"Compilation failed\"", '-m', "\"#{message}\""]
    console.error message
    console.error origMessage
  else
    args = ['growlnotify', '-n', 'CoffeeScript', '-p', '-1', '-t', "\"Compilation Succeeded\"", '-m', "\"#{source}\""]
    console.log origMessage
  exec args.join(' ')

task 'build', 'compile Batman.js and all the tools', (options) ->
  for source, target of getCompilationPairs()
    compileScript(source, target, options)
  copyFile("src/tools/batman.coffee", "tools/batman")
  process.exit 0

task 'watch', 'compile Batman.js or the tools when one of the source files changes', (options) ->
  for source, target of getCompilationPairs()
    watchScript(source, target, options)
  console.log "Cake is watching for changes to files."

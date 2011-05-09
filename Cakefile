# Cakefile
# batman
# Copyright Shopify, 2011

CoffeeScript  = require 'coffee-script'
fs            = require 'fs'
path          = require 'path'
glob          = require 'glob'
{exec}        = require 'child_process'

# Following 2 functions are stolen from Jitter, https://github.com/TrevorBurnham/Jitter/blob/master/src/jitter.coffee
# Compiles a script to a destination
compileScript = (source, target, options) ->
  try
    code = fs.readFileSync(source).toString()
    js = CoffeeScript.compile code, {source, bare: options?.bare}
    fs.writeFileSync target, js
    notify source, "Compiled #{source} to #{target} successfully"
  catch err
    notify source, err.message, true

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

# Copies and chmods a file
copyFile = (source, target, mode = 0644) ->
  contents = fs.readFileSync source
  fs.writeFileSync target, contents
  fs.chmodSync(target, mode)
  notify source, "Moved #{source} to #{target} successfully"

CompilationMap =
 'src/batman.coffee'       : (matches) -> compileScript(matches[0], 'lib/batman.js')
 'src/tools/batman.coffee' : (matches) -> copyFile(matches[0], "tools/batman", 0755)
 'src/tools/(.+)\.coffee'  : (matches) -> compileScript(matches[0], "tools/#{matches[1]}.js")

CompilationMap = for pattern, action of CompilationMap
  {pattern: new RegExp(pattern), action: action}

task 'build', 'compile Batman.js and all the tools', (options) ->
  files = glob.globSync('./src/**/*')

  for map in CompilationMap
    set = []
    for i, file of files
      if matches = map.pattern.exec(file)
        set.push matches
        delete files[i]
    for matches in set
      map.action(matches)

  process.exit 0

task 'watch', 'compile Batman.js or the tools when one of the source files changes', (options) ->
  files = glob.globSync('./src/**/*')

  for map in CompilationMap
    for i, file of files
      do (file, map) ->
        if matches = map.pattern.exec(file)
          delete files[i]
          fs.watchFile file, persistent: true, interval: 250, (curr, prev) ->
            return if curr.mtime.getTime() is prev.mtime.getTime()
            map.action(matches)

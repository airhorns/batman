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
compileScript = (source, target, options = {}) ->
  try
    code = fs.readFileSync(source).toString()
    js = CoffeeScript.compile code, {source, bare: options?.bare}
    fs.writeFileSync target, js
    notify source, "Compiled #{source} to #{target} successfully" unless options.notify == false
    true
  catch err
    notify source, err.message, true unless options.notify == false
    false

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
  true

compileMap = (map) ->
  for pattern, action of map
    {pattern: new RegExp(pattern), action: action}

runActions = (args) ->
  compiled = compileMap args.map
  for map in compiled
    set = []
    result = true
    for i, file of args.files
      if matches = map.pattern.exec(file)
        delete args.files[i]
        result = result and map.action(matches)
        if args.options.watch
          do (map, matches) ->
            fs.watchFile file, persistent: true, interval: 250, (curr, prev) ->
              return if curr.mtime.getTime() is prev.mtime.getTime()
              result = map.action(matches)
              args.after() if args.after and result

  args.after() if args.after and result

option '-w', '--watch', 'continue to watch the files and rebuild them when they change'

task 'build', 'compile Batman.js and all the tools', (options) ->
  runActions
    files: glob.globSync './src/**/*'
    options: options
    map:
      'src/batman.coffee'       : (matches) -> compileScript(matches[0], 'lib/batman.js')
      'src/tools/batman.coffee' : (matches) -> copyFile(matches[0], "tools/batman", 0755)
      'src/tools/(.+)\.coffee'  : (matches) -> compileScript(matches[0], "tools/#{matches[1]}.js")
  console.log "Watching src..." if options.watch

task 'test', 'compile Batman.js and the tests and run them on the command line', (options) ->
  temp    = require 'temp'
  runner  = require 'qunit'

  tmpdir = temp.mkdirSync()
  first = false
  runActions
    files: glob.globSync('./src/**/*.coffee').concat(glob.globSync('./tests/**/*.coffee'))
    options: options
    map:
     'src/batman.coffee'               : (matches) -> compileScript(matches[0], "#{tmpdir}/batman.js", {notify: first})
     'tests/batman/(.+)_test.coffee'   : (matches) -> compileScript(matches[0], "#{tmpdir}/#{matches[1]}_test.js", {notify: first})
     'tests/batman/test_helper.coffee' : (matches) -> compileScript(matches[0], "#{tmpdir}/test_helper.js", {notify: first})
    after: ->
      first = true
      runner.run
        code:  "#{tmpdir}/batman.js"
        deps: ["jsdom", "#{tmpdir}/test_helper.js", "./tests/lib/jquery.js"]
        tests: require('glob').globSync("#{tmpdir}/*_test.js")

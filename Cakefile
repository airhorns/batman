# Cakefile
# batman
# Copyright Shopify, 2011

CoffeeScript  = require 'coffee-script'
fs            = require 'fs'
path          = require 'path'
glob          = require 'glob'
{exec}        = require 'child_process'

class SerialJobProcessor
  constructor: ->
    @queueQueue = []
    @queues = {}
    @done = {}
  push: (queue, f) ->
    @queueWithName(queue).push(f)
    @run()
  finished: (queue) ->
    @done[queue] = true
  run: ->
    process.nextTick =>
      queue = @queueQueue[0]
      if queue and f = @queues[queue].shift()
        f()
      else if @done[queue]
        @queueQueue.shift()
      @run() if @queueQueue[0]
  queueWithName: (name) ->
    for existing in @queueQueue
      return @queues[existing] if existing is name
    delete @done[name]
    @queueQueue.push(name)
    @queues[name] ||= []

jobs = new SerialJobProcessor

$extend = (onto, other) ->
  result = onto
  for o in [@,other]
    for k,v of o
      result[k] = v
  result

inRebase = ->
  path.existsSync('.git/rebase-apply')

readFile = (file, options, callback) ->
  if options.commit
    exec "git show :"+file, (err, stdout, stderr) ->
      handleFileError file, err, options, -> callback(stdout)
  else
    fs.readFile file, (err, data) ->
      handleFileError file, err, options, -> callback(data.toString())

writeFile = (file, data, options, callback) ->
  mode = options.mode || 0644
  if options.commit
    jobs.push file, ->
      child = exec "git hash-object --stdin -w", (err, stdout, stderr) ->
        handleFileError file, err, options, ->
          sha = stdout.substr(0,40)
          exec "git update-index --add --cacheinfo 100"+mode.toString(8)+" "+sha+" "+file, (err, stdout, stderr) ->
            handleFileError file, err, options, ->
              jobs.finished(file)
              callback() if callback
      child.stdin.write(data)
      child.stdin.end()
  else
    fs.writeFile file, data, (err) ->
      handleFileError file, err, options, ->
        fs.chmod file, mode, (err) ->
          handleFileError file, err, options, callback
      

handleFileError = (file, err, options, callback) ->
  if err
    jobs.finished(file)
    notify file, err.message, true unless options.notify == false
  else
    callback() if callback

# Following 2 functions are stolen from Jitter, https://github.com/TrevorBurnham/Jitter/blob/master/src/jitter.coffee
# Compiles a script to a destination
compileScript = (source, target, options = {}) ->
  readFile source, options, (data) ->
    try
      js = CoffeeScript.compile data, {source, bare: options?.bare}
      writeFile target, js, options, ->
        notify source, "Compiled #{source} to #{target} successfully" unless options.notify == false
    catch err
      notify source, err.message, true unless options.notify == false
      


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
copyFile = (source, target, options) ->
  readFile source, options, (contents) ->
    writeFile target, contents, options, ->
      notify source, "Moved #{source} to #{target} successfully"

compileMap = (map) ->
  for pattern, action of map
    {pattern: new RegExp(pattern), action: action}

runActions = (args) ->
  compiled = compileMap args.map
  for map in compiled
    set = []
    for i, file of args.files
      if matches = map.pattern.exec(file)
        delete args.files[i]
        map.action(matches)
        if args.options.watch
          do (map, matches) ->
            fs.watchFile file, persistent: true, interval: 250, (curr, prev) ->
              return if curr.mtime.getTime() is prev.mtime.getTime()
              return if inRebase()
              map.action(matches)
              args.after() if args.after

  args.after() if args.after

option '-w', '--watch', 'continue to watch the files and rebuild them when they change'
option '-c', '--commit', 'operate on the git index instead of the working tree'

task 'build', 'compile Batman.js and all the tools', (options) ->
  runActions
    files: glob.globSync './src/**/*'
    options: options
    map:
      'src/batman.coffee'       : (matches) -> compileScript(matches[0], 'lib/batman.js', options)
      'src/batman.nodep.coffee' : (matches) -> compileScript(matches[0], 'lib/batman.nodep.js', options)
      'src/batman.jquery.coffee': (matches) -> compileScript(matches[0], 'lib/batman.jquery.js', options)
      'src/tools/batman.coffee' : (matches) -> copyFile(matches[0], "tools/batman", $extend(options, {mode: 0755}))
      'src/tools/(.+)\.coffee'  : (matches) -> compileScript(matches[0], "tools/#{matches[1]}.js", options)
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
     'src/batman.coffee'               : (matches) -> compileScript(matches[0], "#{tmpdir}/batman.js", $extend {notify: first}, options)
     'src/batman.nodep.coffee'         : (matches) -> compileScript(matches[0], "#{tmpdir}/batman.nodep.js", $extend {notify: first}, options)
     'tests/batman/(.+)_test.coffee'   : (matches) -> compileScript(matches[0], "#{tmpdir}/#{matches[1]}_test.js", $extend {notify: first}, options)
     'tests/batman/test_helper.coffee' : (matches) -> compileScript(matches[0], "#{tmpdir}/test_helper.js", $extend {notify: first}, options)
    after: ->
      first = true
      runner.run
        code:  "#{tmpdir}/batman.js"
        deps: ["#{tmpdir}/batman.nodep.js", "jsdom", "#{tmpdir}/test_helper.js", "./tests/lib/jquery.js"]
        tests: require('glob').globSync("#{tmpdir}/*_test.js")

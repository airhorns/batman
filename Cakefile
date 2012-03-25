# Cakefile
# batman
# Copyright Shopify, 2011

muffin       = require 'muffin'
path         = require 'path'
q            = require 'q'
glob         = require 'glob'
{exec, fork, spawn} = require 'child_process'

option '-w', '--watch',  'continue to watch the files and rebuild them when they change'
option '-c', '--commit', 'operate on the git index instead of the working tree'
option '-d', '--dist',   'compile minified versions of the platform dependent code into lib/dist (build task only)'
option '-m', '--compare', 'compare to git refs (stat task only)'
option '-s', '--coverage', 'run jscoverage during tests and report coverage (test task only)'

pipedExec = do ->
  running = false
  pipedExec = (args..., callback) ->
    if !running
      running = true
      child = spawn 'node', args
      process.on 'exit', exitListener = -> child.kill()
      child.stdout.on 'data', (data) -> process.stdout.write data
      child.stderr.on 'data', (data) -> process.stderr.write data
      child.on 'exit', (code) ->
        process.removeListener 'exit', exitListener
        running = false
        callback(code)

task 'build', 'compile Batman.js and all the tools', (options) ->
  files = glob.sync('./src/**/*').concat(glob.sync('./tests/lib/*'))
  muffin.run
    files: files
    options: options
    map:
      'src/batman\.coffee'       : (matches) -> muffin.compileScript(matches[0], 'lib/batman.js', options)
      'src/batman\.(.+)\.coffee' : (matches) -> muffin.compileScript(matches[0], "lib/batman.#{matches[1]}.js", options)
      'src/extras/(.+)\.coffee'  : (matches) -> muffin.compileScript(matches[0], "lib/extras/#{matches[1]}.js", options)
      'src/tools/batman\.coffee' : (matches) ->
        source = muffin.readFile(matches[0], options).then (source) ->
          compiled = muffin.compileString(source, options)
          compiled = "#!/usr/bin/env node\n\n" + compiled
          muffin.writeFile "tools/batman", compiled, muffin.extend({}, options, {mode: 0755})
      'src/tools/(.+)\.coffee'   : (matches) -> muffin.compileScript(matches[0], "tools/#{matches[1]}.js", options)
      'tests/run\.coffee'     : (matches) -> muffin.compileScript(matches[0], 'tests/run.js', options)

  if options.dist
    temp    = require 'temp'
    tmpdir = temp.mkdirSync()
    distDir = "lib/dist"
    developmentTransform = require('./tools/build/remove_development_transform').removeDevelopment

    # Compile the scripts to the distribution folder by:
    # 1. Finding each platform specific batman file of the form `batman.platform.coffee`
    # 2. Concatenating each platform specific file with the main Batman source, and storing that in memory
    # 3. Compiling each complete platform specific batman distribution into JavaScript in `./lib/dist`
    # 4. Minify each complete platform specific distribution in to a .min.js file in `./lib/dist`
    compileDist = (platformName) ->
      return if platformName in ['node']
      joinedCoffeePath = "#{tmpdir}/batman.#{platformName}.coffee"
      # Read the platform specific code
      platform = muffin.readFile "src/batman.#{platformName}.coffee", options
      standard = muffin.readFile 'src/batman.coffee', options
      q.join platform, standard, (platformSource, standardSource) ->
        # Compile the joined coffeescript to JS
        js = muffin.compileString(standardSource + "\n" + platformSource, options)
        destination = "#{distDir}/batman#{if platformName is 'solo' then '' else '.' + platformName}.js"
        # Write the unminified javascript.
        muffin.writeFile(destination, js, options).then ->
          options.transform = developmentTransform
          muffin.minifyScript(destination, options).then( ->
            muffin.notify(destination, "File #{destination} minified.")
          )

    # Run a task which concats the coffeescript, compiles it, and then minifies it
    first = true
    muffin.run
      files: './src/**/*'
      options: options
      map:
        'src/batman\.(.+)\.coffee': (matches) -> compileDist(matches[1])
        'src/batman.coffee'       : (matches) ->
          done = false
          if first
            first = false
            return
          # When the the root batman file changes, compile all the platform files.
          platformFiles = glob.sync('./src/batman.*.coffee')
          for file in platformFiles
            matches = /src\/batman.(.+).coffee/.exec(file)
            done = q.wait(done, compileDist(matches[1]))
          console.warn done
          done

task 'doc', 'build the Percolate documentation', (options) ->
  muffin.run
    files: './docs/**/*'
    options: options
    map:
      'docs/percolate\.coffee'  : (matches) -> muffin.compileScript(matches[0], 'docs/percolate.js', options)
      'docs/js/docs.coffee'     : (matches) -> muffin.compileScript(matches[0], 'docs/js/docs.js', options)
      '(.+).percolate'          : -> true
    after: ->
      pipedExec 'docs/percolate.js', options, (code) ->
        process.exit(code) unless options.watch

task 'test', 'compile Batman.js and the tests and run them on the command line', (options) ->
  running = false
  muffin.run
    files: glob.sync('./src/**/*.coffee').concat(glob.sync('./tests/**/*.coffee'))
    options: options
    map:
      'src/batman(.node)?.coffee'                : (matches) -> true
      'src/extras/(.+).coffee'                   : (matches) -> true
      'tests/batman/(.+)_(test|helper).coffee'   : (matches) -> true
      'tests/run.coffee'                         : (matches) -> muffin.compileScript(matches[0], 'tests/run.js', options)
    after: ->
      failFast = (code) ->
        if !options.watch
          process.exit code if code != 0

      pipedExec 'tests/run.js', (code) ->
        failFast(code)
        pipedExec 'docs/percolate.js', '--test-only', (code) ->
          failFast(code)

task 'stats', 'compile the files and report on their final size', (options) ->
  muffin.statFiles(glob.sync('./src/**/*.coffee').concat(glob.sync('./lib/**/*.js')), options)

task 'build:site', (options) ->
  temp    = require 'temp'
  tmpdir = temp.mkdirSync()
  docFiles = ["docs/css/**/*.css", "docs/css/fonts/*", "docs/img/**/*", "docs/js/**/*.js", "docs/batman.html"]
    .reduce( ((a, b) -> a.concat(glob.sync b)) , [] )
    .map((f) -> path.join(__dirname, f))
  console.warn docFiles
  console.warn tmpdir
  cmd = " #{("mkdir -p #{path.dirname(file.replace __dirname, tmpdir)} && cp #{file} #{file.replace __dirname, tmpdir}" for file in docFiles).join ' && '}
          && git checkout gh-pages
          && rm -rf docs
          && cp -r #{tmpdir}/docs docs
          && git add docs
          && git commit -m 'Add new docs.'
          && git checkout master"

  exec cmd, (error, stdout, stderr) ->
    console.warn stdout.toString()
    console.warn stderr.toString()
    throw error if error

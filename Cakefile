# Cakefile
# batman
# Copyright Shopify, 2011

muffin = require 'muffin'
fs     = require 'fs'
q      = require 'q'
glob   = require 'glob'
path   = require 'path'


option '-w', '--watch',  'continue to watch the files and rebuild them when they change'
option '-c', '--commit', 'operate on the git index instead of the working tree'
option '-d', '--dist',   'compile minified versions of the platform dependent code into lib/dist (build task only)'
option '-m', '--compare', 'compare to git refs (stat task only)'
option '-s', '--coverage', 'run jscoverage during tests and report coverage (test task only)'

task 'build', 'compile Batman.js and all the tools', (options) ->
  files = glob.sync('./src/**/*')
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

task 'doc', 'build the Docco documentation', (options) ->
  muffin.run
    files: './src/**/*'
    options: options
    map:
      'src/batman.coffee': (matches) -> muffin.doccoFile(matches[0], options)

task 'test', 'compile Batman.js and the tests and run them on the command line', (options) ->
  temp    = require 'temp'
  runner  = require 'qunit'
  runner.options.coverage = false
  tmpdir = temp.mkdirSync()
  first = true
  extras = []
  muffin.run
    files: glob.sync('./src/**/*.coffee').concat(glob.sync('./tests/**/*.coffee'))
    options: options
    map:
      'src/batman.coffee'                        : (matches) -> muffin.compileScript(matches[0], "#{tmpdir}/batman.js", muffin.extend({notify: !first}, options))
      'src/batman.node.coffee'                   : (matches) -> muffin.compileScript(matches[0], "#{tmpdir}/batman.node.js", muffin.extend({notify: !first}, options))
      'tests/batman/(.+)_(test|helper).coffee'   : (matches) -> muffin.compileScript(matches[0], "#{tmpdir}/tests/batman/#{matches[1]}_#{matches[2]}.js", muffin.extend({notify: !first}, options))
      'src/extras/(.+).coffee'                   : (matches) ->
        extras.push destination = "#{tmpdir}/extras/#{matches[1]}.js"
        muffin.compileScript(matches[0], destination, muffin.extend({notify: !first}, options))
    after: ->
      first = false
      alltests = glob.sync("#{tmpdir}/tests/**/*_test.js")
      tests = alltests.slice(0, 5)
      tests.push(alltests[7])
      console.warn tests
      runner.run
        code:  {namespace: "Batman", path: "#{tmpdir}/batman.node.js"}
        deps: ["jsdom", "#{tmpdir}/tests/batman/test_helper.js", "./tests/lib/jquery.js"]
        tests: tests
        coverage: options.coverage || false
      , (report) ->
        unless options.watch
          exit = -> process.exit report.errors
          unless process.stdout.flush()
            process.stdout.once 'drain', exit
          else
            exit

task 'stats', 'compile the files and report on their final size', (options) ->
  muffin.statFiles(glob.sync('./src/**/*.coffee').concat(glob.sync('./lib/**/*.js')), options)

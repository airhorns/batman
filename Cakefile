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

task 'build', 'compile Batman.js and all the tools', (options) ->
  muffin.run
    files: './src/**/*'
    options: options
    map:
      'src/batman\.coffee'       : (matches) -> muffin.compileScript(matches[0], 'lib/batman.js', options)
      'src/batman\.(.+)\.coffee' : (matches) -> muffin.compileScript(matches[0], "lib/batman.#{matches[1]}.js", options)
      'src/tools/batman\.coffee' : (matches) -> muffin.compileScript(matches[0], "tools/batman", muffin.extend({bare: true}, options, {mode: 755}))
      'src/tools/(.+)\.coffee'   : (matches) -> muffin.compileScript(matches[0], "tools/#{matches[1]}.js", options)

  if options.dist
    temp    = require 'temp'
    tmpdir = temp.mkdirSync()
    distDir = "lib/dist"
    # Run a task which concats the coffeescript, compiles it, and then minifies it
    muffin.run
      files: './src/**/*'
      options: options
      map:

        # Compile the scripts to the distribution folder by:
        # 1. Finding each platform specific batman file of the form `batman.platform.coffee`
        # 2. Concatenating each platform specific file with the main Batman source, and storing that in a temp file.
        # 3. Compiling each complete platform specific batman distribution into JavaScript in `./lib/dist`
        # 4. Minify each complete platform specific distribution in to a .min.js file in `./lib/dist`
        'src/batman\.(.+)\.coffee' : (matches) ->
          return if matches[1] == 'node'
          joinedCoffeePath = "#{tmpdir}/batman.#{matches[1]}.coffee"

          # Read the platform specific code
          platform = muffin.readFile matches[0], options
          standard = muffin.readFile 'src/batman.coffee', options
          q.join platform, standard, (platformSource, standardSource) ->
            # Write the joined coffeescript to a temp dir
            write = muffin.writeFile(joinedCoffeePath, standardSource + "\n" + platformSource, options)
            q.when write, (result) -> 
              # Compile the temp coffeescript to the build dir
              fs.mkdirSync(distDir, 0777) unless path.existsSync(distDir)
              destination = "#{distDir}/batman.#{matches[1]}.js"
              compile = muffin.compileScript(joinedCoffeePath, destination, options)
              q.when compile, ->
                muffin.minifyScript destination, options

task 'doc', 'build the Docco documentation', (options) ->
  muffin.run
    files: './src/**/*'
    options: options
    map:
      'src/batman.coffee': (matches) -> muffin.doccoFile(matches[0], options)

task 'test', 'compile Batman.js and the tests and run them on the command line', (options) ->
  temp    = require 'temp'
  runner  = require 'qunit'

  tmpdir = temp.mkdirSync()
  first = false

  muffin.run
    files: glob.globSync('./src/**/*.coffee').concat(glob.globSync('./tests/**/*.coffee'))
    options: options
    map:
     'src/batman.coffee'               : (matches) -> muffin.compileScript(matches[0], "#{tmpdir}/batman.js", muffin.extend {notify: first}, options)
     'src/batman.nodep.coffee'         : (matches) -> muffin.compileScript(matches[0], "#{tmpdir}/batman.nodep.js", muffin.extend {notify: first}, options)
     'tests/batman/(.+)_test.coffee'   : (matches) -> muffin.compileScript(matches[0], "#{tmpdir}/#{matches[1]}_test.js", muffin.extend {notify: first}, options)
     'tests/batman/test_helper.coffee' : (matches) -> muffin.compileScript(matches[0], "#{tmpdir}/test_helper.js", muffin.extend {notify: first}, options)
    after: ->
      first = true
      runner.run
        code:  {namespace: "Batman", code: "#{tmpdir}/batman.js"}
        deps: ["jsdom", "#{tmpdir}/test_helper.js", "./tests/lib/jquery.js"]
        tests: glob.globSync("#{tmpdir}/*_test.js")

task 'stats', 'compile the files and report on their final size', (options) ->
  muffin.statFiles(glob.globSync('./src/**/*.coffee').concat(glob.globSync('./lib/**/*.js')), options)

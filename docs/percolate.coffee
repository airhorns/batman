glob = require 'glob'
path = require 'path'
fs = require 'fs'
coffee = require 'coffee-script'

# Load test runner
qqunit = require 'qqunit'
oldErrorHandler = window.onerror
delete window.onerror

# Load percolate
percolate = require 'percolate'

testDir = path.resolve(__dirname, '..', 'tests')
jqueryPath = path.join(testDir, 'lib', 'jquery.js')

qqunit.Environment.jsdom.jQueryify window, jqueryPath, (window, jQuery) ->
  try
    global.jQuery = jQuery

    # Load test helper
    Helper = require "#{testDir}/batman/test_helper"
    global[k] = v for own k,v of Helper

    global.Batman = require '../src/batman.node'
    Batman.exportGlobals(global)
    Batman.Request::send = -> throw new Error "Can't send requests during tests!"

    docs = glob.sync("#{__dirname}/**/*.percolate").map (doc) -> path.resolve(process.cwd(), doc)

    console.log "Running Batman doc suite."
    if process.argv[2] == '--test-only'
      percolate.test __dirname, docs..., (error, stats) ->
        process.exit stats.failed
    else
      percolate.generate __dirname, docs..., (error, stats, output) ->
        throw error if error
        fs.writeFileSync path.join(__dirname, 'batman.html'), output unless stats.failed > 0
        console.log "Docs written."
        process.exit stats.failed
  catch e
    console.error e.stack
    process.exit(1)

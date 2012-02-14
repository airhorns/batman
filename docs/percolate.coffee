glob = require 'glob'
path = require 'path'

# Load test runner
qqunit = require 'qqunit'

# Load percolate
percolate = require 'percolate'

testDir = path.resolve(__dirname, '..', 'tests')
jqueryPath = path.join(testDir, 'lib', 'jquery.js')

qqunit.Environment.jsdom.jQueryify window, jqueryPath, (window, jQuery) ->
  global.jQuery = jQuery

  # Load test helper
  Helper = require "#{testDir}/batman/test_helper"
  global[k] = v for own k,v of Helper

  global.Batman = require '../src/batman.node'
  Batman.exportGlobals(global)
  Batman.Request::send = -> throw new Error "Can't send requests during tests!"

  docs = glob.sync("#{__dirname}/**/*.percolate").map (doc) -> path.resolve(process.cwd(), doc)

  console.log "Running Batman doc suite."
  percolate.generate docs..., (error, stats, output) ->
    throw error if error
    console.warn output
    process.exit stats.failed

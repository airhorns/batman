fs     = require 'fs'
temp   = require 'temp'
path   = require 'path'
glob   = require 'glob'
{exec} = require 'child_process'

tmpDir = temp.mkdirSync()

# Clone repo to tmpdir
exec "git clone #{path.resolve(__dirname, '../../')} #{tmpDir}", (err, stdout, stderr) ->
  throw err if err
  console.log stdout.toString()

  shas = process.argv.slice(2)

  doSHA = ->
    sha = shas.pop()
    return unless sha
    exec "cd #{tmpDir}; git co #{sha}", (err, stdout, stderr) ->
     throw err if err
     console.log "Checked out #{sha}."

  doSHA()

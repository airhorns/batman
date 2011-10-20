Batman = require './../../../lib/batman'
Watson = require 'watson'

hash = new Batman.Hash

Watson.trackMemory 'hash memory usage', 3000, (i) ->
  hash.set i, new Batman.Object
  if i == 2000
    hash.clear()

simpleHash = new Batman.SimpleHash

Watson.trackMemory 'simple hash memory usage', 3000, (i) ->
  simpleHash.set i, new Batman.Object
  if i == 2000
    simpleHash.clear()

Batman = require '../../../../lib/batman'
Watson = require 'watson'
Clunk  = require '../lib/clunk'

simpleHash = new Batman.SimpleHash

Watson.trackMemory 'simple hash memory usage', 10000, (i) ->
  simpleHash.set i, new Clunk
  if i % 2000 == 0
    simpleHash.clear()


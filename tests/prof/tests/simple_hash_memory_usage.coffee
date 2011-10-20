Batman = require './../../../lib/batman'
Watson = require 'watson'

simpleHash = new Batman.SimpleHash

Watson.trackMemory 'simple hash memory usage', 3000, (i) ->
  simpleHash.set i, new Batman.Object
  if i == 2000
    simpleHash.clear()


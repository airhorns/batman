Batman = require '../../../../lib/batman'
Watson = require 'watson'
Clunk  = require '../lib/clunk'

hash = new Batman.SimpleHash

Watson.trackMemory 'simple hash memory usage with strings', 10000, (i) ->
  hash.set ""+i, new Clunk
  if i % 2000 == 0
    hash.clear()

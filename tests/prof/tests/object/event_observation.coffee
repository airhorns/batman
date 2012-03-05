Batman = require '../../../../lib/batman'
Watson = require 'watson'
TestStorageAdapter = require '../lib/test_storage_adapter'
Clunk  = require '../lib/clunk'

clunks = []
observerA = ->
observerB = ->
clunks.push(new Clunk(foo: i)) for i in [0..2000]

Watson.trackMemory 'observer attachement memory usage', 2000, (i) ->
  clunk = clunks[i]
  clunk.observe 'foo', observerA
  clunk.on 'explode', observerB

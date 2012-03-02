Batman = require '../../../../lib/batman'
Watson = require 'watson'
TestStorageAdapter = require '../lib/test_storage_adapter'
Clunk  = require '../lib/clunk'

clunks = []
observerA = ->
observerB = ->

Watson.trackMemory 'object instantiation with observers memory usage', 2000, (i) ->
  clunks.push clunk = new Clunk(foo: i)
  clunk.observe 'foo', observerA
  clunk.on 'explode', observerB

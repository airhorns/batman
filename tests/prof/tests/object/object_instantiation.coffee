Batman = require '../../../../lib/batman'
Watson = require 'watson'
TestStorageAdapter = require '../lib/test_storage_adapter'
Clunk  = require '../lib/clunk'

clunks = []

Watson.trackMemory 'object instantiation memory usage', 2000, (i) ->
  clunks.push new Clunk(foo: i)

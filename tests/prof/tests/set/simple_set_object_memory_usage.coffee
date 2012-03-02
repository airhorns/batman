Batman = require '../../../../lib/batman'
Watson = require 'watson'
Clunk  = require '../lib/clunk'

set = new Batman.SimpleSet

Watson.trackMemory 'simple set memory usage with objects', 10000, (i) ->
  set.add new Clunk
  if i % 2000 == 0
    set.clear()

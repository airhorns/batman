Batman = require './../../../lib/batman'
Watson = require 'watson'

set = new Batman.SimpleSet

Watson.trackMemory 'simple set memory usage', 3000, (i) ->
  Set.add new Batman.Object
  if i == 2000
    set.clear()

Batman = require '../../../../lib/batman'
Watson = require 'watson'
Clunk  = require '../lib/clunk'
Random = require '../lib/number_generator'

# Batman.Set::indexedBy(key) returns a Batman.SetIndex
Watson.ensureCommitted '540d76c21a03212d843b632bdad9e61c3b6d2b8a', ->

  ITERATONS = 10000

  generator = new Random(0, 10, 3000)
  clunks = (new Clunk(foo: generator.next()) for i in [0..ITERATONS])

  set = new Batman.Set
  index = set.indexedBy('foo')

  Watson.trackMemory 'set index memory usage', ITERATONS, 100, (i) ->
    set.add clunks[i]
    if i % 500 == 0
      set.clear()

    array = index.get('toArray')

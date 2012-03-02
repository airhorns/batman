Batman = require '../../../../../lib/batman'
Watson = require 'watson'
Clunk  = require '../lib/clunk'
Random = require '../lib/number_generator'

# 69ad8b18908c0171601db7198ffe5e78c73095ee
# Batman.Set::sortedBy(key) and associated accessor
Watson.ensureCommitted '69ad8b18908c0171601db7198ffe5e78c73095ee', ->

  Watson.benchmark 'set sorting', (error, suite) ->
    throw error if error

    do ->
      generator = new Random(0, 1000, 5355074)
      set = new Batman.Set
      set.add new Clunk(foo: generator.next()) for i in [0...1000]

      suite.add 'sorting on integers', ->
        (new Batman.SetSort(set, 'foo')).toArray()

    do ->
      letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g']
      generator = new Random(0, letters.length, 123123)
      set = new Batman.Set

      for i in [0...1000]
        name = (letters[generator.next()] for j in [0..6]).join('')
        set.add new Clunk(foo: name)

      suite.add 'sorting on strings', ->
        (new Batman.SetSort(set, 'foo')).toArray()

    suite.run()

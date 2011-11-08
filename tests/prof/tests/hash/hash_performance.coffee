Batman = require '../../../../lib/batman'
Watson = require 'watson'
Clunk  = require '../lib/clunk'
Random = require '../lib/number_generator'

generator = new Random(0, 10, 2000)
clunks = (new Clunk(number: generator.next()) for i in [0...100])

Watson.benchmark 'hash performance', (error, suite) ->
  throw error if error

  do ->
    hash = new Batman.Hash
    suite.add 'object-key setting', () ->
      for clunk in clunks
        hash.set clunk, true for i in [0..100]
      true

  do ->
    hash = new Batman.Hash
    hash.set clunk, clunk.get('number') for clunk in clunks

    suite.add 'object-key retrieval', () ->
      for clunk in clunks
        hash.get(clunk) for i in [0..100]
      true

    suite.run()

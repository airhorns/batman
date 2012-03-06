Batman = require '../../../../lib/batman'
Watson = require 'watson'
Clunk  = require '../lib/clunk'
Random = require '../lib/number_generator'

Watson.benchmark 'object instantiation', (error, suite) ->
  throw error if error

  do ->
    suite.add 'vanilla object creation', () ->
      new Batman.Object() for i in [0..1000]
      true

  do ->
    suite.add 'clunk creation', () ->
      new Clunk({i}) for i in [0..200]
      true

  suite.run()

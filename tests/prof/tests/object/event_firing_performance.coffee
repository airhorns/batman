Batman = require '../../../../lib/batman'
Watson = require 'watson'
Clunk  = require '../lib/clunk'
Random = require '../lib/number_generator'

Watson.benchmark 'event firing', (error, suite) ->
  throw error if error

  do ->
    clunks = (new Clunk({i}) for i in [0..200])
    suite.add 'once per object', ->
      for clunk in clunks
        clunk.fire('foo')
      true

  do ->
    clunk = new Clunk({i: 0})
    suite.add 'many on same object', ->
      clunk.fire('foo') for i in [0..200]
      true

  do ->
    clunks = for i in [0..200]
      clunk = new Clunk {i}
      clunk.on 'foo', (newer, older) ->
      clunk

    suite.add 'once per object with one handler', ->
      for clunk in clunks
        clunk.fire('foo')
      true

  do ->
    clunk = new Clunk({i: 0})
    clunk.on 'foo', (newer, older) ->

    suite.add 'many on same object with one handler', ->
      clunk.fire('foo') for i in [0..200]
      true

  do ->
    clunks = for i in [0..200]
      clunk = new Clunk {i}
      for j in [0..10]
        clunk.on 'foo', (newer, older) ->
      clunk

    suite.add 'once per object with ten handlers', ->
      for clunk in clunks
        clunk.fire('foo')
      true

  do ->
    clunk = new Clunk({i: 0})
    for j in [0..10]
      clunk.on 'foo', (newer, older) ->

    suite.add 'many on same object with ten handlers', ->
      clunk.fire('foo') for i in [0..200]
      true

  suite.run()

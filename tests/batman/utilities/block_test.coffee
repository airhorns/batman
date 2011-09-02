QUnit.module "Batman._block"

test "should allow blockizing of functions with take only a callback", 1, ->
  class Test
    method: Batman._block (callback) ->
      callback()

  (new Test).method()(-> ok true)

test "should allow blockizing of functions which take arguments and a callback", 3, ->
  class Test
    method: Batman._block (arg1, arg2, callback) ->
      equal arg1, "foo"
      equal arg2, 2
      callback()

  (new Test).method("foo", 2)(-> ok true)

test "should preserve the context in which the function is called", 1, ->
  ctx = false

  class Test
    getContext: ->
      @
    method: Batman._block (arg, callback) ->
      equal arg, @

  x = new Test
  ctx = x.getContext()
  x.method(ctx)(->)


test "should allow the callback to be passed as the last argument", 2, ->
  x = ->
  class Test
    method: Batman._block (arg, callback) ->
      equal arg, true
      equal callback, x

  (new Test).method(true, x)

test "should allow the airty to be specified so non function arguments can be passed and still trigger the call", 2, ->
  class Test
    method: Batman._block(2, (arg, anotherArg) ->
      equal arg, true
      equal anotherArg, false
    )

  (new Test).method(true, false)

QUnit.module "Batman.StateMachine",
  setup: ->
    @sm = new Batman.Object Batman.StateMachine

test "should fire state callback", 1, ->
  @sm.state 'test', (state) ->
    equal(state, 'test', 'test called')

  @sm.test()

test "should fire transition callback", 2, ->
  @sm.transition 'test', 'test2', (state, oldState) ->
    equal state, 'test2', 'new state set'
    equal oldState, 'test', 'old state removed'

  @sm.test()
  @sm.test2()

test "should pause subsequent state changes", 2, ->
  @sm.state 'newState', =>
    @sm.oldState()
    equal(@sm.state(), 'newState')

  @sm.state 'oldState', =>
    equal(@sm.state(), 'oldState')

  @sm.newState()

test "state machine has accessors", 2, ->
  @sm.state 'test', ->
    ok(true, 'state called')

  @sm.set 'state', 'test'
  equal @sm.get('state'), 'test'

test "state machine class", 1, ->
  class SM extends Batman.Object
    @actsAsStateMachine yes
    @state 'foo', -> ok(true)

  sm = new SM
  sm.foo()


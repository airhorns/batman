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

test "state machine class", 1, ->
  class SM extends Batman.Object
    @actsAsStateMachine yes
    @state 'foo', -> ok(true)

  sm = new SM
  sm.foo()



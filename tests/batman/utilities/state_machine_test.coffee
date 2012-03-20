QUnit.module "Batman.StateMachine"
  setup: ->
    class @SwitchStateMachine extends Batman.StateMachine
      @transitions
        switch: {on: 'off', off: 'on'}
        switchOn: {off: 'on'}

    @sm = new @SwitchStateMachine 'on'

test "should start in the inital state given", ->
  equal 'on', @sm.get('state')

test "should accept a transition table in the constructor", ->
  equal @sm.get('state'), 'on'
  @sm.switch()
  equal @sm.get('state'), 'off'
  @sm.switch()
  equal @sm.get('state'), 'on'
  @sm.do('switch') # transitions can be called using strings as well
  equal @sm.get('state'), 'off'

  ok @sm.canDo('switch')
  ok @sm.canDo('switchOn')

test "should not allow transitions which aren't in the table", ->
  equal @sm.get('state'), 'on'
  equal @sm.switchOn(), false
  equal @sm.get('state'), 'on'

  ok !@sm.canDo('switchOn')
  ok !@sm.canDo('nonExistant'), "Non existant events can't be done"

test "should allow observing state entry", 2, ->
  @sm.onEnter 'off', =>
    ok true, 'callback is called'
    equal @sm.get('state'), 'off', 'State should have set when enter callback fires'

  @sm.switch()

test "should allow observing state exit", 2, ->
  @sm.onExit 'on', =>
    ok true, 'callback is called'
    equal @sm.get('state'), 'on', 'State should not have changed when callback fires'
  @sm.switch()

test "should allow observing events", 2, ->
  @sm.on 'switch', =>
    ok true, 'callback is called'
    equal @sm.get('state'), 'on', 'State should not have changed when callback fires'
  @sm.switch()

test "should allow observing state transition", 2, ->
  @sm.onTransition 'on', 'off', =>
    ok true, 'callback is called'
    equal @sm.get('state'), 'on', 'State should not have changed when callback fires'
  @sm.switch()

test "should allow transitioning into the same state", 3, ->
  class Silly extends Batman.StateMachine
    @transitions sillySwitch: {on: 'on'}

  @sm = new Silly 'on'

  @sm.onExit 'on', exitSpy = createSpy()
  @sm.onTransition 'on', 'on', transitionSpy = createSpy()
  @sm.onEnter 'on', enterSpy = createSpy()

  @sm.sillySwitch()

  ok exitSpy.called
  ok transitionSpy.called
  ok enterSpy.called

test "should allow changing the state in callbacks", 5, ->
  @sm.onExit 'on', =>
    @sm.switch()

  callOrder = []
  @sm.onTransition 'on', 'off', transitionToOffSpy = createSpy()
  @sm.onEnter 'off', enterOffSpy = createSpy()
  @sm.onExit 'off', exitOffSpy = createSpy()
  @sm.onTransition 'off', 'on', transitionToOnSpy = createSpy()
  @sm.onEnter 'on', enterOnSpy = createSpy()

  @sm.switch()

  ok transitionToOnSpy.called
  ok enterOffSpy.called
  ok exitOffSpy.called
  ok transitionToOnSpy.called
  ok enterOnSpy.called

test "should recognize the shorthand for many incoming states converging to one", 3, ->
  class ArrayTest extends Batman.StateMachine
    @transitions
      fade:
        from: ['on', 'half']
        to: 'off'
      flick: {off: 'half'}

  @sm = new ArrayTest('on')
  @sm.fade()
  equal @sm.get('state'), 'off'
  @sm.flick()
  equal @sm.get('state'), 'half'
  @sm.fade()
  equal @sm.get('state'), 'off'

test "subclasses should inherit transitions", 2, ->
  class TwoWaySwitch extends @SwitchStateMachine
    @transitions
      switchOff: {on: 'off'}

  @sm = new TwoWaySwitch('on')
  @sm.switchOff()
  equal @sm.get('state'), 'off'
  @sm.switchOn()
  equal @sm.get('state'), 'on'

test "accessors should be able to source state", 2, ->
  x = Batman(sm: @sm)
  x.accessor 'foo', -> @get('sm.state').toUpperCase()

  equal x.get('foo'), 'ON'
  @sm.switch()
  equal x.get('foo'), 'OFF'

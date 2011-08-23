Batman.exportHelpers(this)

QUnit.module "$mixin"
  setup: ->
    @base = {x: "x"}

test "should copy properties from the source to the destination", ->
  deepEqual {x: "y", y: "y"}, $mixin(@base, {x: "y"}, {y: "y"})

test "shouldn't affect the source objects", ->
  more = x: "y"
  $mixin @base, more
  deepEqual more, x: "y"

test "initializers get run and not mixed in", ->
  obj =
    initialize: createSpy()
    uninitialize: ->

  $mixin @base, obj
  ok obj.initialize.called
  ok !@base.initialize
  ok !@base.uninitialize

test "should only initialize objects which have a function initializer", ->
  obj =
    initialize: "x"

  $mixin @base, obj
  ok true, "Initializer wasn't called because no error was thrown"

test "should use set on objects which have it defined", ->
  obj = {}
  spyOn obj, 'set'

  $mixin obj, x: "y"
  deepEqual obj.set.lastCallArguments, ["x", "y"]

QUnit.module "$unmixin",
  setup: ->
    @base =
      x: "x"
      y: "y"
      z: "z"

test "should remove properties on the from that exist on the sources", ->
  deepEqual {z: 'z'}, $unmixin(@base, {x: 'x'}, {y: 'y'})

QUnit.module "$event"

test "ephemeral events", ->
  event = $event ->
  ok event.isEvent

QUnit.module "$events on Batman.Object: prototype events"
  setup: ->
    @oneMethodObserver = a = createSpy()
    @oneRedeclaredObserver = b = createSpy()
    @twoMethodObserver = c = createSpy()
    @twoRedeclaredObserver = d = createSpy()

    class One extends Batman.Object
      method: @event ->
      @observeAll "method", a

      redeclaredMethod: @event ->
      @observeAll "redeclaredMethod", b

    class Two extends One
      # Redeclare a new event with the same key
      redeclaredMethod: @event ->

      @observeAll "method", c
      @observeAll "redeclaredMethod", d

    @one = new One
    @two = new Two

test "should be declarable", ->
  class Emitter extends Batman.Object
    foo: @event ->

  e = new Emitter
  ok e.foo.isEvent

test "should fire observers attached to the prototype", ->
  @one.method("foo")
  equal @oneMethodObserver.callCount, 1
  equal @twoMethodObserver.callCount, 0

  @two.method("foo")
  equal @oneMethodObserver.callCount, 2
  equal @twoMethodObserver.callCount, 1

test "should fire observers for redeclared methods", ->
  @one.redeclaredMethod("foo")
  equal @oneRedeclaredObserver.callCount, 1
  equal @twoRedeclaredObserver.callCount, 0

  @two.redeclaredMethod("foo")
  equal @oneRedeclaredObserver.callCount, 2
  equal @twoRedeclaredObserver.callCount, 1

QUnit.module "$events on Batman.Object: class events"
test "class events", ->
  class Emitter extends Batman.Object
    @foo: @event ->

  ok Emitter.foo.isEvent

QUnit.module "$events on Batman.Object: instance events"

test "instance events", ->
  foo = new Batman.Object
  foo.event 'bar', ->
  ok foo.bar.isEvent

test "should create an event with an action", ->
  event = $event callback = ->

  ok event.isEvent
  strictEqual event.action, callback

test "should maintain return value and arguments for observers", ->
  event = $event (x) -> x * 2
  observer = createSpy()

  event(observer)
  equal event(2), 4
  deepEqual observer.lastCallArguments, [4, 2] # result of event function, followed by original argument

test "return false from event should not fire observers", ->
  event = $event -> false
  event observer = createSpy()
  event true

  equal observer.called, false

test "should return the result of the original function", ->
  event = $event -> "y"
  equal event(), "y"

test "should add observers when passed functions, without calling the original", ->
  event = $event original = createSpy()
  event(->) && event(->)
  equal original.callCount, 0

test "should fire more than once if not oneShot", ->
  event = $event ->
  event observer = createSpy()

  event 1
  event true

  equal observer.callCount, 2

QUnit.module "$eventOneShot"

test "should fire exactly once", ->
  event = $eventOneShot ->
  event observer = createSpy()
  ok event.isOneShot

  event 1
  event true

  equal observer.callCount, 1
  ok event.oneShotFired(), 'event marked itself as fired'

test "should not fire another instance's oneShot event", ->
  class A extends Batman.Object
    single: @eventOneShot ->
  class B extends A

  a = new A
  b = new B

  ok !a.oneShotFired('single')
  ok !b.oneShotFired('single')

  resultA = a.single()

  ok a.oneShotFired('single')
  ok !b.oneShotFired('single')

test "should fire handlers added after the first fire immediately and pass the original arguments in", ->
  event = $eventOneShot -> "result"
  event false, 2

  event (observer = createSpy())

  equal observer.callCount, 1
  deepEqual observer.lastCallArguments, ["result", false, 2]

test "oneShotEvents shouldn't fire each other", ->
  one = $eventOneShot -> "result"
  two = $eventOneShot -> "result"

  one (oneObserver = createSpy())
  two (twoObserver = createSpy())

  one "args", "which", "fire"

  equal oneObserver.callCount, 1
  equal twoObserver.callCount, 0

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


QUnit.module "_Batman",
  setup: ->
    class @Animal extends Batman.Object
      Batman.initializeObject @::

    class @Snake extends @Animal
      Batman.initializeObject @::

    class @BlackMamba extends @Snake
      Batman.initializeObject @::

    @mamba = new @BlackMamba()
    @snake = new @Snake()
    true

deepSortedEqual = (a,b,message) ->
  deepEqual(a.sort(), b.sort(), message)

test "correct ancestors are returned", ->
  deepEqual @snake._batman.object, @snake
  expected = [@Snake::, @Animal::, Batman.Object::, Object.prototype]
  window.SnakeClass = @Snake
  @snake._batman.ancestors()

  for k, v of @snake._batman.ancestors()
    equal v, expected[k]

test "primitives are traversed in _batman lookups", ->
  @Animal::_batman.set 'primitive_key', 1
  @Snake::_batman.set 'primitive_key', 2
  @BlackMamba::_batman.set 'primitive_key', 3

  deepSortedEqual @snake._batman.get('primitive_key'), [1,2]
  deepSortedEqual @mamba._batman.get('primitive_key'), [1,2,3]

  @mamba._batman.set 'primitive_key', 4
  @snake._batman.set 'primitive_key', 5
  deepSortedEqual @mamba._batman.get('primitive_key'), [1,2,3,4]
  deepSortedEqual @snake._batman.get('primitive_key'), [1,2,5]

test "array keys are traversed and merged in _batman lookups", ->
  @Animal::_batman.set 'array_key', [1,2,3]
  @Snake::_batman.set 'array_key', [4,5,6]
  @BlackMamba::_batman.set 'array_key', [7,8,9]

  deepSortedEqual @snake._batman.get('array_key'), [1,2,3,4,5,6]
  deepSortedEqual @mamba._batman.get('array_key'), [1,2,3,4,5,6,7,8,9]

  @mamba._batman.set 'array_key', [10,11]
  @snake._batman.set 'array_key', [12,13]
  deepSortedEqual @snake._batman.get('array_key'), [1,2,3,4,5,6,12,13]
  deepSortedEqual @mamba._batman.get('array_key'), [1,2,3,4,5,6,7,8,9,10,11]

test "hash keys are traversed and merged in _batman lookups", ->
  @Animal::_batman.set 'hash_key', new Batman.SimpleHash
  @Animal::_batman.hash_key.set 'foo', 'bar'

  @Snake::_batman.set 'hash_key', new Batman.SimpleHash
  @Snake::_batman.hash_key.set 'baz', 'qux'

  @BlackMamba::_batman.set 'hash_key', new Batman.SimpleHash
  @BlackMamba::_batman.hash_key.set 'wibble', 'wobble'

  for k, v of {wibble: 'wobble', baz: 'qux', foo: 'bar'}
    equal @mamba._batman.get('hash_key').get(k), v

  @mamba._batman.set 'hash_key', new Batman.SimpleHash

  @mamba._batman.hash_key.set 'winnie', 'pooh'
  ok !@mamba._batman.get('hash_key').isEmpty()
  for k, v of {wibble: 'wobble', baz: 'qux', foo: 'bar', winnie:'pooh'}
    equal @mamba._batman.get('hash_key').get(k), v

test "hash keys from closer ancestors replace those from further ancestors", ->
  @Animal::_batman.set 'hash_key', new Batman.SimpleHash
  @Animal::_batman.hash_key.set 'foo', 'bar'

  @Snake::_batman.set 'hash_key', new Batman.SimpleHash
  @Snake::_batman.hash_key.set 'foo', 'baz'

  @BlackMamba::_batman.set 'hash_key', new Batman.SimpleHash
  @BlackMamba::_batman.hash_key.set 'foo', 'qux'

  equal @snake._batman.get('hash_key').get('foo'), 'baz'
  equal @mamba._batman.get('hash_key').get('foo'), 'qux'

  for obj in [@snake, @mamba]
    obj._batman.hash_key = new Batman.SimpleHash
    obj._batman.hash_key.set('foo', 'corge')
    equal obj._batman.get('hash_key').get('foo'), 'corge'

test "set keys are traversed and merged in _batman lookups", ->
  @Animal::_batman.set 'set_key', new Batman.SimpleSet
  @Animal::_batman.set_key.add 'foo', 'bar'

  @Snake::_batman.set 'set_key', new Batman.SimpleSet
  @Snake::_batman.set_key.add 'baz', 'qux'

  @BlackMamba::_batman.set 'set_key', new Batman.SimpleSet
  @BlackMamba::_batman.set_key.add 'wibble', 'wobble'

  for k in ['wibble', 'wobble', 'baz', 'qux', 'foo', 'bar']
    ok @mamba._batman.get('set_key').has(k)
  equal @mamba._batman.get('set_key').length, 6

  @mamba._batman.set 'set_key', new Batman.SimpleSet
  equal @mamba._batman.get('set_key').length, 6

  @mamba._batman.set_key.add 'winnie', 'pooh'
  for k in ['wibble', 'wobble', 'baz', 'qux', 'foo', 'bar', 'winnie', 'pooh']
    ok @mamba._batman.get('set_key').has(k)
  equal @mamba._batman.get('set_key').length, 8

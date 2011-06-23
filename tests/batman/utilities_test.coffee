QUnit.module "$mixin"
  setup: ->
    @base = {x: "x"}

test "should copy properties from the source to the destination", ->
  deepEqual {x: "y", y: "y"}, $mixin(@base, {x: "y"}, {y: "y"})

test "shouldn't affect the source objects", ->
  more = x: "y"
  $mixin @base, more
  deepEqual more, x: "y"

test "reserved words don't get applied", ->
  obj =
    initialize: createSpy()
    uninitialize: ->

  $mixin @base, obj
  ok !obj.initialize.called, "initialized was never called on the object"
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

QUnit.module "prototype events"
  setup: ->
    @oneMethodObserver = a = createSpy()
    @oneRedeclaredObserver = b = createSpy()
    @twoMethodObserver = c = createSpy()
    @twoRedeclaredObserver = d = createSpy()

    class One extends Batman.Object
      method: @event ->
      @::observe "method", a

      redeclaredMethod: @event ->
      @::observe "redeclaredMethod", b

    class Two extends One
      # Redeclare a new event with the same key
      redeclaredMethod: @event ->

      @::observe "method", c
      @::observe "redeclaredMethod", d

    @one = new One
    @two = new Two
    
test "should be declarable", ->
  class Emitter extends Batman.Object
    foo: @event ->
  
  e = new Emitter
  ok e.foo.isEvent

test "should fire observers attached to the prototype", ->
  @one.method("foo")
  ok @oneMethodObserver.called

  @two.method("foo")
  ok @twoMethodObserver.called

test "should fire observers for redeclared methods", ->
  @one.redeclaredMethod("foo")
  equal @oneRedeclaredObserver.callCount, 1
  equal @twoRedeclaredObserver.callCount, 0

  @two.redeclaredMethod("foo")
  equal @oneRedeclaredObserver.callCount, 1
  equal @twoRedeclaredObserver.callCount, 1

QUnit.module "class events"
test "class events", ->
  class Emitter extends Batman.Object
    @foo: @event ->
  
  ok Emitter.foo.isEvent

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
      equal @, arg

  x = new Test
  ctx = x.getContext()
  x.method(ctx)(->)


test "should allow the callback to be passed as the last argument", 1, ->
  class Test
    method: Batman._block (arg, callback) ->
      equal true, arg
  
  (new Test).method(true, ->)

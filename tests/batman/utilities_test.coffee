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

test "prototype events", ->
  class Emitter extends Batman.Object
    foo: @event ->
  
  e = new Emitter
  ok e.foo.isEvent

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
  event true, 1
  
  event observer = createSpy()
  equal observer.callCount, 1
  deepEqual observer.lastCallArguments, ["result", true, 1]
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

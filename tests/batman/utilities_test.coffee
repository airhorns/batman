QUnit.module "Batman.mixin"
  setup: ->
    @base = {x: "x"}

test "should copy properties from the source to the destination", ->
  deepEqual {x: "y", y: "y"}, Batman.mixin(@base, {x: "y"}, {y: "y"})

test "shouldn't affect the source objects", ->
  more = {x: "y"}
  Batman.mixin(@base, more)
  deepEqual more, {x: "y"}

test "should initialize objects", ->
  obj =
    initialize: m = createSpy().whichReturns(true)

  Batman.mixin(@base, obj)
  ok obj.initialize.called, "initialized was never called on the object"

test "should only initialize objects which have a function initializer", ->
  obj =
    initialize: "x"
  Batman.mixin(@base, obj)

test "should use set on objects which have it defined", ->
  obj = {}
  spyOn(obj, 'set')

  Batman.mixin(obj, x: "y")
  deepEqual obj.set.lastCallArguments, ["x", "y"]

QUnit.module "Batman.unmixin",
  setup: ->
    @base =
      x: "x"
      y: "y"
      z: "z"

test "should remove properties on the from that exist on the sources", ->
  deepEqual {z: 'z'}, Batman.unmixin(@base, {x: 'x'}, {y: 'y'})

QUnit.module "Batman.event"
test "should create an event with an action", ->
  event = Batman.event("x")
  ok event.isEvent
  equal event.action, "x"

test "should fire event handlers with the value when passed a value", ->
  event = Batman.event((x) -> x * 2)
  observer = createSpy()
  event(observer)
  event(2)
  equals observer.lastCallArguments, 2

test "should return false and not fire observers if the result is false", ->
  event = Batman.event((x) -> false)
  observer = createSpy()
  event(observer)
  result = event(true)
  equal observer.called, false
  equal result, false

test "should return the result of the original function", ->
  event = Batman.event((x) -> "y")
  equal event(true), "y"

test "should add handlers when passed functions, without calling the original", ->
  original = createSpy()
  event = Batman.event(original)
  event(->) && event(->)
  equals original.callCount, 0

test "should fire more than once", ->
  event = Batman.event(->)
  observer = createSpy()
  event(observer)
  event(1)
  event(true)
  equals observer.callCount, 2

QUnit.module "oneshot Batman.events"
test "should fire handlers when fired", ->
  event = Batman.event.oneShot(->)
  observer = createSpy()
  event(observer)
  event(true)
  equals observer.callCount, 1

test "should fire handlers added after the first fire immediately and pass the original arguments in", ->
  event = Batman.event.oneShot(->)
  event(true, 1)
  observer = createSpy()
  event(observer)
  deepEqual observer.lastCallArguments, [true, 1]

getObservable = (obj, set = true) ->
  if set
    observable = Batman.mixin({}, Batman.Observable)
    for k, v of obj
      observable.set(k, v)
  else
    observable = Batman.mixin(obj, Batman.Observable)
  observable

QUnit.module "Batman.Observable get"
test "should allow retrieval of keys", ->
  obsv = getObservable({foo: "bar"})
  equal obsv.get("foo"), "bar"

test "should allow retrieval of multiple keys", ->
  obsv = getObservable({foo: "bar", x: 1})
  deepEqual obsv.get("foo", "x"), ["bar", 1]

test "should call methodMissing if the key doesn't exist", ->
  obsv = getObservable()
  spyOn(obsv, 'methodMissing')
  obsv.get("nonexistant")
  deepEqual obsv.methodMissing.lastCallArguments, ["nonexistant"]

test "should call properties", ->
  prop = () ->
    equal @, obsv
    "value"
  prop.isProperty = true
  
  obsv = getObservable({"attr": prop})
  equal obsv.get("attr"), "value"

QUnit.module "Batman.Observable nested gets"
  setup: ->
    @child  = getObservable({"attr": true})
    @parent = getObservable({"child": @child})

test "should allow nested gets", ->
  equal @parent.get("child.attr"), true

test "should call method missing on children", ->
  spyOn(@child, 'methodMissing')
  @parent.get("child.nonexistant")
  deepEqual @child.methodMissing.lastCallArguments, ["nonexistant"]

QUnit.module "Batman.Observable set",
  setup: ->
    @obsv = getObservable()

test "should allow setting of keys", ->
  @obsv.set("foo", "bar")
  equal @obsv.foo, "bar"
  equal @obsv.get("foo"), "bar"

test "should allow setting of multiple keys", ->
  @obsv.set("foo", "bar", "baz", "qux")
  equal @obsv.foo, "bar"
  equal @obsv.baz, "qux"
  equals @obsv.bar, undefined
  equals @obsv.qux, undefined

test "should not call method missing if the key does exist", ->
  @obsv.foo = "bar"
  spyOn(@obsv, 'methodMissing')
  @obsv.set("foo", "baz")
  equals @obsv.methodMissing.callCount, 0

test "should call method missing of the key doesn't exist", ->
  spyOn(@obsv, 'methodMissing')
  @obsv.set("nonexistant", "val")
  deepEqual @obsv.methodMissing.lastCallArguments, ["nonexistant", "val"]

test "should call properties", ->
  prop = (val) ->
    if val
      equal @, obsv
      equal val, "val"
      "val"
    else
      ""
  prop.isProperty = true

  obsv = getObservable({"attr": prop})
  obsv.set("attr", "val")

QUnit.module "Batman.Observable nested sets"
  setup: ->
    @child = getObservable({"attr": true})
    @parent = getObservable({"child": @child})

test "should allow nested sets", ->
  equal true, @parent.set("child.attr", true)

test "should call method missing on children", ->
  spyOn(@child, 'methodMissing')
  @parent.set("child.nonexistant", "val")
  deepEqual @child.methodMissing.lastCallArguments, ["nonexistant", "val"]

QUnit.module "Batman.Observable unsetting"
  setup: ->
    @obsv = getObservable({foo: "bar"})

test "should unset existant keys", ->
  @obsv.unset('foo')
  equals @obsv.foo, undefined

test "should call method missing for non existant keys", ->
  spyOn(@obsv, 'methodMissing')
  @obsv.unset('nonexistant')
  deepEqual @obsv.methodMissing.lastCallArguments, ["unset:nonexistant"]

QUnit.module "Batman.Observable observing fields"
  setup: ->
    @obsv = getObservable({foo: "bar"})
    @callback = createSpy()

test "should fire immediate observes if specified", ->
  @obsv.observe "foo", true, @callback
  deepEqual @callback.lastCallArguments, ["bar"]

test "should fire change observers when a new value is set", ->
  @obsv.observe "foo", @callback
  @obsv.observe "foo:before", @callback
  @obsv.set("foo", "baz")
  deepEqual @callback.lastCallArguments, ["baz", "bar"]
  equal @callback.callCount, 2

test "should not fire change observers when the same value is set", ->
  @obsv.observe "foo", @callback
  @obsv.observe "foo:before", @callback
  @obsv.set("foo", "bar")
  equal @callback.callCount, 0

QUnit.module "Batman.Observable nested observing"
  setup: ->
    @child = getObservable({"attr": true})
    @parent = getObservable({"child": @child})
    @callback = createSpy()

test "should allow observing of nested attributes", ->
  @parent.observe('child.attr', @callback)
  @parent.set('child.attr', "foo")
  @child.set("attr", "bar")
  equal @callback.callCount, 2

QUnit.module "Batman.Observable forgetting observers"
  setup: ->
    @callback = createSpy()

test "should forget observers", ->
  @obsv = getObservable({foo: "bar"})
  @obsv.observe "foo", @callback
  @obsv.set("foo", "baz")
  deepEqual @callback.lastCallArguments, ["baz", "bar"]
  @obsv.forget("foo", @callback)
  @obsv.set("foo", "qux")
  equal @callback.callCount, 1

test "should forget nested observers", ->
  @child = getObservable({"attr": true})
  @parent = getObservable({"child": @child})
  @parent.observe "child.attr", @callback
  @parent.set("child.attr", "foo")
  ok @callback.called
  @parent.forget("child.attr", @callback)
  @parent.set("child.attr", "bar")
  equal @callback.callCount, 1

QUnit.module "Batman.Observable mixed in at class and instance level",
  setup: ->
    @classLevel = c = createSpy()
    @instanceLevel = i = createSpy()
    @klass = class Test
      Batman.mixin @, Batman.Observable
      Batman.mixin @::, Batman.Observable

      @observe 'attr', c
      @::observe 'attr', i
    
    @obj = new Test

test "observers attached during class definition should be fired", ->
  @obj.set('attr', 'foo')
  ok @instanceLevel.called

test "instance observers attached after class definition to the prototype should be fired", ->
  @klass::observe('attr', spy = createSpy())
  @obj.set('attr', 'bar')
  ok spy.called

test "instance level observers shouldn't fire class level observers", ->
  @obj.set('attr', 'foo')
  ok !@classLevel.called

test "class level observers shouldn't fire instance level observers", ->
  @klass.set('attr', 'bar')
  ok !@instanceLevel.called

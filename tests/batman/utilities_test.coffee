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
  ok true, "Initializer wasn't called because no error was thrown"

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

QUnit.module "Batman.EventEmitter"
  setup: ->
    @klass = class TestEventClass extends Batman.Object
      @::mixin Batman.EventEmitter
    
      explode: @event ->
    @obj = new TestEventClass
    
    @addEvent = (key, f = ->) ->
      TestEventClass::[key] = TestEventClass::event f

    @addOneShot = (key, f = ->) ->
      TestEventClass::[key] = TestEventClass::eventOneShot f

test "should create an event", ->
  ok @obj.explode.isEvent

test "should fire event handlers with the value when passed a value", ->
  observer = createSpy()
  @obj.explode observer
  @obj.explode 2
  equals observer.lastCallArguments[0], 2

test "should return the result of the original function", ->
  @addEvent 'returnY', (x) -> "y"
  equal @obj.returnY(), "y"

test "should add handlers when passed functions, without calling the original", ->
  original = createSpy()
  @addEvent 'e', original
  @obj.e(->) && @obj.e(->)
  equals original.callCount, 0

test "should fire more than once", ->
  @addEvent 'e'
  observer = createSpy()
  @obj.e(observer)
  @obj.e(1)
  @obj.e(true)
  equals observer.callCount, 2

test "observers shouldn't be shared between instances", ->
  @before = new @klass
  @addEvent 'e'
  @after = new @klass
  @obj.e(true)

  ok @obj._batman.events['e'].fired
  if @before._batman.events?['e']?
    ok !@before._batman.events['e'] .fired
  if @after._batman.events?['e']?
    ok !@after._batman.events['e'] .fired

test "one shot events should fire handlers when fired", ->
  @addOneShot 'e'
  observer = createSpy()
  @obj.e observer
  @obj.e true
  equals observer.callCount, 1

test "one shot events should fire handlers added after the first fire immediately and pass the original result in", ->
  @addOneShot 'e', -> [false, 2]
  @obj.e true, 1
  observer = createSpy()
  @obj.e observer
  deepEqual observer.lastCallArguments, [[false, 2]]

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

test "should call things with their own getters defined", ->
  prop = 
    get: (key, context) ->
      equal @, prop # assert context doesn't change
      equal context, obsv
      equal key, "attr"
      "value"
  
  obsv = getObservable({"attr": prop})
  equal obsv.get("attr"), "value"

QUnit.module "Batman.Observable set",
  setup: ->
    @obsv = getObservable()

test "should allow setting of keys", ->
  @obsv.set("foo", "bar")
  equal @obsv.foo, "bar"
  equal @obsv.get("foo"), "bar"

test "should call things with their own setters defined", ->
  prop = 
    set: (key, val, context) ->
      if val
        equal @, prop # assert context doesn't change
        equal context, obsv
        equal val, "val"
        "val"
      else
        ""

  obsv = getObservable({"attr": prop})
  obsv.set("attr", "val")

QUnit.module "Batman.Observable unsetting"
  setup: ->
    @obsv = getObservable({foo: "bar"})

test "should unset existant keys", ->
  @obsv.unset('foo')
  equals @obsv.foo, undefined

QUnit.module "Batman.Observable observing fields"
  setup: ->
    @obsv = getObservable({foo: "bar"})
    @callback = createSpy()

test "should fire immediate observes if specified", ->
  @obsv.observe "foo", true, @callback
  deepEqual @callback.lastCallArguments, ["bar", "bar"]

test "should fire change observers when a new value is set", ->
  @obsv.observe "foo", @callback
  @obsv.set("foo", "baz")
  deepEqual @callback.lastCallArguments, ["baz", "bar"]
  equal @callback.callCount, 1

test "should not fire change observers when the same value is set", ->
  @obsv.observe "foo", @callback
  @obsv.set("foo", "bar")
  equal @callback.callCount, 0

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

QUnit.module "Batman.Deferred function deferring"
  setup: ->
    @deferred = new Batman.Deferred 
    @spy = createSpy()
    @spy2 = createSpy()

test "should fire then/always callbacks on success", ->
  @deferred.then @spy
  @deferred.always @spy2
  @deferred.resolve true
  ok @spy.called
  ok @spy2.called

test "should fire then/always callbacks on failure", ->
  @deferred.then @spy
  @deferred.always @spy2
  @deferred.reject true
  ok @spy.called
  ok @spy2.called

test "should fire done callbacks on success", ->
  @deferred.done @spy
  @deferred.resolve true
  ok @spy.called

test "should not fire done callbacks on failure", ->
  @deferred.done @spy
  @deferred.reject true
  ok !@spy.called

test "should fire fail callbacks on failure", ->
  @deferred.fail @spy
  @deferred.reject true
  ok @spy.called

test "should not fire fail callbacks on success", ->
  @deferred.fail @spy
  @deferred.resolve true
  ok !@spy.called

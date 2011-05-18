QUnit.module "Batman.Object sub-classes and sub-sub-classes"
  setup: ->
    @subClass = class SubClass extends Batman.Object
    @subSubClass = class SubSubClass extends SubClass

test "subclasses should have the dsl helpers defined", ->
  ok @subClass.property
  ok @subSubClass.property

test "instances should have observable mixed in", ->
  ok (new @subClass).get
  ok (new @subSubClass).get
  ok (new @subClass).set
  ok (new @subSubClass).set

test "instances shouldn't share attributes", ->
  @obj = new @subClass
  @obj2 = new @subClass
  @obj3 = new @subSubClass
  @obj4 = new @subSubClass

  @obj.set("foo", "bar")
  for obj in [@obj2, @obj3, @obj4]
    equal obj.get('foo'), undefined

  @obj4.set("baz", "qux")
  for obj in [@obj, @obj2, @obj3]
    equal obj.get('baz'), undefined

test "classes should have observable mixed in", ->
  ok  @subClass.get
  ok  @subSubClass.get
  ok  @subClass.set
  ok  @subSubClass.set

test "classes shouldn't share attributes", ->
  @subSubClass.set("foo", "bar")
  equal @subSubClass.get("foo"), "bar"
  equal @subClass.get("foo"), undefined

QUnit.module "Batman.Object properties"
  setup: ->
    @get = get = createSpy().whichReturns("")
    @set = set = createSpy()
    @klass = class Test extends Batman.Object
      foo: @property
        get: get
        set: set
    @obj = new Test

test "it should allow creation of properties", ->
  ok @obj.foo.isProperty

test "it should allow getting and setting via the object", ->
  @obj.set("foo", "bar")
  deepEqual @set.lastCallArguments, ["bar"]

test "it should allow getting and setting via the property", ->
  @obj.foo("qux")
  deepEqual @set.lastCallArguments, ["qux"]

test "it should allow observation via the object", ->
  a = createSpy()
  @obj.observe("foo", a)

  b = createSpy()
  @obj2 = new @klass
  @obj2.observe("foo", b)

  @obj.set("foo", "baz")
  ok a.called
  ok !b.called

test "it should allow observation via the class", ->
  a = createSpy()
  class Custom extends Batman.Object
    @::observe 'foo', a

  @obj = new Custom
  @obj2 = new Custom

  @obj.set("foo", "baz")
  equal a.callCount, 1
  @obj2.set("foo", "qux")
  equal a.callCount, 2

test "it should allow custom getters and setters", ->
  class Custom extends Batman.Object
    foo: @property
      get: ->
        "special"
      set: (value) ->
        @somethingElse = value
  @obj = new Custom
  @obj.get("foo")
  equal @obj.get("foo"), "special"

  @obj.set("foo", "something")
  equal @obj.somethingElse, "something"

test "one object should not affect the other", ->
  @obj2 = new @klass

  @obj.set("foo", "bar")
  equal @set.lastCallContext, @obj

  @obj2.set("foo", "baz")
  equal @set.lastCallContext, @obj2

test "property setters should fire observers if the return a changed value", 2, ->
  class Custom extends Batman.Object
    foo: @property
      get: () -> @test
      set: (value) ->
        @test = value * 2
    
    bar: @property
      get: () ->
        "silly"
      set: (value) ->
        "silly"
  
  @obj = new Custom
  @obj.set 'foo', 1
  @obj.observe 'foo', (value, oldValue) ->
    equals value, 4
    equals oldValue, 2
  @obj.set 'foo', 2
  
  @obj.observe 'bar', (value, oldValue) ->
    ok false, "Observer isn't supposed to be called because set doesn't return a different value!"
  @obj.set 'bar', 'weird'

QUnit.module "Batman (the function)"

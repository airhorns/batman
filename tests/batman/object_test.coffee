QUnit.module "Batman.Object"

test "@accessor adds instance-level accessors to the prototype", ->
  defaultAccessor = {get: ->}
  keyAccessor = {get: ->}
  class Thing extends Batman.Object
    @accessor defaultAccessor
    @accessor 'foo', 'bar', keyAccessor

  equal Thing::_batman.defaultAccessor, defaultAccessor
  equal Thing::_batman.keyAccessors.get('foo'), keyAccessor
  equal Thing::_batman.keyAccessors.get('bar'), keyAccessor

test "@classAccessor adds class-level accessors", ->
  defaultAccessor = {get: ->}
  keyAccessor = {get: ->}
  class Thing extends Batman.Object
    @classAccessor defaultAccessor
    @classAccessor 'foo', 'bar', keyAccessor

  equal Thing._batman.defaultAccessor, defaultAccessor
  equal Thing._batman.keyAccessors.get('foo'), keyAccessor
  equal Thing._batman.keyAccessors.get('bar'), keyAccessor

test "@accessor takes a function argument for the accessor as a shortcut for {get: function}", ->
  keyAccessorSpy = createSpy()
  defaultAccessorSpy = createSpy()
  class Thing extends Batman.Object
    @accessor 'foo', keyAccessorSpy
    @accessor defaultAccessorSpy

  deepEqual Thing::_batman.defaultAccessor, {get: defaultAccessorSpy}
  deepEqual Thing::_batman.keyAccessors.get('foo'), {get: keyAccessorSpy}

test "@singleton creates a singleton", ->
  class Thing extends Batman.Object
    @singleton 'sharedThing'

  strictEqual(Thing.get('sharedThing'), Thing.get('sharedThing'))

QUnit.module "Batman.Object sub-classes and sub-sub-classes",
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

test "classes should share observables", ->
  @subClass.observe 'foo', spy = createSpy()
  @subSubClass.observe 'foo', subSpy = createSpy()
  @subSubClass.set 'foo', 'bar'
  Batman.Object.set 'foo', 'bar'

  ok spy.called
  ok subSpy.called

  @subClass.set 'foo', 'bar'
  ok spy.called

test "newly created classes shouldn fire observers on parent classes", ->
  @subClass.observe 'foo', spy = createSpy()

  newSubClass = class TestSubClass extends @subClass
  newSubClass.observe 'foo', subSpy = createSpy()

  newSubClass.set 'foo', 'bar'
  ok spy.called
  ok subSpy.called

test "parent classes shouldn't fire observers on newly created classes", ->
  @subClass.observe 'foo', spy = createSpy()

  newSubClass = class TestSubClass extends @subClass
  newSubClass.observe 'foo', subSpy = createSpy()

  @subClass.set 'foo', 'bar'
  ok spy.called
  ok !subSpy.called


test "it should allow observation via the class", ->
  a = createSpy()
  class Custom extends Batman.Object
    @observe 'foo', a

  @obj = new Custom
  @obj2 = new Custom

  @obj.set("foo", "baz")
  equal a.callCount, 1
  @obj2.set("foo", "qux")
  equal a.callCount, 2

test 'Batman: runtime integration test', ->
  class A extends Batman.Object
  a = new A
  a.set 'foo', 10

  class B extends Batman.Object
    @accessor 'prop'
      get: (key) -> a.get('foo') + @get 'foo'

  b = new B
  b.set 'foo', 20
  b.observe 'prop', spy = createSpy()
  equal b.get('prop'), 30

  a.set('foo', 20)
  ok spy.called

  class Binding extends Batman.Object
    @accessor
      get: () -> b.get 'foo'

  c = new Binding
  equal c.get('anything'), 20

  c.observe 'whatever', spy = createSpy()
  b.set 'foo', 1000
  ok spy.called

QUnit.module "Batman (the function)"

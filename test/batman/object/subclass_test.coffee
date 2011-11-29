QUnit.module "Batman.Object sub-classes and sub-sub-classes",
  setup: ->
    class @subClass extends Batman.Object
    class @subSubClass extends @subClass

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

  equal spy.callCount, 1
  equal subSpy.callCount, 1

  @subClass.set 'foo', 'bar'
  equal spy.callCount, 2
  equal subSpy.callCount, 1

test "newly created classes should fire observers on parent classes", ->
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
    @observeAll 'foo', a

  @obj = new Custom
  @obj2 = new Custom

  @obj.set("foo", "baz")
  equal a.callCount, 1
  @obj2.set("foo", "qux")
  equal a.callCount, 2

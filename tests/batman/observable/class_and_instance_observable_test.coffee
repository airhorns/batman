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

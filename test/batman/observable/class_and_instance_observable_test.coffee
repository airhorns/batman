suite "Batman", ->
  suite "Observable", ->
    suite "mixed in at class and instance level", ->
      classLevel = false
      instanceLevel = false
      klass = false
      obj = false

      setup ->
        classLevel = c = createSpy()
        instanceLevel = i = createSpy()
        klass = class Test
          Batman.mixin @, Batman.Observable
          Batman.mixin @::, Batman.Observable

          @observe 'attr', c
          @::observe 'attr', i

        obj = new Test

      test "observers attached during class definition should be fired",  ->
        obj.set('attr', 'foo')
        assert.ok instanceLevel.called

      test "instance observers attached after class definition to the prototype should be fired",  ->
        klass::observe('attr', spy = createSpy())
        obj.set('attr', 'bar')
        assert.ok spy.called

      test "instance level observers shouldn't fire class level observers",  ->
        obj.set('attr', 'foo')
        assert.ok !classLevel.called

      test "class level observers shouldn't fire instance level observers",  ->
        klass.set('attr', 'bar')
        assert.ok !instanceLevel.called

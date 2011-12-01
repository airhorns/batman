suite "Batman", ->
  suite "Object", ->
    test "@accessor adds instance-level accessors to the prototype",  ->
      defaultAccessor = {get: ->}
      keyAccessor = {get: ->}
      class Thing extends Batman.Object
        @accessor defaultAccessor
        @accessor 'foo', 'bar', keyAccessor

      assert.equal Thing::_batman.defaultAccessor, defaultAccessor
      assert.equal Thing::_batman.keyAccessors.get('foo'), keyAccessor
      assert.equal Thing::_batman.keyAccessors.get('bar'), keyAccessor

    test "@classAccessor adds class-level accessors",  ->
      defaultAccessor = {get: ->}
      keyAccessor = {get: ->}
      class Thing extends Batman.Object
        @classAccessor defaultAccessor
        @classAccessor 'foo', 'bar', keyAccessor

      assert.equal Thing._batman.defaultAccessor, defaultAccessor
      assert.equal Thing._batman.keyAccessors.get('foo'), keyAccessor
      assert.equal Thing._batman.keyAccessors.get('bar'), keyAccessor

    test "@accessor takes a function argument for the accessor as a shortcut for {get: function}",  ->
      keyAccessorSpy = createSpy()
      defaultAccessorSpy = createSpy()
      class Thing extends Batman.Object
        @accessor 'foo', keyAccessorSpy
        @accessor defaultAccessorSpy

      assert.deepEqual Thing::_batman.defaultAccessor, {get: defaultAccessorSpy}
      assert.deepEqual Thing::_batman.keyAccessors.get('foo'), {get: keyAccessorSpy}

    test "@singleton creates a singleton",  ->
      class Thing extends Batman.Object
        @singleton 'sharedThing'

      assert.strictEqual(Thing.get('sharedThing'), Thing.get('sharedThing'))

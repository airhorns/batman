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

test "@accessor() without any args returns the default accessor", ->
  obj = new Batman.Object
  strictEqual obj.accessor(), Batman.Property.defaultAccessor

test "@accessor(key) with a single non-object, non-function argument returns the accessor for that key", ->
  obj = new Batman.Object
  fooAccessor = get: -> "foo"
  obj.accessor "foo", fooAccessor
  strictEqual obj.accessor("foo"), fooAccessor

test "@wrapAccessor calls the given function with the existing accessor, and merges it with the return value of the function", ->
  class PlusOne extends Batman.Object
    @wrapAccessor (core) ->
      get: (key) -> core.get.apply(this, arguments) + 1
  
  example = new PlusOne
  example.set('foo', 1)
  equal example.foo, 1
  equal example.get('foo'), 2

test "@wrapAccessor can be passed an accessor object directly instead of an accessor-returning function", ->
  class PlusOne extends Batman.Object
    @wrapAccessor
      set: (key, val) -> @[key] = val + 1
  
  example = new PlusOne
  example.set('foo', 1)
  equal example.foo, 2
  equal example.get('foo'), 2

test "@wrapAccessor can be given a wrapper function for specific keys", ->
  class PlusOne extends Batman.Object
    @wrapAccessor 'foo', 'bar', (core) ->
      set: (key, val) -> core.set.call(this, key, val+1)
  
  example = new PlusOne
  example.set('foo', 1)
  equal example.foo, 2
  equal example.get('foo'), 2
  example.set('bar', 1)
  equal example.bar, 2
  equal example.get('bar'), 2
  example.set('baz', 1)
  equal example.baz, 1
  equal example.get('baz'), 1

test "@wrapAccessor can be given a wrapper object for specific keys", ->
  class PlusOne extends Batman.Object
    @wrapAccessor 'foo', 'bar'
      get: (key) -> @[key] + 1
  
  example = new PlusOne
  example.set('foo', 1)
  equal example.foo, 1
  equal example.get('foo'), 2
  example.set('bar', 1)
  equal example.bar, 1
  equal example.get('bar'), 2
  example.set('baz', 1)
  equal example.baz, 1
  equal example.get('baz'), 1

test "@singleton creates a singleton", ->
  class Thing extends Batman.Object
    @singleton 'sharedThing'

  strictEqual(Thing.get('sharedThing'), Thing.get('sharedThing'))

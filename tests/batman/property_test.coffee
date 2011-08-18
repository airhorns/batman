# class Person
#   @accessor 'name', 'momName', 'dadName',
#     get: -> @firstName+' '+@lastName
#     set: (val) -> [@firstName, @lastName] = val.split(' ')
#     unset: ->
#       @firstName = null
#       delete @firstName
#       @lastName = null
#       delete @lastName

#
# class Batman.Object
#   constructor: (obj) ->
#     @[key] = val for own key, val of obj if obj


QUnit.module 'Batman.Property',
  setup: ->
    @customKeyAccessor =
      get: createSpy().whichReturns('customKeyValue')
      set: createSpy().whichReturns('customKeyValue')
      unset: createSpy()

    @prototypeKeyAccessor =
      get: createSpy().whichReturns('customKeyValue')
      set: createSpy().whichReturns('customKeyValue')
      unset: createSpy()

    @customBaseAccessor =
      get: createSpy().whichReturns('customBaseValue')

    @prototypeBaseAccessor =
      get: createSpy().whichReturns('customKeyValue')
      set: createSpy().whichReturns('customKeyValue')
      unset: createSpy()

    class TestSubclass  extends Batman.Object
    @base = new TestSubclass
    @base.accessor @customBaseAccessor
    @base.accessor 'foo', @customKeyAccessor
    @base.constructor::accessor @prototypeBaseAccessor
    @base.constructor::accessor 'baz', @prototypeKeyAccessor
    @property = new Batman.Property(@base, 'foo')
    @customBaseAccessorProperty = new Batman.Property(@base, 'bar')

test "Property.defaultAccessor does vanilla JS property access", ->
  obj = {}

  equal typeof Batman.Property.defaultAccessor.get.call(obj, 'foo'), 'undefined'
  obj.foo = 'fooVal'
  equal Batman.Property.defaultAccessor.get.call(obj, 'foo'), 'fooVal'

  equal Batman.Property.defaultAccessor.set.call(obj, 'foo', 'newVal'), 'newVal'
  equal obj.foo, 'newVal'

  equal Batman.Property.defaultAccessor.unset.call(obj, 'foo'), 'newVal'
  equal typeof obj.foo, 'undefined'

test "accessor() returns the accessor specified on the base for that key, if present", ->
  equal @property.accessor(), @customKeyAccessor

test "accessor() returns the accessor specified on the base's prototype for that key, if present", ->
  equal new Batman.Property(@base, 'baz').accessor(), @prototypeKeyAccessor

test "accessor() returns the base's default accessor if none is specified for the key", ->
  equal @customBaseAccessorProperty.accessor(), @customBaseAccessor

test "accessor() returns the base's prototype's default accessor if none is specified for key or base instance", ->
  @base._batman.defaultAccessor = null
  equal new Batman.Property(@base, 'bar').accessor(), @prototypeBaseAccessor

test "accessor() returns Property.defaultAccessor if none is specified for key or base", ->
  equal new Batman.Property({}, 'foo').accessor(), Batman.Property.defaultAccessor

test "getValue() calls the accessor's get(key) method in the context of the property's base", ->
  equal @property.getValue(), 'customKeyValue'
  deepEqual @customKeyAccessor.get.lastCallArguments, ['foo']
  equal @customKeyAccessor.get.lastCallContext, @base

test "setValue(val) calls the accessor's set(key, val) method in the context of the property's base", ->
  equal @property.setValue('customKeyValue'), 'customKeyValue'
  deepEqual @customKeyAccessor.set.lastCallArguments, ['foo', 'customKeyValue']
  equal @customKeyAccessor.set.lastCallContext, @base

test "unsetValue() calls the accessor's unset(key) method in the context of the property's base", ->
  equal typeof @property.unsetValue(), 'undefined'
  deepEqual @customKeyAccessor.unset.lastCallArguments, ['foo']
  equal @customKeyAccessor.unset.lastCallContext, @base

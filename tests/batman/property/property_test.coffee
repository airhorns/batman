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

    class ObjectWithNestedAccessors extends Batman.Object
      @accessor 'fromFooAndQux', -> [@get('foo').name(), @get('qux')]
      @accessor 'foo', -> @get('bar')
      @accessor 'bar', -> @get('baz')

    name = ->
      @registerAsMutableSource()
      @_name
    @mutableSomething = $mixin({name: name, _name: 'Jim'}, Batman.EventEmitter)

    @baseWithNestedAccessors = new ObjectWithNestedAccessors
    @baseWithNestedAccessors.set('baz', @mutableSomething)
    @baseWithNestedAccessors.set('qux', "quxVal")

###
# caching
###

test "getValue() stores the value in .value and sets .cached to true", ->
  property = @baseWithNestedAccessors.property('baz')
  strictEqual property.getValue(), @mutableSomething
  strictEqual property.value, @mutableSomething
  strictEqual property.cached, yes

test "getValue() just returns the .value without hitting the accessor if .cached is true", ->
  property = @baseWithNestedAccessors.property('baz')
  spy = spyOn(property.accessor(), 'get')

  property.cached = yes
  property.value = 'cached'
  strictEqual property.getValue(), 'cached'
  ok not spy.called

test "refresh() should recursively refresh .value and set .sources to the properties accessed directly by the accessor's getter", ->
  foo = @baseWithNestedAccessors.property('foo')
  bar = @baseWithNestedAccessors.property('bar')
  baz = @baseWithNestedAccessors.property('baz')
  qux = @baseWithNestedAccessors.property('qux')
  fromFooAndQux = @baseWithNestedAccessors.property('fromFooAndQux')
  fromFooAndQux.refresh()

  deepEqual foo.sources.toArray(), [bar]
  deepEqual bar.sources.toArray(), [baz]
  deepEqual baz.sources.toArray(), []
  deepEqual foo.sources.toArray(), [bar]
  deepEqual foo.sources.toArray(), [bar]

  fromFooAndQux = @baseWithNestedAccessors.property('fromFooAndQux')
  qux = @baseWithNestedAccessors.property('qux')
  fromFooAndQux.refresh()
  deepEqual fromFooAndQux.sources.toArray(), [foo, @mutableSomething, qux]

test "if the value of a property with observers fires its 'change' event at some point after the property has refreshed its sources, then the property will refresh its .value and .sources", ->
  foo = @baseWithNestedAccessors.property('foo')
  bar = @baseWithNestedAccessors.property('bar')
  baz = @baseWithNestedAccessors.property('baz')
  qux = @baseWithNestedAccessors.property('qux')
  fromFooAndQux = @baseWithNestedAccessors.property('fromFooAndQux')
  fromFooAndQux.observe ->

  fromFooAndQux.refresh()
  deepEqual fromFooAndQux.sources.toArray(), [foo, @mutableSomething, qux]
  deepEqual fromFooAndQux.value, ['Jim', 'quxVal']

  @mutableSomething._name = 'Wanda'
  @mutableSomething.fire('change')

  deepEqual foo.sources.toArray(), [bar]
  deepEqual bar.sources.toArray(), [baz]
  deepEqual baz.sources.toArray(), []
  deepEqual qux.sources.toArray(), []
  deepEqual fromFooAndQux.sources.toArray(), [foo, @mutableSomething, qux]

  strictEqual foo.value, @mutableSomething
  strictEqual bar.value, @mutableSomething
  strictEqual baz.value, @mutableSomething
  strictEqual qux.value, 'quxVal'
  deepEqual fromFooAndQux.value, ['Wanda', 'quxVal']

test "when a property has no observers and one of its sources changes, the property should merely invalidate its cache instead of refreshing", ->
  base = @baseWithNestedAccessors
  bar = base.property('bar')
  baz = base.property('baz')
  equal bar.getValue(), @mutableSomething
  equal bar.value, @mutableSomething
  equal bar.cached, yes
  baz.setValue('newValue')
  equal bar.value, @mutableSomething
  equal bar.cached, no
  equal bar.getValue(), 'newValue'
  equal bar.value, 'newValue'
  equal bar.cached, yes
  

###
# isolation
###
test ".isolate() and .expose() use a count to determine if this property will update itself when its sources change", ->
  bar = @baseWithNestedAccessors.property('bar')
  baz = @baseWithNestedAccessors.property('baz')
  bar.observe(observer = createSpy())

  bar.isolate()
  baz.setValue('baz2')
  equal bar.getValue(), @mutableSomething
  equal observer.called, false

  bar.expose()
  equal observer.callCount, 1
  deepEqual observer.lastCallArguments, ['baz2', @mutableSomething]
  equal bar.getValue(), 'baz2'

  bar.isolate()
  baz.setValue('baz3')
  equal bar.getValue(), 'baz2'
  equal observer.callCount, 1

  bar.isolate()
  baz.setValue('baz4')
  equal bar.getValue(), 'baz2'
  equal observer.callCount, 1

  bar.expose()
  equal bar.getValue(), 'baz2'
  equal observer.callCount, 1

  bar.expose()
  equal bar.getValue(), 'baz4'
  equal observer.callCount, 2
  deepEqual observer.lastCallArguments, ['baz4', 'baz2']

test ".isolate() and .expose() use a count to determine if this property will fire change events when it is set to a new value", ->
  bar = @baseWithNestedAccessors.property('bar')
  baz = @baseWithNestedAccessors.property('baz')
  bar.observe(barObserver = createSpy())
  baz.observe(bazObserver = createSpy())

  baz.isolate()
  baz.setValue('baz2')
  equal baz.getValue(), 'baz2'
  equal bar.getValue(), @mutableSomething
  equal barObserver.called, false
  equal bazObserver.called, false

  baz.expose()
  equal barObserver.callCount, 1
  equal bazObserver.callCount, 1
  deepEqual barObserver.lastCallArguments, ['baz2', @mutableSomething]
  deepEqual bazObserver.lastCallArguments, ['baz2', @mutableSomething]
  equal baz.getValue(), 'baz2'
  equal bar.getValue(), 'baz2'

  baz.isolate()
  baz.setValue('baz3')
  equal baz.getValue(), 'baz3'
  equal bar.getValue(), 'baz2'
  equal barObserver.callCount, 1
  equal bazObserver.callCount, 1

  baz.isolate()
  baz.setValue('baz4')
  equal baz.getValue(), 'baz4'
  equal bar.getValue(), 'baz2'
  equal barObserver.callCount, 1
  equal bazObserver.callCount, 1

  baz.expose()
  equal baz.getValue(), 'baz4'
  equal bar.getValue(), 'baz2'
  equal barObserver.callCount, 1
  equal bazObserver.callCount, 1

  baz.expose()
  equal baz.getValue(), 'baz4'
  equal bar.getValue(), 'baz4'
  equal barObserver.callCount, 2
  equal bazObserver.callCount, 2
  deepEqual barObserver.lastCallArguments, ['baz4', 'baz2']
  deepEqual bazObserver.lastCallArguments, ['baz4', 'baz2']

test ".expose() will only trigger a .refresh() if updates have come in from sources while it was isolated", ->
  bar = @baseWithNestedAccessors.property('bar')
  refreshSpy = spyOn(bar, 'refresh')
  bar.isolate()
  bar.expose()
  equal refreshSpy.called, false

###
# accessing
###
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

test "property() works on non Batman objects", ->
  property = Batman.Property.forBaseAndKey(window, 'Array')
  property.observe spy = createSpy()
  property.fire()
  ok spy.called

  property = Batman.Property.forBaseAndKey({}, 'foo')
  property.observe spy = createSpy()
  property.fire()
  ok spy.called

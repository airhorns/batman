getPropertyAccessor = ->
  get: createSpy ->
  set: createSpy()
  unset: createSpy()

QUnit.module 'Batman.Observable',
  setup: ->

    @obj = Batman
      foo: Batman
        bar: Batman
          baz: Batman
            qux: 'quxVal'

    @obj.foo.bar.baz.event('corge', @corgeEventSpy = createSpy())
    @obj.accessor 'someProperty',     (@objPropertyAccessor = getPropertyAccessor())
    @obj.foo.accessor 'someProperty', (@fooPropertyAccessor = getPropertyAccessor())

###
# property(key)
###
test 'property(key) returns a keypath of this object with the given key', ->
  keypath = @obj.property('foo.bar.baz')
  ok keypath.base is @obj
  equal keypath.key, 'foo.bar.baz'


###
# get(key)
###
test 'get(key) with a simple key returns the value of that property', ->
  ok @obj.get('foo') is @obj.foo

test 'get(key) with a deep keypath returns the value of the property at the end of the keypath', ->
  equal @obj.get('foo.bar.baz.qux'), 'quxVal'

test "get(key) with an unresolvable simple key returns undefined", ->
  equal typeof(@obj.get('nothing')), 'undefined'

test "get(key) with an unresolvable keypath returns undefined", ->
  equal typeof(@obj.get('foo.bar.nothing')), 'undefined'

test "get(key) with a simple key calls resolve() on the result if it is a Batman.Property and returns that instead", ->
  @objPropertyAccessor.get.whichReturns('resolvedValue')
  equal @obj.get('someProperty'), 'resolvedValue'
  deepEqual @objPropertyAccessor.get.lastCallArguments, ['someProperty']
  ok @objPropertyAccessor.get.lastCallContext is @obj

test "get(key) with a deep keypath uses the last property's accessor with the last base as the context", ->
  @fooPropertyAccessor.get.whichReturns('resolvedValue')
  equal @obj.get('foo.someProperty'), 'resolvedValue'
  deepEqual @fooPropertyAccessor.get.lastCallArguments, ['someProperty']
  ok @fooPropertyAccessor.get.lastCallContext is @obj.foo

test "get(key) is cached until one of its sources changes", ->
  @obj.get('foo.someProperty')
  equal @fooPropertyAccessor.get.callCount, 1
  @obj.get('foo.someProperty')
  equal @fooPropertyAccessor.get.callCount, 1

  @obj.set('foo.someProperty', yes)

  @obj.get('foo.someProperty')
  equal @fooPropertyAccessor.get.callCount, 2
  @obj.get('foo.someProperty')
  equal @fooPropertyAccessor.get.callCount, 2

test "get(key) works with cacheable properties with more than one level of accessor indirection", ->
  @obj.accessor 'indirectProperty', -> @get('foo.someProperty')
  @obj.get('indirectProperty')
  equal @fooPropertyAccessor.get.callCount, 1
  @obj.get('indirectProperty')
  equal @fooPropertyAccessor.get.callCount, 1

  @obj.set('foo.someProperty', yes)

  @obj.get('indirectProperty')
  equal @fooPropertyAccessor.get.callCount, 2
  @obj.get('indirectProperty')
  equal @fooPropertyAccessor.get.callCount, 2

test "get(key) works with Batman.Property.withoutTracking", ->
  callCount = 0
  @obj.accessor 'withoutTrackingProperty', ->
    callCount++
    @get('foo')
    Batman.Property.withoutTracking =>
      @get('foo.bar')
    true

  @obj.get('withoutTrackingProperty')
  equal callCount, 1
  @obj.set('foo.bar', true)
  @obj.get('withoutTrackingProperty')
  equal callCount, 1
  @obj.set('foo')
  @obj.get('withoutTrackingProperty')
  equal callCount, 2

###
# set(key)
###
test "set(key, val) with a simple key stores the value in the property", ->
  equal @obj.set('foo', 'newVal'), 'newVal'
  equal @obj.foo, 'newVal'

test "set(key, val) with a deep keypath stores the value in the property at the end of the keypath", ->
  @obj.set 'foo.bar.baz.qux', 'newVal'
  equal @obj.foo.bar.baz.qux, 'newVal'

test "set(key, val) with a simple key calls fire(key, val, oldValue)", ->
  fooProperty = @obj.property('foo')
  spyOn(fooProperty, 'fire')
  foo = @obj.foo
  @obj.observe 'foo', ->

  @obj.set 'foo', 'newVal'

  equal fooProperty.fire.lastCallArguments.length, 2
  equal fooProperty.fire.lastCallArguments[0], 'newVal'
  ok fooProperty.fire.lastCallArguments[1] is foo

test "set(key, val) with a simple key should use the existing value's assign() method if the value is a Batman.Property", ->
  @obj.set 'someProperty', 'newVal'
  deepEqual @objPropertyAccessor.set.lastCallArguments, ['someProperty', 'newVal']
  ok @objPropertyAccessor.set.lastCallContext is @obj

test "set(key, val) with a deep keypath should use the existing value's assign() method if the value is a Batman.Property", ->
  @obj.set 'foo.someProperty', 'newVal'
  deepEqual @fooPropertyAccessor.set.lastCallArguments, ['someProperty', 'newVal']
  ok @fooPropertyAccessor.set.lastCallContext is @obj.foo



###
# unset(key)
###
test "unset(key) deletes the referenced property and returns the removed value", ->
  equal @obj.unset('foo.bar.baz.qux'), 'quxVal'
  strictEqual @obj.foo.bar.baz.qux, undefined

test "unset(key) with a simple key calls fire(key, undefined, oldValue)", ->
  fooProperty = @obj.property('foo')
  spyOn(fooProperty, 'fire')
  foo = @obj.foo
  @obj.observe 'foo', ->

  @obj.unset 'foo'

  [newVal, oldVal] = fooProperty.fire.lastCallArguments
  equal typeof(newVal), 'undefined'
  ok oldVal is foo

test "unset(key) with a simple key should use the existing value's remove() method if the value is a Batman.Property", ->
  someProperty = @objPropertyAccessor
  @obj.unset 'someProperty'
  equal someProperty, @objPropertyAccessor
  equal @objPropertyAccessor.unset.called, true
  ok @objPropertyAccessor.unset.lastCallContext is @obj

test "unset(key) with a deep keypath should use the existing value's remove() method if the value is a Batman.Property", ->
  @obj.unset 'foo.someProperty'
  equal @fooPropertyAccessor.unset.called, true
  ok @fooPropertyAccessor.unset.lastCallContext is @obj.foo

test "unset(key) should remove the property instance if it has no observers", ->
  property = @obj.property('foo')
  @obj.unset 'foo'
  notEqual @obj.property('foo'), property

test "unset(key) should not remove the property instance if it has observers", ->
  property = @obj.property('foo')
  @obj.observe 'foo', ->
  @obj.unset 'foo'
  equal @obj.property('foo'), property

###
# getOrSet(key, valueFunction)
###
test "getOrSet(key, valueFunction) does conditional assignment with the return value of the given function", ->
  equal @obj.foo, @obj.getOrSet("foo", -> "bar")
  equal @obj.foo, @obj.get("foo")
  equal "bar", @obj.getOrSet("foo2", -> "bar")
  equal "bar", @obj.get("foo2")

###
# observe(key, callback)
###
test "observe(key, callback) stores the callback such that it is called with (value, oldValue) when the value of the key changes", ->
  callback = createSpy()
  ok @obj.observe('foo', callback) is @obj
  equal callback.called, false
  foo = @obj.foo
  @obj.set 'foo', 'newVal'
  [newValue, oldValue] = callback.lastCallArguments
  equal newValue, 'newVal'
  ok oldValue is foo

test "observe(key, callback) with a deep keypath will fire with the new value when the final key value is changed directly", ->
  @obj.observe 'foo.bar.baz.qux', callback = createSpy()

  @obj.foo.bar.baz.set 'qux', 'newVal'

  ok callback.called
  [newVal, oldVal] = callback.lastCallArguments
  equal newVal, 'newVal'
  equal oldVal, 'quxVal'

test "observe(key, callback) with a deep keypath will fire with the new value when the final key value is changed via the same deep keypath", ->
  @obj.observe 'foo.bar.baz.qux', callback = createSpy()

  @obj.set 'foo.bar.baz.qux', 'newVal'

  ok callback.called
  [newVal, oldVal] = callback.lastCallArguments
  equal newVal, 'newVal'
  equal oldVal, 'quxVal'
test "observe(key, callback) with a deep keypath will fire with the new value when the final key value is changed via an equivalent subset of that deep keypath", ->
  @obj.observe 'foo.bar.baz.qux', callback = createSpy()

  @obj.foo.set 'bar.baz.qux', 'newVal'

  ok callback.called
  [newVal, oldVal] = callback.lastCallArguments
  equal newVal, 'newVal'
  equal oldVal, 'quxVal'

test "observe(key, callback) with a deep keypath will fire with undefined if the key segment chain is broken", ->
  @obj.observe 'foo.bar.baz.qux', callback = createSpy()

  @obj.set 'foo', 'newVal'

  ok callback.called
  [newVal, oldVal] = callback.lastCallArguments
  equal typeof(newVal), 'undefined'
  equal oldVal, 'quxVal'

test "observe(key, callback) with a deep keypath will fire with the new value if an intermediary key is changed such that the keypath resolves to a new value", ->
  @obj.observe 'foo.bar.baz.qux', callback = createSpy()

  @obj.set 'foo',
    bar:
      baz:
        qux: 'newVal'

  ok callback.called
  [newVal, oldVal] = callback.lastCallArguments
  equal newVal, 'newVal'
  equal oldVal, 'quxVal'

test "observe(key, callback) with a deep keypath will fire with a previous value that has been removed and re-added", ->
  @obj.observe 'foo.bar.baz.qux', callback = createSpy()
  bar = @obj.foo.bar

  @obj.unset 'foo.bar'

  equal callback.callCount, 1
  [newVal, oldVal] = callback.lastCallArguments
  equal typeof(newVal), 'undefined'
  equal oldVal, 'quxVal'

  @obj.set 'foo.bar', bar

  equal callback.callCount, 2
  [newVal, oldVal] = callback.lastCallArguments
  equal newVal, 'quxVal'
  equal typeof(oldVal), 'undefined'

test "observe(key, callback) with a deep keypath will not fire if a previous portion of the path is modified", ->
  @obj.observe 'foo.bar.baz.qux', callback = createSpy()
  bar = @obj.foo.bar

  @obj.unset 'foo.bar'
  bar.unset 'baz'

  equal callback.callCount, 1
  [newVal, oldVal] = callback.lastCallArguments
  equal typeof(newVal), 'undefined'
  equal oldVal, 'quxVal'

test "observe(key, callback) with a deep keypath will fire when a portion of a previously removed and re-added portion is modified", ->
  @obj.observe 'foo.bar.baz.qux', callback = createSpy()
  bar = @obj.foo.bar

  @obj.unset 'foo.bar'
  @obj.set 'foo.bar', bar
  @obj.set 'foo.bar.baz.qux', 'newVal'

  equal callback.callCount, 3
  [newVal, oldVal] = callback.lastCallArguments
  equal newVal, 'newVal'
  equal oldVal, 'quxVal'

test "observe(key, callback) called twice to attach two different observers on the same deep keypath will only fire those observers once each for any given change", ->
  @obj.observe 'foo.bar.baz.qux', callback1 = createSpy()
  @obj.observe 'foo.bar.baz.qux', callback2 = createSpy()

  @obj.set 'foo.bar.baz.qux', 'newVal'

  equal callback1.callCount, 1
  equal callback2.callCount, 1

test "observe(key, callback) will only fire once and will not break when there's an object cycle", ->
  @obj.foo.bar.baz.foo = @obj.foo

  @obj.observe 'foo.bar.baz.foo.bar', callback = createSpy()

  oldBar = @obj.foo.bar
  newBar = Batman
    baz: Batman
      foo: Batman
        bar: 'newVal'
  @obj.foo.set 'bar', newBar

  equal callback.callCount, 1
  [newVal, oldVal] = callback.lastCallArguments
  equal newVal, 'newVal'
  ok oldVal == oldBar, "oldVal is not oldBar"


###
# observeAndFire(key, callback)
###
test "observeAndFire(key, callback) adds the callback and then calls it immediately", ->
  callback = createSpy()
  @obj.observeAndFire 'foo.bar.baz.qux', callback
  deepEqual callback.lastCallArguments, ['quxVal', 'quxVal']


###
# forget(key [, callback])
###
test "forget(key, callback) for a simple key will remove the specified callback from that key's observers", ->
  callback1 = createSpy()
  callback2 = createSpy()
  @obj.observe 'foo', callback1
  @obj.observe 'foo', callback2

  @obj.forget 'foo', callback2

  @obj.set 'foo', 'newVal'
  equal callback1.callCount, 1
  equal callback2.callCount, 0


test "forget(key) for a simple key with no callback specified will forget all observers for that key, leaving observers of other keys untouched", ->
  callback1 = createSpy()
  callback2 = createSpy()
  callback3 = createSpy()
  @obj.observe 'foo', callback1
  @obj.observe 'foo', callback2
  @obj.observe 'someOtherKey', callback3

  @obj.forget 'foo'

  @obj.set 'foo', 'newVal'

  equal callback1.callCount, 0
  equal callback2.callCount, 0

  @obj.set 'someOtherKey', 'someVal'
  equal callback3.callCount, 1


test "forget() without any arguments removes all observers from all of this object's keys", ->
  callback1 = createSpy()
  callback2 = createSpy()
  callback3 = createSpy()
  @obj.observe 'foo', callback1
  @obj.observe 'foo', callback2
  @obj.observe 'someOtherKey', callback3

  equal @obj.forget(), @obj, "forget returns object for chaining"

  @obj.set 'foo', 'newVal'

  equal callback1.callCount, 0
  equal callback2.callCount, 0

  @obj.set 'someOtherKey', 'someVal'
  equal callback3.callCount, 0


test "forget(key) for a deep keypath does not remove any sources when there are still observers present on the keypath", ->
  callback1 = createSpy()
  callback2 = createSpy()

  @obj.observe 'foo.bar.baz', callback1
  @obj.observe 'foo.bar.baz', callback2

  equal @obj.forget('foo.bar.baz', callback2), @obj, "forget returns object for chaining"

  equal @obj.property('foo').event('change').handlers.length, 1
  equal @obj.foo.property('bar').event('change').handlers.length, 1
  equal @obj.foo.bar.property('baz').event('change').handlers.length, 1

  equal @obj.property('foo.bar.baz').sources.length, 3

  @obj.foo.bar.set 'baz', 'newBaz'
  equal callback1.callCount, 1
  @obj.foo.set 'bar', 'newBar'
  equal callback1.callCount, 2
  @obj.set 'foo', Batman(bar: Batman(baz: 'reconstructedBaz'))
  equal callback1.callCount, 3
  equal callback2.callCount, 0

QUnit.module 'Batman.Observable',
  setup: ->
    # spyOn Batman.TriggerSet.prototype, 'add'
    # spyOn Batman.TriggerSet.prototype, 'remove'
    @obj = Batman
      someProperty: new Batman.Property
        resolve: createSpy()
        assign: createSpy()
        remove: createSpy()
      foo: Batman
        someProperty: new Batman.Property
          resolve: createSpy()
          assign: createSpy()
          remove: createSpy()
        bar: Batman
          baz: Batman
            qux: 'quxVal'

###
# keypath(key)
###
test 'keypath(key) returns a keypath of this object with the given key', ->
  keypath = @obj.keypath('foo.bar.baz')
  equal keypath.base, @obj
  deepEqual keypath.segments, ['foo', 'bar', 'baz']


###
# get(key)
###
test 'get(key) with a simple key returns the value of that property', ->
  equal @obj.get('foo'), @obj.foo
  
test 'get(key) with a deep keypath returns the value of the property at the end of the keypath', ->
  equal @obj.get('foo.bar.baz.qux'), 'quxVal'
  
test "get(key) with an unresolvable simple key returns undefined", ->
  equal typeof(@obj.get('nothing')), 'undefined'
  
test "get(key) with an unresolvable keypath returns undefined", ->
  equal typeof(@obj.get('foo.bar.nothing')), 'undefined'

test "get(key) with a simple key calls resolve() on the result if it is a Batman.Property and returns that instead", ->
  @obj.someProperty.resolve.whichReturns('resolvedValue')
  equal @obj.get('someProperty'), 'resolvedValue'
  equal @obj.someProperty.resolve.lastCallContext, @obj

test "get(key) with a deep keypath calls resolve() on the result if it is a Batman.Property and returns that instead", ->
  @obj.foo.someProperty.resolve.whichReturns('resolvedValue')
  equal @obj.get('foo.someProperty'), 'resolvedValue'
  equal @obj.foo.someProperty.resolve.lastCallContext, @obj.foo
  
test "get(key) with a simple key uses _get(key) if present", ->
  fancyObj =
    _get: (key) -> 'fancy '+key
  result = Batman.Observable.get.call(fancyObj, 'foo')
  equal result, 'fancy foo'
  
test "get(key) with a deep keypath uses _get(key) if present", ->
  fancyObj =
    _get: (key) -> 'fancy '+key
  wrapper =
    fancy: fancyObj
  result = Batman.Observable.get.call(wrapper, 'fancy.foo')
  equal result, 'fancy foo'


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
  spyOn(@obj, 'fire')
  foo = @obj.foo
  @obj.set 'foo', 'newVal'
  deepEqual @obj.fire.lastCallArguments, ['foo', 'newVal', foo]
  
test "set(key, val) with a deep keypath does not call fire() directly", ->
  spyOn(@obj, 'fire')
  @obj.set 'foo.bar.baz.qux', 'newVal'
  equal @obj.fire.called, false

test "set(key, val) with a simple key should use the existing value's assign() method if the value is a Batman.Property", ->
  someProperty = @obj.someProperty
  @obj.set 'someProperty', 'newVal'
  equal someProperty, @obj.someProperty
  deepEqual someProperty.assign.lastCallArguments, ['newVal']
  equal someProperty.assign.lastCallContext, @obj

test "set(key, val) with a deep keypath should use the existing value's assign() method if the value is a Batman.Property", ->
  someProperty = @obj.foo.someProperty
  @obj.set 'foo.someProperty', 'newVal'
  equal someProperty, @obj.foo.someProperty
  deepEqual someProperty.assign.lastCallArguments, ['newVal']
  equal someProperty.assign.lastCallContext, @obj.foo

test "set(key, val) with a simple key uses _set(key, val) if present", ->
  fancyObj =
    _set: (key, val) -> @[key] = 'fancy '+val
  Batman.Observable.set.call(fancyObj, 'foo', 'bar')
  equal fancyObj.foo, 'fancy bar'

test "set(key, val) with a deep keypath uses _set(key, val) if present", ->
  fancyObj =
    _set: (key, val) -> @[key] = 'fancy '+val
  wrapper =
    fancy: fancyObj
  Batman.Observable.set.call(wrapper, 'fancy.foo', 'bar')
  equal fancyObj.foo, 'fancy bar'
  


###
# unset(key)
###
test "unset(key) removes the referenced property", ->
  @obj.unset 'foo.bar.baz.qux'
  equal typeof(@obj.foo.bar.baz.qux), 'undefined'

test "unset(key) with a simple key calls fire(key, undefined, oldValue)", ->
  spyOn(@obj, 'fire')
  foo = @obj.foo
  @obj.unset 'foo'
  [key, newVal, oldVal] = @obj.fire.lastCallArguments
  equal key, 'foo'
  equal typeof(newVal), 'undefined'
  equal oldVal, foo

test "unset(key) with a deep keypath does not call fire() directly", ->
  spyOn(@obj, 'fire')
  @obj.unset 'foo.bar.baz.qux'
  equal @obj.fire.called, false

test "unset(key) with a simple key should use the existing value's remove() method if the value is a Batman.Property", ->
  someProperty = @obj.someProperty
  @obj.unset 'someProperty'
  equal someProperty, @obj.someProperty
  equal someProperty.remove.called, true
  equal someProperty.remove.lastCallContext, @obj

test "unset(key) with a deep keypath should use the existing value's remove() method if the value is a Batman.Property", ->
  someProperty = @obj.foo.someProperty
  @obj.unset 'foo.someProperty'
  equal someProperty, @obj.foo.someProperty
  equal someProperty.remove.called, true
  equal someProperty.remove.lastCallContext, @obj.foo

test "unset(key) with a simple key uses _unset(key, val) if present", ->
  fancyObj =
    _unset: (key) -> @[key] = key+' has been _unset!'
  Batman.Observable.unset.call(fancyObj, 'foo')
  equal fancyObj.foo, 'foo has been _unset!'

test "unset(key) with a deep keypath uses _unset(key, val) if present", ->
  fancyObj =
    _unset: (key) -> @[key] = key+' has been _unset!'
  wrapper =
    fancy: fancyObj
  Batman.Observable.unset.call(wrapper, 'fancy.foo')
  equal fancyObj.foo, 'foo has been _unset!'
  


###
# observe(key [, fireImmediately], callback)
###
test "observe(key, callback) stores the callback such that it is called with (value, oldValue) when the value of the key changes", ->
  callback = createSpy()
  equal @obj.observe('foo', callback), @obj
  equal callback.called, false
  foo = @obj.foo
  @obj.set 'foo', 'newVal'
  deepEqual callback.lastCallArguments, ['newVal', foo]

test "observe(key, fireImmediately, callback) calls the callback immediately if fireImmediately is true", ->
  callback = createSpy()
  @obj.observe 'foo.bar.baz.qux', yes, callback
  deepEqual callback.lastCallArguments, ['quxVal', 'quxVal']

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
# observesKeyWithObserver(key, observer)
###
test "observesKeyWithObserver(key, observer) returns false when the given key is not observed by the given observer", ->
  @obj.observe 'foo', ->
  equal false, @obj.observesKeyWithObserver('foo', ->)

test "observesKeyWithObserver(key, observer) returns true when the given key is observed by the given observer", ->
  observer = ->
  @obj.observe 'foo', observer
  equal true, @obj.observesKeyWithObserver('foo', observer)


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
  
  @obj.forget()
  
  @obj.set 'foo', 'newVal'
  
  equal callback1.callCount, 0
  equal callback2.callCount, 0
  
  @obj.set 'someOtherKey', 'someVal'
  equal callback3.callCount, 0
  
  
test "forget(key) for a deep keypath will remove all triggers for that callback on other objects", ->
  callback1 = createSpy()
  callback2 = createSpy()
  
  @obj.observe 'foo.bar.baz', callback1
  @obj.observe 'foo.bar.baz', callback2
  
  @obj.forget 'foo.bar.baz', callback2
  
  equal @obj._batman.outboundTriggers['foo'].triggers.toArray().length, 1
  equal @obj.foo._batman.outboundTriggers['bar'].triggers.toArray().length, 1
  equal @obj.foo.bar._batman.outboundTriggers['baz'].triggers.toArray().length, 1
  
  equal @obj._batman.inboundTriggers['foo.bar.baz'].triggers.toArray().length, 3
  
  @obj.foo.bar.set 'baz', 'newBaz'
  @obj.foo.set 'bar', 'newBar'
  @obj.set 'foo', 'newFoo'
  equal callback1.callCount, 3
  equal callback2.callCount, 0


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
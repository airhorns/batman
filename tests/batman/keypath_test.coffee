QUnit.module 'Batman.Keypath',
  setup: ->
    @obj =
      foo:
        bar:
          baz:
            qux: 'quxVal'
    @emptyKey = new Batman.Keypath(@obj, [])
    @simpleKey = new Batman.Keypath(@obj, ['foo'])
    @deepKeypath = new Batman.Keypath(@obj, ['foo', 'bar', 'baz', 'qux'])


###
# constructor
###
test "initialize from string", ->
  keypath = new Batman.Keypath @obj, 'foo.bar.baz.qux'
  deepEqual keypath.segments, ['foo', 'bar', 'baz', 'qux']

test "initialize from array of key segments", ->
  deepEqual @deepKeypath.segments, ['foo', 'bar', 'baz', 'qux']


###
# path()
###
test "path() returns the dot-delimited string representation of the key segments", ->
  equal @emptyKey.path(), ''
  equal @simpleKey.path(), 'foo'
  equal @deepKeypath.path(), 'foo.bar.baz.qux'


###
# slice([begin] [, end])
###
test "slice(0, keypath.segments.length) returns a new equivalent keypath", ->
  slice = @deepKeypath.slice(0, 4)
  deepEqual @deepKeypath, slice
  notStrictEqual @deepKeypath, slice

test "slice(0) returns a new equivalent keypath", ->
  slice = @deepKeypath.slice(0)
  deepEqual @deepKeypath, slice
  notStrictEqual @deepKeypath, slice
  
test "slice(2, keypath.segments.length) returns a new keypath with the second segment's value as the base, and the remaining segments as the segments", ->
  slice = @deepKeypath.slice(2, 4)
  equal slice.base, @obj.foo.bar
  deepEqual slice.segments, ['baz', 'qux']
  
test "slice(2) returns a new keypath with the second segment's value as the base, and the remaining segments as the segments", ->
  slice = @deepKeypath.slice(2)
  equal slice.base, @obj.foo.bar
  deepEqual slice.segments, ['baz', 'qux']
  
test "slice(0, 2) returns a new keypath with the same base but only the first two segments", ->
  slice = @deepKeypath.slice(0, 2)
  equal slice.base, @obj
  deepEqual slice.segments, ['foo', 'bar']
  
test "slice(1, 3) returns a new keypath with the first segment as the base, and only extending through the following two segments", ->
  slice = @deepKeypath.slice(1, 3)
  equal slice.base, @obj.foo
  deepEqual slice.segments, ['bar', 'baz']
  
test "slice(1, 1) returns a new keypath with the first segment as the base, and no segments", ->
  slice = @deepKeypath.slice(1, 1)
  equal slice.base, @obj.foo
  deepEqual slice.segments, []
  
test "slice(1, -1) counts from the end of the segments", ->
  slice = @deepKeypath.slice(1, -1)
  equal slice.base, @obj.foo
  deepEqual slice.segments, ['bar', 'baz']


###
# finalPair()
###
test "finalPair() returns the final one-segment keypath component", ->
  slice = @deepKeypath.slice(-1)
  equal slice.base, @obj.foo.bar.baz
  deepEqual slice.segments, ['qux']


###
# resolve()
###
test "resolve() returns the value referenced by this keypath", ->
  equal @simpleKey.resolve(), @obj.foo
  equal @deepKeypath.resolve(), 'quxVal'

test "resolve() returns the base if there are no key segments", ->
  equal @emptyKey.resolve(), @obj

test "resolve() returns undefined if the key segment chain has been broken", ->
  @obj.foo.bar = 'newVal'
  equal typeof(@deepKeypath.resolve()), 'undefined'


###
# assign(val)
###
test "assign(val) on a simple key sets the referenced property to the given value", ->
  equal @simpleKey.assign('newVal'), 'newVal'
  equal @obj.foo, 'newVal'

test "assign(val) is a no-op if there are no key segments", ->
  foo = @obj.foo
  @emptyKey.assign('foo')
  equal @emptyKey.base, @obj
  deepEqual @emptyKey.segments, []
  deepEqual @obj, {foo: foo}

test "assign(val) on a deep keypath sets the referenced property to the given value", ->
  equal @deepKeypath.assign('newVal'), 'newVal'
  equal @obj.foo.bar.baz.qux, 'newVal'


###
# remove()
###
test "remove() on a simple key deletes the referenced property", ->
  @simpleKey.remove()
  equal typeof(@obj.foo), 'undefined'

test "remove() on a deep keypath deletes the referenced property", ->
  @deepKeypath.remove()
  equal typeof(@obj.foo.bar.baz.qux), 'undefined'

test "remove() is a no-op if there are no key segments", ->
  foo = @obj.foo
  @emptyKey.remove()
  equal @emptyKey.base, @obj
  deepEqual @emptyKey.segments, []
  deepEqual @obj, {foo: foo}


###
# eachPair(callback)
###
test "eachPair(callback) iterates over each minimal keypath pair which composes this keypath", ->
  callback = createSpy()
  bases = [@obj, @obj.foo, @obj.foo.bar, @obj.foo.bar.baz]
  segments = ['foo', 'bar', 'baz', 'qux']
  
  @deepKeypath.eachPair(callback)
  equal callback.callCount, 4
  for call, index in callback.calls
    keypath = call.arguments[0]
    eachPairIndex = call.arguments[1]
    equal keypath.base, bases[index]
    deepEqual keypath.segments, [segments[index]]
    equal eachPairIndex, index

test "eachPair(callback) stops if the chain of key segments is broken somewhere", ->
  callback = createSpy()
  @obj.foo.bar = 'newVal'
  @deepKeypath.eachPair(callback)
  equal callback.callCount, 2


###
# isEqual(other)
###
test "isEqual(other) returns true if both keypaths' bases are the same object and both segment arrays are equivalent", ->
  obj = {}
  path1 = new Batman.Keypath(obj, ['foo', 'bar'])
  path2 = new Batman.Keypath(obj, ['foo', 'bar'])
  ok path1.isEqual(path2)
  ok path2.isEqual(path1)
  
test "isEqual(other) returns false if the other keypath has a different object as its base", ->
  obj1 = {}
  obj2 = {}
  path1 = new Batman.Keypath(obj1, ['foo', 'bar'])
  path2 = new Batman.Keypath(obj2, ['foo', 'bar'])
  ok not path1.isEqual(path2)
  ok not path2.isEqual(path1)
  
test "isEqual(other) returns false if the other keypath has a different array of key segments", ->
  obj = {}
  path1 = new Batman.Keypath(obj, ['foo', 'bar'])
  path2 = new Batman.Keypath(obj, ['foo', 'bar', 'baz'])
  ok not path1.isEqual(path2)
  ok not path2.isEqual(path1)


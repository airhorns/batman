QUnit.module 'Batman.Keypath',
  setup: ->
    @obj =
      foo:
        bar:
          baz:
            qux: 'quxVal'
    @emptyKey = new Batman.Keypath(@obj)
    @simpleKey = new Batman.Keypath(@obj, 'foo')
    @deepKeypath = new Batman.Keypath(@obj, 'foo.bar.baz.qux')


###
# constructor
###
test "initializing sets segments and depth", ->
  keypath = new Batman.Keypath @obj, 'foo.bar.baz.qux'
  deepEqual keypath.segments, ['foo', 'bar', 'baz', 'qux']
  equal keypath.depth, 4


###
# slice([begin] [, end])
###
test "slice(0, keypath.segments.length) returns a new equivalent keypath", ->
  slice = @deepKeypath.slice(0, 4)
  deepEqual slice, @deepKeypath
  notStrictEqual slice, @deepKeypath

test "slice(0) returns a new equivalent keypath", ->
  slice = @deepKeypath.slice(0)
  deepEqual slice, @deepKeypath
  notStrictEqual slice, @deepKeypath

test "slice(2, keypath.segments.length) returns a new keypath with the second segment's value as the base, and the remaining segments as the segments", ->
  slice = @deepKeypath.slice(2, 4)
  equal slice.base, @obj.foo.bar
  deepEqual slice.key, 'baz.qux'

test "slice(2) returns a new keypath with the second segment's value as the base, and the remaining segments as the segments", ->
  slice = @deepKeypath.slice(2)
  equal slice.base, @obj.foo.bar
  deepEqual slice.key, 'baz.qux'

test "slice(0, 2) returns a new keypath with the same base but only the first two segments", ->
  slice = @deepKeypath.slice(0, 2)
  equal slice.base, @obj
  deepEqual slice.key, 'foo.bar'

test "slice(1, 3) returns a new keypath with the first segment as the base, and only extending through the following two segments", ->
  slice = @deepKeypath.slice(1, 3)
  equal slice.base, @obj.foo
  deepEqual slice.key, 'bar.baz'

test "slice(1, -1) counts from the end of the segments", ->
  slice = @deepKeypath.slice(1, -1)
  equal slice.base, @obj.foo
  deepEqual slice.key, 'bar.baz'


###
# terminalProperty()
###
test "terminalProperty() returns the final one-segment keypath component", ->
  slice = @deepKeypath.slice(-1)
  equal slice.base, @obj.foo.bar.baz
  deepEqual slice.segments, ['qux']


###
# getValue()
###
test "getValue() returns the value referenced by this keypath", ->
  equal @simpleKey.getValue(), @obj.foo
  equal @deepKeypath.getValue(), 'quxVal'

test "getValue() returns undefined if the key segment chain has been broken", ->
  @obj.foo.bar = 'newVal'
  equal typeof(@deepKeypath.getValue()), 'undefined'


###
# setValue(val)
###
test "setValue(val) on a simple key sets the referenced property to the given value", ->
  equal @simpleKey.setValue('newVal'), 'newVal'
  equal @obj.foo, 'newVal'

test "setValue(val) on a deep keypath sets the referenced property to the given value", ->
  equal @deepKeypath.setValue('newVal'), 'newVal'
  equal @obj.foo.bar.baz.qux, 'newVal'


###
# unsetValue()
###
test "unsetValue() on a simple key deletes the referenced property", ->
  @simpleKey.unsetValue()
  equal typeof(@obj.foo), 'undefined'

test "unsetValue() on a deep keypath deletes the referenced property", ->
  @deepKeypath.unsetValue()
  equal typeof(@obj.foo.bar.baz.qux), 'undefined'


###
# isEqual(other)
###
test "isEqual(other) returns true if both keypaths' bases are the same object and both segment arrays are equivalent", ->
  obj = {}
  path1 = new Batman.Keypath(obj, 'foo.bar')
  path2 = new Batman.Keypath(obj, 'foo.bar')
  ok path1.isEqual(path2)
  ok path2.isEqual(path1)

test "isEqual(other) returns false if the other keypath has a different object as its base", ->
  obj1 = {}
  obj2 = {}
  path1 = new Batman.Keypath(obj1, 'foo.bar')
  path2 = new Batman.Keypath(obj2, 'foo.bar')
  ok not path1.isEqual(path2)
  ok not path2.isEqual(path1)

test "isEqual(other) returns false if the other keypath has a different array of key segments", ->
  obj = {}
  path1 = new Batman.Keypath(obj, 'foo.bar')
  path2 = new Batman.Keypath(obj, 'foo.bar.baz')
  ok not path1.isEqual(path2)
  ok not path2.isEqual(path1)


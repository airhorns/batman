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


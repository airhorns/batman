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
# terminalProperty()
###
test "terminalProperty() returns the final one-segment keypath component", ->
  terminalProperty = @deepKeypath.terminalProperty()
  equal terminalProperty.base, @obj.foo.bar.baz
  deepEqual terminalProperty.segments, ['qux']


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

###
# working with segments that refer to objects with a non-Keypath propertyClass
###
test "working with Hashes", ->
  obj = new Batman.Object
    hash: new Batman.Hash
      foo: new Batman.Object(bar: 'nested value'),
      "foo.bar": 'flat value'

  equal obj.get('hash.foo.bar'), 'nested value'
  equal obj.hash.get('foo.bar'), 'flat value'

  property = obj.property('hash.foo.bar')
  ok property instanceof Batman.Keypath
  equal property.getValue(), 'nested value'

  obj.observe 'hash.foo.bar', hashFooBarSpy = createSpy()
  obj.set 'hash.foo.bar', 'new value'
  equal hashFooBarSpy.callCount, 1
  deepEqual hashFooBarSpy.lastCallArguments, ['new value', 'nested value']

  obj.hash.observe 'foo.bar', fooBarSpy = createSpy()
  obj.hash.set 'foo.bar', 'newer value'
  equal fooBarSpy.callCount, 1
  deepEqual fooBarSpy.lastCallArguments, ['newer value', 'flat value']

test "working with SimpleHashes", ->
  obj = new Batman.Object
    hash: new Batman.SimpleHash
      foo: new Batman.Object(bar: 'nested value'),
      "foo.bar": 'flat value'

  equal obj.get('hash.foo.bar'), 'nested value'
  equal obj.hash.get('foo.bar'), 'flat value'

  property = obj.property('hash.foo.bar')
  ok property instanceof Batman.Keypath
  equal property.getValue(), 'nested value'

  obj.observe 'hash.foo.bar', hashFooBarSpy = createSpy()
  obj.set 'hash.foo.bar', 'new value'
  equal hashFooBarSpy.callCount, 1
  deepEqual hashFooBarSpy.lastCallArguments, ['new value', 'nested value']

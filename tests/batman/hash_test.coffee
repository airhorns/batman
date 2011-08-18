QUnit.module 'Batman.Hash',
  setup: ->
    @hash = new Batman.Hash

test "constructor takes arguments", ->
  @hash = new Batman.Hash(foo: 'bar', baz: true)
  ok @hash.hasKey('foo')
  ok !@hash.hasKey('qux')

test "isEmpty() on an empty hash returns true", ->
  ok @hash.isEmpty()
  ok @hash.get('isEmpty')

test "has(key) on an empty hash returns false", ->
  equal @hash.hasKey('foo'), false

test "has(undefined) returns false", ->
  equal @hash.hasKey(undefined), false

test "hash(key) for an existing key who's value is undefined returns true", ->
  @hash.set('foo', undefined)
  ok @hash.hasKey('foo')

test "get(undefined) returns undefined", ->
  equal typeof(@hash.get(undefined)), 'undefined'

test "get(key) on an empty hash returns undefined", ->
  equal typeof(@hash.get('foo')), 'undefined'

test "get(key) where the key's value is undefined returns undefined", ->
  @hash.set('foo', undefined)
  equal @hash.length, 1
  equal @hash.get('foo'), undefined

test "set(key, val) stores the value for that key, such that hasKey(key) returns true and get(key) returns the stored value", ->
  @hash.set 'foo', 'bar'
  equal @hash.hasKey('foo'), true
  equal @hash.get('foo'), 'bar'

test "set(key, val) overwrites existing keys", ->
  @hash.set 'foo', 'bar'
  @hash.set 'foo', 'baz'
  equal @hash.hasKey('foo'), true
  equal @hash.get('foo'), 'baz'

test "set(key, val) keeps unequal keys distinct", ->
  key1 = {}
  key2 = {}
  @hash.set key1, 1
  @hash.set key2, 2
  equal @hash.get(key1), 1
  equal @hash.get(key2), 2

test "set(undefined, val) doesn't set", ->
  equal typeof(@hash.set undefined, true), 'undefined'
  equal @hash.length, 0

test "set(key, undefined) sets", ->
  equal typeof(@hash.set 'foo', undefined), 'undefined'
  equal @hash.length, 1

test "unset(key) unsets a key and its value from the hash, returning the existing key", ->
  @hash.set 'foo', 'bar'
  equal typeof(@hash.unset('foo')), 'undefined'
  equal @hash.hasKey('foo'), false

test "unset(key) doesn't touch any other keys", ->
  @hash.set 'foo', 'bar'
  @hash.set (o1 = {}), 1
  @hash.set (o2 = {}), 2
  @hash.set (o3 = {}), 3
  @hash.unset o2
  equal @hash.hasKey('foo'), true
  equal @hash.hasKey(o1), true
  equal @hash.hasKey(o2), false
  equal @hash.hasKey(o3), true

test "unset(undefined) doesn't touch any other keys", ->
  @hash.set 'foo', 'bar'
  @hash.set {}, 'bar'
  @hash.unset undefined
  equal @hash.length, 2

test "length is maintained over get, set, and unset", ->
  equal @hash.length, 0

  @hash.set 'foo', 'bar'
  equal @hash.length, 1

  @hash.set 'foo', 'baz'
  equal @hash.length, 1, "Length doesn't increase after setting an already existing key"

  @hash.set 'corge', 'qux'
  equal @hash.length, 2

  @hash.unset 'foo'
  equal @hash.length, 1, "Unsetting an existant key decreases the length"

  @hash.unset 'nonexistant'
  equal @hash.length, 1, "Unsetting an nonexistant key doesn't decrease the length"

  @hash.set 'bar', 'baz'
  @hash.clear()
  equal @hash.length, 0

  @hash.set o1 = {}, true
  equal @hash.length, 1
  @hash.set o2 = {}, true
  equal @hash.length, 2

  @hash.set o1, false, "Resetting object keys doesn't change length"
  equal @hash.length, 2

  @hash.clear()
  equal @hash.length, 0

test "equality(lhs, rhs) uses === by default", ->
  equal @hash.equality({}, {}), false
  equal @hash.equality(1, '1'), false
  equal @hash.equality('1', '1'), true

test "equality(lhs, rhs) uses lhs.isEqual or rhs.isEqual if available", ->
  o1 =
    isEqual: -> true
  o2 = {}
  equal @hash.equality(o1, o2), true
  equal @hash.equality(o2, o1), true

test "keys() returns an array of the hash's keys", ->
  @hash.set 'foo', 'bar'
  @hash.set (o1 = {}), 1
  @hash.set (o2 = {}), 2
  @hash.set 'foo', 'baz'
  @hash.set 'bar', 'buzz'
  @hash.set 'baz', 'blue'
  @hash.unset 'baz'
  keys = @hash.keys()
  equal keys.indexOf('baz'), -1
  notEqual keys.indexOf('foo'), -1
  notEqual keys.indexOf(o1), -1
  notEqual keys.indexOf(o2), -1
  notEqual keys.indexOf('bar'), -1

test "merge(other) returns a new hash without modifying the original", ->
  key1 = {}
  key2 = {}
  @hash.set key1, 1
  @hash.set key2, 2
  @hash.set 'foo', 'baz'
  @hash.set 'bar', 'buzz'

  other = new Batman.Hash
  other.set key1, 3
  other.set key3 = {}, 4

  merged = @hash.merge other

  ok merged.hasKey 'foo'
  ok merged.hasKey 'bar'
  ok merged.hasKey key1
  ok merged.hasKey key2
  ok merged.hasKey key3
  equal merged.get(key1), 3

  ok !@hash.hasKey(key3)
  equal @hash.get(key1), 1

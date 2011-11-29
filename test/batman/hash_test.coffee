suite 'Batman.Hash', ->
  hash = false
  setup ->
    hash = new Batman.Hash

  equalHashLength = (hash, length) ->
    assert.equal hash.length, length
    assert.equal hash.meta.get('length'), length

  test "constructor takes arguments", ->
    hash = new Batman.Hash(foo: 'bar', baz: true)
    assert.ok hash.hasKey('foo')
    assert.ok !hash.hasKey('qux')

  test "isEmpty() on an empty hash returns true", ->
    assert.ok hash.isEmpty()
    assert.ok hash.meta.get('isEmpty')

  test "hasKey(key) on an empty hash returns false", ->
    assert.equal hash.hasKey('foo'), false

  test "hasKey(undefined) returns false", ->
    assert.equal hash.hasKey(undefined), false

  test "hasKey(key) for an existing key whose value is undefined returns true", ->
    hash.set('foo', undefined)
    assert.ok hash.hasKey('foo')

  test "get(undefined) returns undefined", ->
    assert.equal typeof(hash.get(undefined)), 'undefined'

  test "get(key) on an empty hash returns undefined", ->
    assert.equal typeof(hash.get('foo')), 'undefined'

  test "get(key) where the key's value is undefined returns undefined", ->
    hash.set('foo', undefined)
    equalHashLength hash, 1
    assert.equal hash.get('foo'), undefined

  test "get(key) is not cached", ->
    hash.set('foo', 'bar')
    assert.equal hash.get('foo'), 'bar'
    hash.property('foo').value = 'baz'
    assert.equal hash.get('foo'), 'bar'

  test "set(key, val) stores the value for that key, such that hasKey(key) returns true and get(key) returns the stored value", ->
    hash.set 'foo', 'bar'
    assert.equal hash.hasKey('foo'), true
    assert.equal hash.get('foo'), 'bar'

  test "set(key, val) overwrites existing keys", ->
    hash.set 'foo', 'bar'
    hash.set 'foo', 'baz'
    assert.equal hash.hasKey('foo'), true
    assert.equal hash.get('foo'), 'baz'

  test "set(key, val) keeps unequal keys distinct", ->
    Batman.developer.suppress =>
      key1 = {}
      key2 = {}
      hash.set key1, 1
      hash.set key2, 2
      assert.equal hash.get(key1), 1
      assert.equal hash.get(key2), 2

  test "set(key, undefined) sets", ->
    assert.equal typeof(hash.set 'foo', undefined), 'undefined'
    equalHashLength hash, 1

  test "set(key, value) fires an itemsWereAdded event", ->
    hash.on 'itemsWereAdded', spy = createSpy()
    hash.set 'foo', 'bar'
    assert.deepEqual spy.lastCallArguments, ['foo']

  test "unset(key) unsets a key and its value from the hash, returning the existing value", ->
    hash.set 'foo', 'bar'
    assert.equal hash.unset('foo'), 'bar'
    assert.equal hash.hasKey('foo'), false

  test "unset(key) doesn't touch any other keys", ->
    Batman.developer.suppress =>
      hash.set 'foo', 'bar'
      hash.set (o1 = {}), 1
      hash.set (o2 = {}), 2
      hash.set (o3 = {}), 3
      hash.unset o2
      assert.equal hash.hasKey('foo'), true
      assert.equal hash.hasKey(o1), true
      assert.equal hash.hasKey(o2), false
      assert.equal hash.hasKey(o3), true

  test "unset(undefined) doesn't touch any other keys", ->
    Batman.developer.suppress =>
      hash.set 'foo', 'bar'
      hash.set {}, 'bar'
      hash.unset undefined
      equalHashLength hash, 2

  test "unset(key) fires an itemsWereRemoved event", ->
    hash.set 'foo', 'bar'
    hash.on 'itemsWereRemoved', spy = createSpy()
    hash.unset 'foo'
    assert.deepEqual spy.lastCallArguments, ['foo']

  test "length is maintained over get, set, and unset", ->
    Batman.developer.suppress =>
      equalHashLength hash, 0

      hash.set 'foo', 'bar'
      equalHashLength hash, 1

      hash.set 'foo', 'baz'
      equalHashLength hash, 1, "Length doesn't increase after setting an already existing key"

      hash.set 'corge', 'qux'
      equalHashLength hash, 2

      hash.unset 'foo'
      equalHashLength hash, 1, "Unsetting an existant key decreases the length"

      hash.unset 'nonexistant'
      equalHashLength hash, 1, "Unsetting an nonexistant key doesn't decrease the length"

      hash.set 'bar', 'baz'
      hash.clear()
      equalHashLength hash, 0

      hash.set o1 = {}, true
      equalHashLength hash, 1
      hash.set o2 = {}, true
      equalHashLength hash, 2

      hash.set o1, false, "Resetting object keys doesn't change length"
      equalHashLength hash, 2

      hash.clear()
      equalHashLength hash, 0

  test "using .hasKey(key) in an accessor registers the hash as a source of the property", ->
    obj = new Batman.Object
    obj.accessor 'hasFoo', => hash.hasKey('foo')
    obj.observe 'hasFoo', observer = createSpy()
    hash.set('foo', 'bar')
    assert.equal observer.callCount, 1
    hash.unset('foo')
    assert.equal observer.callCount, 2

  test "using .forEach() in an accessor registers the hash as a source of the property", ->
    obj = new Batman.Object
    obj.accessor 'foreach', => hash.forEach ->
    obj.observe 'foreach', observer = createSpy()
    hash.set('foo', 'bar')
    assert.equal observer.callCount, 1
    hash.unset('foo')
    assert.equal observer.callCount, 2

  test "using .isEmpty() in an accessor registers the hash as a source of the property", ->
    obj = new Batman.Object
    obj.accessor 'isEmpty', => hash.isEmpty()
    obj.observe 'isEmpty', observer = createSpy()
    hash.set('foo', 'bar')
    assert.equal observer.callCount, 1
    hash.unset('foo')
    assert.equal observer.callCount, 2

  test "using .keys() in an accessor registers the hash as a source of the property", ->
    obj = new Batman.Object
    obj.accessor 'keys', => hash.keys()
    obj.observe 'keys', observer = createSpy()
    hash.set('foo', 'bar')
    assert.equal observer.callCount, 1
    hash.unset('foo')
    assert.equal observer.callCount, 2

  test "using .merge(other) in an accessor registers the hash as a source of the property", ->
    obj = new Batman.Object
    otherHash = new Batman.Hash
    obj.accessor 'mergedWithOther', => hash.merge(otherHash)
    obj.observe 'mergedWithOther', observer = createSpy()
    hash.set('foo', 'bar')
    assert.equal observer.callCount, 1
    hash.unset('foo')
    assert.equal observer.callCount, 2

  test "equality(lhs, rhs) uses === by default", ->
    assert.equal hash.equality({}, {}), false
    assert.equal hash.equality(1, '1'), false
    assert.equal hash.equality('1', '1'), true

  test "equality(lhs, rhs) uses lhs.isEqual and rhs.isEqual if available", ->
    o1 = isEqual: -> true
    o2 = isEqual: -> true
    assert.equal hash.equality(o1, o2), true
    assert.equal hash.equality(o2, o1), true

  test "equality(lhs, rhs) returns true when both are NaN", ->
    assert.equal hash.equality(NaN, NaN), true

  test "keys() returns an array of the hash's keys", ->
    Batman.developer.suppress =>
      hash.set 'foo', 'bar'
      hash.set (o1 = {}), 1
      hash.set (o2 = {}), 2
      hash.set 'foo', 'baz'
      hash.set 'bar', 'buzz'
      hash.set 'baz', 'blue'
      hash.unset 'baz'
      test = (keys) ->
        assert.equal keys.indexOf('baz'), -1
        assert.notEqual keys.indexOf('foo'), -1
        assert.notEqual keys.indexOf(o1), -1
        assert.notEqual keys.indexOf(o2), -1
        assert.notEqual keys.indexOf('bar'), -1
      test(hash.keys())
      test(hash.meta.get('keys'))

  test "get/set/unset/hasKey with an undefined or null key works like any other, and they don't collide with each other", ->
    assert.equal hash.hasKey(undefined), false
    assert.equal hash.hasKey(null), false

    assert.equal hash.set(undefined, 1), 1
    assert.equal hash.get(undefined), 1
    assert.equal hash.hasKey(undefined), true
    assert.equal hash.hasKey(null), false
    assert.equal hash.get(null), undefined

    assert.equal hash.set(null, 1), 1
    assert.equal hash.get(null), 1
    assert.equal hash.hasKey(null), true

    hash.unset(null)
    assert.equal hash.hasKey(null), false
    assert.equal hash.hasKey(undefined), true

    hash.unset(undefined)
    assert.equal hash.hasKey(undefined), false

  test "get/set/unset with an undefined or null value works like any other", ->
    assert.equal hash.set(1, undefined), undefined
    assert.equal hash.get(1), undefined
    assert.equal hash.hasKey(1), true
    hash.unset(1)
    assert.equal hash.hasKey(1), false

    assert.equal hash.set(1, null), null
    assert.equal hash.get(1), null
    assert.equal hash.hasKey(1), true
    hash.unset(1)
    assert.equal hash.hasKey(1), false

  test "keys containing dots (.) are treated as simple keys, not keypaths", ->
    key = "foo.bar.baz"
    assert.equal hash.hasKey(key), false

    assert.equal hash.set(key, 1), 1
    assert.equal hash.get(key), 1
    assert.equal hash.hasKey(key), true

    assert.equal hash.hasKey(key), true

    hash.unset(key)
    assert.equal hash.hasKey(key), false

  test "clear() removes all keys from the hash", ->
    Batman.developer.suppress =>
      key1 = {}
      key2 = {}
      hash.set key1, 1
      hash.set key2, 2
      hash.set 'foo', 'baz'
      hash.set 'bar', 'buzz'

      hash.on 'itemsWereRemoved', spy = createSpy()
      hash.clear()
      equalHashLength hash, 0
      assert.deepEqual spy.lastCallArguments.sort(), [key1, key2, 'foo', 'bar'].sort()

  test "clear() fires key observers exactly once each, and exactly one 'change' and one 'itemsWereRemoved' event on the hash itself", ->
    Batman.developer.suppress =>
      objKey = {}
      hash.set objKey, 1
      hash.set 'foo', 'bar'

      hash.observe objKey, objKeyObserver = createSpy()
      hash.observe 'foo', fooObserver = createSpy()
      hash.on 'change', changeHandler = createSpy()
      hash.on 'itemsWereRemoved', itemsWereRemovedHandler = createSpy()

      hash.clear()

      assert.equal objKeyObserver.callCount, 1
      assert.deepEqual objKeyObserver.lastCallArguments, [undefined, 1]
      assert.equal fooObserver.callCount, 1
      assert.deepEqual fooObserver.lastCallArguments, [undefined, 'bar']
      assert.equal changeHandler.callCount, 1
      assert.deepEqual changeHandler.lastCallArguments, [hash, hash]
      assert.equal itemsWereRemovedHandler.callCount, 1
      assert.deepEqual itemsWereRemovedHandler.lastCallArguments, [objKey, 'foo']

  test "merge(other) returns a new hash without modifying the original", ->
    Batman.developer.suppress =>
      key1 = {}
      key2 = {}
      hash.set key1, 1
      hash.set key2, 2
      hash.set 'foo', 'baz'
      hash.set 'bar', 'buzz'

      other = new Batman.Hash
      other.set key1, 3
      other.set key3 = {}, 4

      merged = hash.merge other

      assert.ok merged.hasKey 'foo'
      assert.ok merged.hasKey 'bar'
      assert.ok merged.hasKey key1
      assert.ok merged.hasKey key2
      assert.ok merged.hasKey key3
      assert.equal merged.get(key1), 3

      assert.ok !hash.hasKey(key3)
      assert.equal hash.get(key1), 1

  test "filter(f) returns a filtered hash", ->
    Batman.developer.suppress =>
      key1 = {}
      key2 = {}
      hash.set key1, 1
      hash.set key2, 2
      hash.set 'foo', 'baz'
      hash.set 'bar', 'buzz'

      filtered = hash.filter (k, v) -> k in [key1, 'foo']
      assert.ok filtered instanceof Batman.Hash
      assert.equal filtered.length, 2
      assert.ok filtered.get key1
      assert.ok filtered.get 'foo'

  test "JSON.stringify(hash) returns the correct object representation for native types", ->
    obj =
      number: 1
      string: "abc"
      object:
        a: 1
        b: 2
        c: 3
    hash = new Batman.Hash obj
    assert.deepEqual JSON.parse(JSON.stringify(hash)), obj

  test "JSON.stringify(hash) returns the correct object representation for Batman.Object types", ->
    Batman.developer.suppress =>
      objectKey = new Batman.Object
      obj = new Batman.Object
        set: new Batman.Set 1, 2, 3
      obj.hashKey()
      hash = new Batman.Hash
      hash.set(objectKey, obj)
      expected = {}
      expected[objectKey.hashKey()] = set: [1,2,3]
      assert.deepEqual JSON.parse(JSON.stringify(hash)), expected

  test "update(pojo) updates the keys and values with those of the given object", ->
    hash.set('foo', 'foo1')
    hash.set('bar', 'bar1')

    hash.observe 'foo', fooObserver = createSpy()
    hash.observe 'bar', barObserver = createSpy()
    hash.observe 'size', sizeObserver = createSpy()
    hash.on 'change', changeHandler = createSpy()
    hash.on 'itemsWereAdded', itemsWereAddedHandler = createSpy()

    hash.update foo: 'foo2', size: 'medium'

    assert.deepEqual hash.toObject(), foo: 'foo2', bar: 'bar1', size: 'medium'

    assert.equal fooObserver.callCount, 1
    assert.deepEqual fooObserver.lastCallArguments, ['foo2', 'foo1']
    assert.equal barObserver.callCount, 0
    assert.equal sizeObserver.callCount, 1
    assert.deepEqual sizeObserver.lastCallArguments, ['medium', undefined]
    assert.equal changeHandler.callCount, 1
    assert.deepEqual changeHandler.lastCallArguments, [hash, hash]
    assert.equal itemsWereAddedHandler.callCount, 1
    assert.deepEqual itemsWereAddedHandler.lastCallArguments, ['size']

  test "replace(pojo) replaces the keys and values with those of the given object", ->
    hash.set('foo', 'foo1')
    hash.set('bar', 'bar1')
    hash.set('baz', 'baz1')

    hash.observe 'foo', fooObserver = createSpy()
    hash.observe 'bar', barObserver = createSpy()
    hash.observe 'baz', bazObserver = createSpy()
    hash.observe 'material', materialObserver = createSpy()
    hash.observe 'size', sizeObserver = createSpy()
    hash.on 'change', changeHandler = createSpy()
    hash.on 'itemsWereAdded', itemsWereAddedHandler = createSpy()
    hash.on 'itemsWereRemoved', itemsWereRemovedHandler = createSpy()

    hash.replace foo: 'foo2', material: 'silk', size: 'medium'

    assert.deepEqual hash.toObject(), foo: 'foo2', material: 'silk', size: 'medium'

    assert.equal fooObserver.callCount, 1
    assert.deepEqual fooObserver.lastCallArguments, ['foo2', 'foo1']
    assert.equal barObserver.callCount, 1
    assert.deepEqual barObserver.lastCallArguments, [undefined, 'bar1']
    assert.equal bazObserver.callCount, 1
    assert.deepEqual bazObserver.lastCallArguments, [undefined, 'baz1']
    assert.equal materialObserver.callCount, 1
    assert.deepEqual materialObserver.lastCallArguments, ['silk', undefined]
    assert.equal sizeObserver.callCount, 1
    assert.deepEqual sizeObserver.lastCallArguments, ['medium', undefined]
    assert.equal changeHandler.callCount, 1
    assert.deepEqual changeHandler.lastCallArguments, [hash, hash]
    assert.equal itemsWereAddedHandler.callCount, 1
    assert.equal itemsWereAddedHandler.lastCallArguments.length, 2
    assert.ok 'material' in itemsWereAddedHandler.lastCallArguments
    assert.ok 'size' in itemsWereAddedHandler.lastCallArguments
    assert.equal itemsWereRemovedHandler.callCount, 1
    assert.equal itemsWereRemovedHandler.lastCallArguments.length, 2
    assert.ok 'bar' in itemsWereRemovedHandler.lastCallArguments
    assert.ok 'baz' in itemsWereRemovedHandler.lastCallArguments

  test "update(hash) works with other batman hashes as expected", ->
    hash.set('foo', 'foo')
    hash.set('bar', 'bar')
    otherHash = new Batman.Hash
      foo: 'otherFoo'
      baz: 'otherBaz'
    hash.update(otherHash)

    assert.deepEqual hash.toObject(), foo: 'otherFoo', bar: 'bar', baz: 'otherBaz'

  test "replace(hash) works with other batman hashes as expected", ->
    hash.set('foo', 'foo')
    hash.set('bar', 'bar')
    otherHash = new Batman.Hash
      foo: 'otherFoo'
      baz: 'otherBaz'
    hash.replace(otherHash)

    assert.deepEqual hash.toObject(), foo: 'otherFoo', baz: 'otherBaz'

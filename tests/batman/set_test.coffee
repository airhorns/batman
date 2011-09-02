setTestSuite = ->
  test "isEmpty() on an empty set returns true", ->
    ok @set.isEmpty()
    ok @set.get 'isEmpty'

  test "has(item) on an empty set returns false", ->
    equal @set.has('foo'), false

  test "has(undefined) returns false", ->
    equal @set.has(undefined), false

  test "add(items...) adds the items to the set, such that has(item) returns true for each item, and increments the set's length accordingly", ->
    deepEqual @set.add('foo', 'bar'), ['foo', 'bar']
    equal @set.length, 2
    equal @set.has('foo'), true
    equal @set.has('bar'), true

  test "add(items...) only increments length for items which weren't already there, and only returns items which weren't already there", ->
    deepEqual @set.add('foo'), ['foo']
    deepEqual @set.add('foo', 'bar'), ['bar']
    deepEqual @set.add('baz', 'baz'), ['baz']

    equal @set.length, 3

  test "remove(items...) removes the items from the set, returning the item and not touching any others", ->
    @set.add('foo', o1={}, o2={}, o3={})

    deepEqual @set.remove(o2, o3), [o2, o3]

    equal @set.length, 2
    equal @set.has('foo'), true
    equal @set.has(o1), true
    equal @set.has(o2), false
    equal @set.has(o3), false

  test "remove(items...) returns an array of only the items that were there in the first place", ->
    @set.add('foo')
    @set.add('baz')

    deepEqual @set.remove('foo', 'bar'), ['foo']
    deepEqual @set.remove('foo'), []

  test "remove(items...) only decrements length for items that are there to be removed", ->
    @set.add('foo', 'bar', 'baz')
    @set.remove('foo', 'qux')
    @set.remove('bar', 'bar')

    equal @set.length, 1

  test "merge(other) returns a merged set without changing the original", ->
    @set.add('foo', 'bar', 'baz')
    other = new Batman.Set
    other.add('qux', 'buzz')
    merged = @set.merge(other)

    for v in ['foo', 'bar', 'baz', 'qux', 'buzz']
      ok merged.has(v)
    equal merged.length, 5

    ok !@set.has('qux')
    ok !@set.has('buzz')

  test "merge, add, remove, and clear fire length observers", ->
    spy = createSpy()
    @set.observe('length', spy)

    @set.add('foo', 'bar')
    equal spy.callCount, 1, 'add(items...) fires length observers'

    @set.remove('foo')
    equal spy.callCount, 2, 'remove(items...) fires length observers'

    @set.clear()
    equal spy.callCount, 3, 'clear() fires length observers'

    @set.merge(new Batman.Set('qux', 'baz'))
    equal spy.callCount, 4, 'merge() fires length observers'
  
  test "indexedBy(key) returns a memoized Batman.SetIndex for that key", ->
    index = @set.indexedBy('length')
    ok index instanceof Batman.SetIndex
    equal index.base, @set
    equal index.key, 'length'
    strictEqual @set.indexedBy('length'), index

  test "get('indexedBy.someKey') returns the same index as indexedBy(key)", ->
    strictEqual @set.get('indexedBy.length'), @set.indexedBy('length')

  test "sortedBy(key) returns a memoized Batman.SetSort for that key", ->
    sort = @set.sortedBy('length')
    ok sort instanceof Batman.SetSort
    equal sort.base, @set
    equal sort.key, 'length'
    strictEqual @set.sortedBy('length'), sort

  test "get('sortedBy.someKey') returns the same index as sortedBy(key)", ->
    strictEqual @set.get('sortedBy.length'), @set.sortedBy('length')


QUnit.module 'Batman.Set',
  setup: ->
    @set = new Batman.Set

setTestSuite()

QUnit.module 'Batman.SortableSet',
  setup: ->
    @set = new Batman.SortableSet

setTestSuite()

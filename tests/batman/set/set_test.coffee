basicSetTestSuite = ->
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

  test "find(f) returns the first item for which f is true", 1, ->
    @set.add(1, 2, 3, 5)
    result = @set.find (n) -> n % 2 is 0
    equal result, 2

  test "find(f) returns undefined when f is false for all items", 1, ->
    @set.add(1, 2)
    result = @set.find -> false
    equal result, undefined

  test "find(f) works with booleans", 2, ->
    @set.add(false, true)
    result = @set.find (item) -> item is true
    equal result, true
    @set.clear()
    @set.add(true, false)
    result = @set.find (item) -> item is false
    equal result, false

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

  test "add(items...) fires length observers", ->
    @set.observe 'length', spy = createSpy()
    @set.add('foo')
    deepEqual spy.lastCallArguments, [1, 0]

    @set.add('baz', 'bar')
    deepEqual spy.lastCallArguments, [3, 1]

    equal spy.callCount, 2
    @set.add('bar')
    equal spy.callCount, 2

  test "add(items...) fires itemsWereAdded handlers", ->
    @set.on 'itemsWereAdded', spy = createSpy()
    @set.add('foo')
    deepEqual spy.lastCallArguments, ['foo']

    @set.add('baz', 'bar')
    deepEqual spy.lastCallArguments, ['baz', 'bar']

    equal spy.callCount, 2
    @set.add('bar')
    equal spy.callCount, 2

  test "remove(items...) fires length observers", ->
    @set.observe 'length', spy = createSpy()
    @set.add('foo')
    @set.remove('foo')
    deepEqual spy.lastCallArguments, [0, 1]

    equal spy.callCount, 2
    @set.remove('foo')
    equal spy.callCount, 2

  test "remove(items...) fires itemsWereRemoved handlers", ->
    @set.on 'itemsWereRemoved', spy = createSpy()
    @set.add('foo')
    @set.remove('foo')
    deepEqual spy.lastCallArguments, ['foo']

    equal spy.callCount, 1
    @set.remove('foo')
    equal spy.callCount, 1

  test "clear() fires length observers", ->
    spy = createSpy()
    @set.observe('length', spy)

    @set.add('foo', 'bar')
    @set.clear()
    equal spy.callCount, 2, 'clear() fires length observers'

  test "clear() fires itemsWereRemoved handlers", ->
    spy = createSpy()
    @set.on('itemsWereRemoved', spy)

    @set.add('foo', 'bar')
    @set.clear()
    equal spy.callCount, 1, 'clear() fires itemsWereRemoved handlers'

  test "replace() doesn't fire length observers if the size didn't change", ->
    spy = createSpy()
    other = new Batman.Set
    other.add('baz', 'cux')
    @set.add('foo', 'bar')
    @set.observe('length', spy)
    @set.replace(other)
    equal spy.callCount, 0, 'replaces() fires length observers'

  test "replace() fires length observers if the size has changed", ->
    spy = createSpy()
    other = new Batman.Set
    other.add('baz', 'cux', 'cuux')
    @set.add('foo', 'bar')
    @set.observe('length', spy)
    @set.replace(other)
    equal spy.callCount, 1, 'replaces() fires length observers'

  test "replace() fires item-based mutation events for Batman.Set", ->
    return if @set.console isnt Batman.Set
    addedSpy = createSpy()
    removedSpy = createSpy()
    other = new Batman.Set
    other.add('baz', 'cux')
    @set.add('foo', 'bar')
    @set.on('itemsWereAdded', addedSpy)
    @set.on('itemsWereRemoved', removedSpy)
    @set.replace(other)
    equal addedSpy.callCount, 1, 'replaces() fires itemsWereAdded observers'
    equal removedSpy.callCount, 1, 'replaces() fires itemsWereRemoved observers'

  test "replace() removes existing items", ->
    spy = createSpy()
    other = new Batman.Set
    other.add('baz', 'cux')
    @set.add('foo', 'bar')
    @set.replace(other)
    deepEqual @set.toArray(), other.toArray()

  test "filter() returns a set", ->
    @set.add 'foo', 'bar', 'baz'

    @filtered = @set.filter (v) -> v.slice(0, 1) is 'b'
    equal @filtered.length, 2
    ok @filtered.has 'bar'
    ok @filtered.has 'baz'

  test "using .has(key) in an accessor registers the set as a source of the property", ->
    obj = new Batman.Object
    obj.accessor 'hasFoo', => @set.has('foo')
    obj.observe 'hasFoo', observer = createSpy()
    @set.add('foo')
    equal observer.callCount, 1
    @set.add('bar')
    equal observer.callCount, 1
    @set.remove('foo')
    equal observer.callCount, 2

  test ".observe('isEmpty') fires when the value actually changes", ->
    @set.add('foo')
    @set.observe 'isEmpty', observer = createSpy()
    @set.add('bar')
    equal observer.callCount, 0
    @set.remove('bar')
    equal observer.callCount, 0
    @set.remove('foo')
    equal observer.callCount, 1
    @set.add('foo')
    equal observer.callCount, 2

  test "using .toArray() in an accessor registers the set as a source of the property", ->
    obj = new Batman.Object
    obj.accessor 'array', => @set.toArray()
    obj.observe 'array', observer = createSpy()
    @set.add('foo')
    equal observer.callCount, 1
    @set.add('bar')
    equal observer.callCount, 2

  test "using .forEach() in an accessor registers the set as a source of the property", ->
    obj = new Batman.Object
    obj.accessor 'foreach', => @set.forEach(->); []
    obj.observe 'foreach', observer = createSpy()
    @set.add('foo')
    equal observer.callCount, 1
    @set.add('bar')
    equal observer.callCount, 2

  test "using .merge() in an accessor registers the original and merged sets as sources of the property", ->
    obj = new Batman.Object
    otherSet = new Batman.Set
    obj.accessor 'mergedWithOther', => @set.merge(otherSet)
    obj.observe 'mergedWithOther', observer = createSpy()
    @set.add('foo')
    equal observer.callCount, 1
    @set.add('bar')
    equal observer.callCount, 2
    otherSet.add('baz')
    equal observer.callCount, 3

  test "using .find() in an accessor registers the set as a source of the property", ->
    obj = new Batman.Object
    obj.accessor 'firstBiggerThan2', => @set.find (n) -> n > 2
    obj.observe 'firstBiggerThan2', observer = createSpy()
    @set.add(3)
    equal observer.callCount, 1
    strictEqual obj.get('firstBiggerThan2'), 3
    @set.add(4)
    equal observer.callCount, 1
    strictEqual obj.get('firstBiggerThan2'), 3
    @set.remove(3)
    equal observer.callCount, 2
    strictEqual obj.get('firstBiggerThan2'), 4


  test "using .toJSON() returns an array representation of the set", ->
    set = new Batman.Set
    set.add new Batman.Object foo: 'bar'
    set.add new Batman.Object bar: 'baz'
    deepEqual set.toJSON(), set.toArray()

sortAndIndexSuite = ->
  test "sortedBy(property, order) returns a cached SetSort", ->
    ascendingFoo = @set.sortedBy('foo')
    strictEqual @set.sortedBy('foo'), ascendingFoo
    descendingFoo = @set.sortedBy('foo', 'desc')
    strictEqual @set.sortedBy('foo', 'desc'), descendingFoo

    notEqual ascendingFoo, descendingFoo
    equal ascendingFoo.base, @base
    equal ascendingFoo.key, 'foo'
    equal ascendingFoo.descending, no
    equal descendingFoo.base, @base
    equal descendingFoo.key, 'foo'
    equal descendingFoo.descending, yes

  test "sortedBy(deepProperty, order) returns a cached SetSort", ->
    ascendingFoo = @set.sortedBy('foo.bar')
    strictEqual @set.sortedBy('foo.bar'), ascendingFoo
    descendingFoo = @set.sortedBy('foo.bar', 'desc')
    strictEqual @set.sortedBy('foo.bar', 'desc'), descendingFoo

    notEqual ascendingFoo, descendingFoo
    equal ascendingFoo.base, @base
    equal ascendingFoo.key, 'foo.bar'
    equal ascendingFoo.descending, no
    equal descendingFoo.base, @base
    equal descendingFoo.key, 'foo.bar'
    equal descendingFoo.descending, yes

  test "get('sortedBy.name') returns .sortedBy('name')", ->
    strictEqual @set.get('sortedBy.name'), @set.sortedBy('name')

  test "get('sortedByDescending.name') returns .sortedBy('name', 'desc')", ->
    strictEqual @set.get('sortedByDescending.name'), @set.sortedBy('name', 'desc')

  test "sortedBy(deepProperty) sorts by the deep property instead of traversing the keypath", ->
    sort = @set.sortedBy('foo.bar')
    deepEqual sort.toArray(), [@o1, @o2, @o3]

  test "get('sortedBy').get(deepProperty) sorts by the deep property instead of traversing the keypath", ->
    sort = @set.get('sortedBy').get('foo.bar')
    deepEqual sort.toArray(), [@o1, @o2, @o3]

  test "sortedBy(deepProperty, 'desc') sorts by the deep property instead of traversing the keypath", ->
    sort = @set.sortedBy('foo.bar', 'desc')
    deepEqual sort.toArray(), [@o3, @o2, @o1]

  test "get('sortedByDescending').get(deepProperty) sorts by the deep property instead of traversing the keypath", ->
    sort = @set.get('sortedByDescending').get('foo.bar')
    deepEqual sort.toArray(), [@o3, @o2, @o1]

  test "indexedBy(key) returns a memoized Batman.SetIndex for that key", ->
    index = @set.indexedBy('length')
    ok index instanceof Batman.SetIndex
    equal index.base, @base
    equal index.key, 'length'
    strictEqual @set.indexedBy('length'), index

  test "get('indexedBy.someKey') returns the same index as indexedBy(key)", ->
    strictEqual @set.get('indexedBy.length'), @set.indexedBy('length')

  test "indexedBy(deepProperty) indexes by the deep property instead of traversing the keypath", ->
    index = @set.indexedBy('foo.bar')
    deepEqual index.get(2).toArray(), [@o2]

  test "get('indexedBy').get(deepProperty) indexes by the deep property instead of traversing the keypath", ->
    index = @set.get('indexedBy').get('foo.bar')
    deepEqual index.get(2).toArray(), [@o2]

  test "indexedByUnique(key) returns a memoized UniqueSetIndex for that key", ->
    Batman.developer.suppress =>
      index = @set.indexedByUnique('foo')
      ok index instanceof Batman.UniqueSetIndex
      equal index.base, @base
      equal index.key, 'foo'
      strictEqual @set.indexedByUnique('foo'), index

  test "get('indexedByUnique.foo') returns a memoized UniqueSetIndex for the key 'foo'", ->
    Batman.developer.suppress =>
      strictEqual @set.get('indexedByUnique.foo'), @set.indexedByUnique('foo')


QUnit.module 'Batman.Set',
  setup: ->
    @set = new Batman.Set

basicSetTestSuite()

QUnit.module 'Batman.SetIntersection set polymorphism',
  setup: ->
    @set = new Batman.SetIntersection(new Batman.Set, new Batman.Set)

basicSetTestSuite()

QUnit.module 'Batman.SetUnion set polymorphism',
  setup: ->
    @set = new Batman.SetUnion(new Batman.Set, new Batman.Set)

basicSetTestSuite()

QUnit.module 'Batman.Set indexedBy and SortedBy' ,
  setup: ->
    @base = @set = new Batman.Set

    @set.add @o3 =
      foo:
        bar: 3

    @set.add @o1 =
      foo:
        bar: 1

    @set.add @o2 =
      foo:
        bar: 2

sortAndIndexSuite()

QUnit.module "Batman.SetSort set polymorphism"
  setup: ->
    set = new Batman.Set
    @set = set.sortedBy('')

basicSetTestSuite()

QUnit.module 'Batman.SetSort indexedBy and SortedBy' ,
  setup: ->
    @base = new Batman.Set
    @set = @base.sortedBy('')

    @set.add @o3 =
      foo:
        bar: 3

    @set.add @o1 =
      foo:
        bar: 1

    @set.add @o2 =
      foo:
        bar: 2

sortAndIndexSuite()


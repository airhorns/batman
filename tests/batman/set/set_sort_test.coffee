QUnit.module 'Batman.SetSort',
  setup: ->
    @zeke = Batman name: 'Zeke'
    @mary = Batman name: 'Mary'
    @fred = Batman name: 'Fred'
    @jill = Batman name: 'Jill'

    @byZeke = Batman author: @zeke
    @byMary = Batman author: @mary
    @byFred = Batman author: @fred, prop: "byFred"
    @anotherByFred = Batman author: @fred, prop: "anotherByFred"

    @base = new Batman.Set(@byMary, @byFred, @byZeke, @anotherByFred)
    @authorNameSort = new Batman.SetSort(@base, 'author.name')

    # not yet in the set:
    @byJill = Batman author: @jill
    @anotherByZeke = Batman author: @zeke

assertSorted = (array, compareFunction) ->
  last = null
  for item, i in array
    if last
      ok compareFunction(last, item) < 1
    last = item

test "new Batman.SetSort(set, key) constructs a sort on the set for that keypath", ->
  equal @authorNameSort.base, @base
  equal @authorNameSort.key, 'author.name'
  equal @authorNameSort.descending, no

test "new Batman.SetSort(set, key, 'desc') constructs a reversed sort", ->
  reversedSort = new Batman.SetSort(@base, 'author.name', 'desc')
  equal reversedSort.base, @base
  equal reversedSort.key, 'author.name'
  equal reversedSort.descending, yes

test "toArray() returns the sorted items", ->
  noName = Batman()
  anotherNoName = Batman()
  nullName = Batman
    author: Batman
      name: null
  naNName = Batman
    author: Batman
      name: NaN
  numberedName = Batman
    author: Batman
      name: 9
  anotherNumberedName = Batman
    author: Batman
      name: 80
  trueName = Batman
    author: Batman
      name: true
  falseName = Batman
    author: Batman
      name: false
  @base.add noName
  @base.add nullName
  @base.add anotherNoName
  @base.add anotherNumberedName
  @base.add naNName
  @base.add numberedName
  @base.add trueName
  @base.add falseName
  @base.remove @anotherByFred

  assertSorted(@authorNameSort.toArray(), Batman.SetSort::compare)

test "forEach(iterator) and toArray() go in reverse if sort is descending", ->
  noName = Batman()
  nullName = Batman
    author: Batman
      name: null
  naNName = Batman
    author: Batman
      name: NaN
  numberedName = Batman
    author: Batman
      name: 9
  anotherNumberedName = Batman
    author: Batman
      name: 80
  trueName = Batman
    author: Batman
      name: true
  falseName = Batman
    author: Batman
      name: false
  @base.add noName
  @base.add nullName
  @base.add anotherNumberedName
  @base.add naNName
  @base.add numberedName
  @base.add trueName
  @base.add falseName
  @base.remove @anotherByFred

  descendingAuthorNameSort = new Batman.SetSort(@base, 'author.name', 'desc')
  sorted = descendingAuthorNameSort.toArray()
  assertSorted(sorted, (a,b) -> Batman.SetSort::compare(b,a))

  collector = []
  descendingAuthorNameSort.forEach (item) -> collector.push(item)
  deepEqual sorted, collector

test "forEach(iterator) loops in the correct order", ->
  expect 4
  expected = [@byFred, @anotherByFred, @byMary, @byZeke]
  @authorNameSort.forEach (item, i) ->
    ok item is expected[i]

test "toArray() returns the correct order", ->
  expected = [@byFred, @anotherByFred, @byMary, @byZeke]
  deepEqual @authorNameSort.toArray(), expected

test "toArray() returns the correct order when sorting on key which returns a function by calling the function", ->
  class Test
    constructor: (@name) ->
    getName: -> @name

  a = new Test('a')
  b = new Test('b')
  c = new Test('c')

  base = new Batman.Set(b, a, c)
  sorted = base.sortedBy('getName')
  deepEqual sorted.toArray(), [a, b, c]

test "toArray() returns the correct order when sorting on the 'valueOf' key to sort primitives", ->
  @base = new Batman.Set('b', 'c', 'a')
  sorted = @base.sortedBy('valueOf')
  deepEqual sorted.toArray(), ['a', 'b', 'c']

test "toArray() includes newly added items in the correct order", ->
  @base.add @byJill
  expected = [@byFred, @anotherByFred, @byJill, @byMary, @byZeke]
  deepEqual @authorNameSort.toArray(), expected

  @base.add @anotherByZeke
  expected = [@byFred, @anotherByFred, @byJill, @byMary, @byZeke, @anotherByZeke]
  deepEqual @authorNameSort.toArray(), expected

test "toArray() does not include items which have been removed", ->
  @base.remove @anotherByFred
  expected = [@byFred, @byMary, @byZeke]
  equal @authorNameSort.toArray().length, 3
  deepEqual @authorNameSort.toArray(), expected

  @base.remove @byZeke
  expected = [@byFred, @byMary]
  equal @authorNameSort.toArray().length, 2
  deepEqual @authorNameSort.toArray(), expected

test "setting a new value of the sorted property on one of the items triggers an update", ->
  switchedAuthorToMary = @anotherByFred
  switchedAuthorToMary.set('author', @mary)
  expected = [@byFred, @byMary, switchedAuthorToMary, @byZeke]
  deepEqual @authorNameSort.toArray(), expected

test "setting a new value of the sorted property on an item which has been removed should not trigger an update", ->
  @base.remove @anotherByFred
  reIndex = spyOn(@authorNameSort, "_reIndex")

  @anotherByFred.set('author', @mary)

  equal reIndex.called, false
  expected = [@byFred, @byMary, @byZeke]
  deepEqual @authorNameSort.toArray(), expected

test "stopObserving() forgets all observers", ->
  @authorNameSort.stopObserving()
  expected = [@byFred, @anotherByFred, @byMary, @byZeke]

  @base.add @byJill
  deepEqual @authorNameSort.toArray(), expected

  @base.remove @byZeke
  deepEqual @authorNameSort.toArray(), expected

  @byFred.set('author', @mary)
  deepEqual @authorNameSort.toArray(), expected

QUnit.module 'Batman.Paginator'
  setup: ->
    @data = ['a','b','c','d','e','f','g','h','i','j']

test "constructing a paginator with a specified page limit", ->
  p = new Batman.Paginator limit: 2
  equal p.limit, 2

test "get('page') is based on the offset and limit", ->
  p = new Batman.Paginator offset: 2, limit: 2
  equal p.get('page'), 2
  p = new Batman.Paginator offset: 5, limit: 10
  equal p.get('page'), 1.5

test "set('page', pageNumber) changes the offset based on the limit", ->
  p = new Batman.Paginator limit: 10
  p.set('page', 2)
  equal p.get('offset'), 10
  p.set('page', 2.51)
  equal p.get('offset'), 15

test "get('toArray') returns items from the cache for the paginator's current offset and limit", ->
  p = new Batman.Paginator
    offset: 2
    limit: 2
    cache: new Batman.Paginator.Cache(0,10,@data)
  deepEqual p.get('toArray'), ['c','d']

test "get('toArray') calls loadItemsForOffsetAndLimit and returns an empty array if there is no cache", ->
  p = new Batman.Paginator
    offset: 4
    limit: 2
  p.loadItemsForOffsetAndLimit = createSpy()
  deepEqual p.get('toArray'), []
  equal p.loadItemsForOffsetAndLimit.callCount, 1
  deepEqual p.loadItemsForOffsetAndLimit.lastCallArguments, [4,2]

test "get('pageCount') returns the total number of pages based on limit and totalCount", ->
  p = new Batman.Paginator totalCount: 21, limit: 10
  equal p.get('pageCount'), 3

test "numeric setters cast strings to numbers", ->
  p = new Batman.Paginator
  p.set('totalCount', '100')
  strictEqual p.get('totalCount'), 100
  strictEqual p.totalCount, 100
  p.set('limit', '10')
  strictEqual p.get('limit'), 10
  strictEqual p.limit, 10
  p.set('offset', '10')
  strictEqual p.get('offset'), 10
  strictEqual p.offset, 10
  p.set('page', '2')
  strictEqual p.get('page'), 2
  strictEqual p.get('offset'), 10
  strictEqual p.offset, 10



QUnit.module 'Batman.Paginator.Cache'
  setup: ->
    @slice = new Batman.Paginator.Cache(2, 5, ['a','b','c','d'])

test "constructing with an offset, limit, and array of items", ->
  equal @slice.offset, 2
  equal @slice.limit, 5
  equal @slice.length, 4
  equal @slice.reach, 7

test "containsItemsForOffsetAndLimit(offset, limit) returns true if and only if this slice covers the given offset and limit", ->
  equal @slice.containsItemsForOffsetAndLimit(3,3), true
  equal @slice.containsItemsForOffsetAndLimit(2,5), true
  equal @slice.containsItemsForOffsetAndLimit(2,6), false
  equal @slice.containsItemsForOffsetAndLimit(1,5), false

test "itemsForOffsetAndLimit(offset, limit) returns an array of the items in that range", ->
  deepEqual @slice.itemsForOffsetAndLimit(3,2), ['b','c']
  deepEqual @slice.itemsForOffsetAndLimit(2,5), ['a','b','c','d']

test "itemsForOffsetAndLimit(offset, limit) returns undefined if the slice does not contain the given range", ->
  strictEqual @slice.itemsForOffsetAndLimit(1,3), undefined
  strictEqual @slice.itemsForOffsetAndLimit(2,6), undefined

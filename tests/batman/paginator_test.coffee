QUnit.module 'Batman.Paginator'
  setup: ->
    @data = ['a','b','c','d','e','f','g','h','i','j']
    @p = new Batman.Paginator
      offset: 4
      limit: 2
    @p.loadItemsForOffsetAndLimit = createSpy()

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
  deepEqual @p.get('toArray'), []
  equal @p.loadItemsForOffsetAndLimit.callCount, 1
  deepEqual @p.loadItemsForOffsetAndLimit.lastCallArguments, [4,2]

test "get('toArray') won't call loadItemsForOffsetAndLimit if it's already loading that range", ->
  @p.markAsLoadingOffsetAndLimit(4, 2)
  deepEqual @p.get('toArray'), []
  equal @p.loadItemsForOffsetAndLimit.callCount, 0
  equal @p.loadingRange.offset, 4
  equal @p.loadingRange.limit, 2

test "get('toArray') won't call loadItemsForOffsetAndLimit if it's loading a superset of that range", ->
  @p.markAsLoadingOffsetAndLimit(3, 5)
  deepEqual @p.get('toArray'), []
  equal @p.loadItemsForOffsetAndLimit.callCount, 0
  equal @p.loadingRange.offset, 3
  equal @p.loadingRange.limit, 5

test "get('toArray') will call loadItemsForOffsetAndLimit if it's only loading a proper subset of that range", ->
  @p.markAsLoadingOffsetAndLimit(4, 1)
  deepEqual @p.get('toArray'), []
  equal @p.loadItemsForOffsetAndLimit.callCount, 1
  deepEqual @p.loadItemsForOffsetAndLimit.lastCallArguments, [4,2]
  equal @p.loadingRange.offset, 4
  equal @p.loadingRange.limit, 2

test "updateCache(offset, limit, items) doesn't do anything if the paginator is already loading a range which isn't covered by the update", ->
  @p.markAsLoadingOffsetAndLimit(4, 2)
  @p.updateCache(4, 1, ['e'])
  strictEqual @p.cache, undefined

test "updateCache(offset, limit, items) creates a new cache with the given args if we aren't in the middle of a load", ->
  @p.updateCache(4, 1, ['e'])
  strictEqual @p.cache.offset, 4
  strictEqual @p.cache.limit, 1
  deepEqual @p.cache.items, ['e']

test "updateCache(offset, limit, items) does do the update if we are marked as loading a subset of the given range", ->
  @p.markAsLoadingOffsetAndLimit(4, 1)
  @p.updateCache(4, 2, ['e', 'f'])
  strictEqual @p.cache.offset, 4
  strictEqual @p.cache.limit, 2
  deepEqual @p.cache.items, ['e', 'f']

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

test "coversOffsetAndLimit(offset, limit) returns true if and only if this slice covers the given offset and limit", ->
  equal @slice.coversOffsetAndLimit(3,3), true
  equal @slice.coversOffsetAndLimit(2,5), true
  equal @slice.coversOffsetAndLimit(2,6), false
  equal @slice.coversOffsetAndLimit(1,5), false

test "itemsForOffsetAndLimit(offset, limit) returns an array of the items in that range", ->
  deepEqual @slice.itemsForOffsetAndLimit(3,2), ['b','c']
  deepEqual @slice.itemsForOffsetAndLimit(2,5), ['a','b','c','d']

test "itemsForOffsetAndLimit(offset, limit) returns a left-padded array with undefineds if the slice does not contain the given range", ->
  ary = @slice.itemsForOffsetAndLimit(0,4)
  equal ary.length, 4
  strictEqual ary[0], undefined
  strictEqual ary[1], undefined
  strictEqual ary[2], 'a'
  strictEqual ary[3], 'b'


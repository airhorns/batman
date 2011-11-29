QUnit.module 'Batman.ModelPaginator'
  setup: ->
    class @Thing extends Batman.Model
      @load: createSpy()
    @thingPaginator = new Batman.ModelPaginator model: @Thing

test "the model's .load method gets called with the paginator's .params merged in", ->
  @thingPaginator.params = owner_id: 5
  @thingPaginator.loadItemsForOffsetAndLimit(0, 10)
  deepEqual @Thing.load.lastCallArguments?[0],
    offset: 0
    limit: 10
    owner_id: 5
  

test "loadItemsForOffsetAndLimit(offset, limit) calls .load on the model class with the appropriate params", ->
  @thingPaginator.set('cachePadding', 30)
  @thingPaginator.loadItemsForOffsetAndLimit(100, 20)
  deepEqual @Thing.load.lastCallArguments?[0],
    offset: 70
    limit: 80

  callback = @Thing.load.lastCallArguments?[1]
  callback.call(null, null, (things = [new @Thing(id:1), new @Thing(id:2)]))
  equal @thingPaginator.cache.offset, 70
  equal @thingPaginator.cache.limit, 80
  equal @thingPaginator.cache.items, things

test "overriding paramsForOffsetAndLimit, offsetFromParams, and limitFromParams lets you construct params however you like", ->
  @thingPaginator.paramsForOffsetAndLimit = (offset, limit) ->
    limit *= 2
    page = Math.floor(@pageFromOffsetAndLimit(offset, limit))
    page_number: page, page_size: limit
  @thingPaginator.offsetFromParams = (params) ->
    @offsetFromPageAndLimit(+params.page_number, @limitFromParams(params))
  @thingPaginator.limitFromParams = (params) ->
    params.page_size

  @thingPaginator.loadItemsForOffsetAndLimit(100, 15)
  deepEqual @Thing.load.lastCallArguments?[0],
    page_number: 4
    page_size: 30

  callback = @Thing.load.lastCallArguments?[1]
  callback.call(null, null, (things = [new @Thing(id:1), new @Thing(id:2)]))
  equal @thingPaginator.cache.offset, 90
  equal @thingPaginator.cache.limit, 30
  equal @thingPaginator.cache.items, things
  





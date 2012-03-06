{generateSorterOnProperty} = if typeof require isnt 'undefined' then require '../model/model_helper' else window

QUnit.module 'Polymorphic object access',
  setup: ->
    @pojo =
      foo: 'fooVal'
      bar: 'barVal'
    @hash = new Batman.Hash
    @hash.set('foo', 'fooVal')
    @hash.set('bar', 'barVal')

    @array = ['foo', 'bar']
    @set = new Batman.Set('foo', 'bar')
    @setSort = @set.sortedBy(0)
    @spy = createSpy()
    @emptyContext = {}

###
# Batman.forEach
###
test "Batman.forEach iterates over a Plain-Old JavaScript Object", ->
  Batman.forEach @pojo, @spy, @emptyContext
  equal @spy.callCount, 2
  deepEqual @spy.calls[0].arguments, ['foo', 'fooVal', @pojo]
  deepEqual @spy.calls[1].arguments, ['bar', 'barVal', @pojo]
  strictEqual @spy.calls[0].context, @emptyContext
  strictEqual @spy.calls[1].context, @emptyContext

test "Batman.forEach iterates over a Batman.Hash", ->
  Batman.forEach @hash, @spy, @emptyContext
  equal @spy.callCount, 2
  deepEqual @spy.calls[0].arguments, ['foo', 'fooVal', @hash]
  deepEqual @spy.calls[1].arguments, ['bar', 'barVal', @hash]
  strictEqual @spy.calls[0].context, @emptyContext
  strictEqual @spy.calls[1].context, @emptyContext

test "Batman.forEach iterates over an Array", ->
  Batman.forEach @array, @spy, @emptyContext
  equal @spy.callCount, 2
  deepEqual @spy.calls[0].arguments, ['foo', 0, @array]
  deepEqual @spy.calls[1].arguments, ['bar', 1, @array]
  strictEqual @spy.calls[0].context, @emptyContext
  strictEqual @spy.calls[1].context, @emptyContext

test "Batman.forEach iterates over a Batman.Set", ->
  Batman.forEach @set, @spy, @emptyContext
  equal @spy.callCount, 2
  sorter = generateSorterOnProperty((x) -> x.arguments[0])
  deepEqual sorter(@spy.calls)[0].arguments, ['bar', null, @set]
  deepEqual sorter(@spy.calls)[1].arguments, ['foo', null, @set]
  strictEqual @spy.calls[0].context, @emptyContext
  strictEqual @spy.calls[1].context, @emptyContext

test "Batman.forEach iterates over a Batman.SetSort", ->
  Batman.forEach @setSort, @spy, @emptyContext
  equal @spy.callCount, 2
  deepEqual @spy.calls[0].arguments, ['bar', 0, @setSort]
  deepEqual @spy.calls[1].arguments, ['foo', 1, @setSort]
  strictEqual @spy.calls[0].context, @emptyContext
  strictEqual @spy.calls[1].context, @emptyContext

###
# Batman.objectHasKey
###
test "Batman.objectHasKey works on a Plain-Old JavaScript Object", ->
  strictEqual Batman.objectHasKey(@pojo, 'foo'), true
  strictEqual Batman.objectHasKey(@pojo, 'bar'), true
  strictEqual Batman.objectHasKey(@pojo, 'baz'), false

test "Batman.objectHasKey works on a Batman.Hash", ->
  strictEqual Batman.objectHasKey(@hash, 'foo'), true
  strictEqual Batman.objectHasKey(@hash, 'bar'), true
  strictEqual Batman.objectHasKey(@hash, 'baz'), false

###
# Batman.contains
###
test "Batman.contains queries item membership of an Array", ->
  strictEqual Batman.contains(@array, 'foo'), true
  strictEqual Batman.contains(@array, 'bar'), true
  strictEqual Batman.contains(@array, 'baz'), false

test "Batman.contains queries item membership of a Batman.Set", ->
  strictEqual Batman.contains(@set, 'foo'), true
  strictEqual Batman.contains(@set, 'bar'), true
  strictEqual Batman.contains(@set, 'baz'), false

test "Batman.contains delegates to Batman.objectHasKey for Plain-Old JavaScript Objects", ->
  strictEqual Batman.contains(@pojo, 'foo'), true
  strictEqual Batman.contains(@pojo, 'bar'), true
  strictEqual Batman.contains(@pojo, 'baz'), false

test "Batman.contains delegates to Batman.objectHasKey for Batman.Hashes", ->
  strictEqual Batman.contains(@hash, 'foo'), true
  strictEqual Batman.contains(@hash, 'bar'), true
  strictEqual Batman.contains(@hash, 'baz'), false



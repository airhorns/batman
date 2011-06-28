QUnit.module 'Batman.Set',
  setup: ->
    @set = new Batman.Set

test "has(item) on an empty set returns false", ->
  equal @set.has('foo'), false

test "add(item) adds the item to the set, such that has(item) returns true", ->
  equal @set.add('foo'), 'foo'
  equal @set.has('foo'), true

test "remove(item) removes an item from the set, returning the item and not touching any others", ->
  @set.add('foo')
  @set.add(o1 = {})
  @set.add(o2 = {})
  @set.add(o3 = {})
  equal @set.remove(o2), o2
  equal @set.has('foo'), true
  equal @set.has(o1), true
  equal @set.has(o2), false
  equal @set.has(o3), true

test "remove(item) returns undefined if the item wasn't there", ->
  equal typeof @set.remove('foo'), 'undefined'


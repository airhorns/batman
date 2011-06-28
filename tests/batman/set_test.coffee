QUnit.module 'Batman.Set',
  setup: ->
    @set = new Batman.Set

test "has(item) on an empty set returns false", ->
  equal @set.has('foo'), false

test "add(items...) adds the items to the set, such that has(item) returns true for each item, and increments the set's length accordingly", ->
  deepEqual @set.add('foo', 'bar'), ['foo', 'bar']
  equal @set.length, 2
  equal @set.has('foo'), true
  equal @set.has('bar'), true

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

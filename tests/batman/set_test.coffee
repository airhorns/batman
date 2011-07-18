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

test "add(items...) only increments length for items that aren't already there", ->
  @set.add('foo')
  @set.add('foo', 'bar')
  @set.add('baz', 'baz')
  
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
  equal merged.get('length'), 5

  ok !@set.has('qux')
  ok !@set.has('buzz')

QUnit.module 'Batman.SetSort',
  setup: ->
    @zeke = Batman name: 'Zeke'
    @mary = Batman name: 'Mary'
    @fred = Batman name: 'Fred'
    @jill = Batman name: 'Jill'
    
    @byZeke = Batman author: @zeke
    @byMary = Batman author: @mary
    @byFred = Batman author: @fred
    @anotherByFred = Batman author: @fred
    
    @base = new Batman.Set(@byMary, @byFred, @byZeke, @anotherByFred)
    @authorNameSort = new Batman.SetSort(@base, 'author.name')
    
    # not yet in the set:
    @byJill = Batman author: @jill
    @anotherByZeke = Batman author: @zeke

test "new Batman.SetSort(set, sortKey) constructs a sort on the set for that keypath", ->
  equal @authorNameSort.base, @base
  equal @authorNameSort.sortKey, 'author.name'

test "items with undefined values for the sorted key come first, then null values, then NaN values", ->
  noAuthorName = Batman()
  anotherNoAuthorName = Batman()
  nullAuthorName = Batman
    author: Batman
      name: null
  naNAuthorName = Batman
    author: Batman
      name: NaN
  @base.add naNAuthorName
  @base.add noAuthorName
  @base.add nullAuthorName
  @base.add anotherNoAuthorName
  
  expected = [noAuthorName, anotherNoAuthorName, nullAuthorName, naNAuthorName, @byFred, @anotherByFred, @byMary, @byZeke]
  deepEqual @authorNameSort.toArray(), expected
  
test "forEach(iterator) loops in the correct order", ->
  expect 4
  expected = [@byFred, @anotherByFred, @byMary, @byZeke]
  @authorNameSort.forEach (item, i) ->
    ok item is expected[i]
  
test "toArray() returns the correct order", ->
  expected = [@byFred, @anotherByFred, @byMary, @byZeke]
  deepEqual @authorNameSort.toArray(), expected


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
  
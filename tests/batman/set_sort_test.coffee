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

test "new Batman.SetSort(set, key) constructs a sort on the set for that keypath", ->
  equal @authorNameSort.base, @base
  equal @authorNameSort.key, 'author.name'

test "items with null or undefined values for the sorted key come last and in that order. values of different types are grouped. NaN comes immediately after other numbers.", ->
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
  
  expected = [falseName, trueName, numberedName, anotherNumberedName, naNName, @byFred, @anotherByFred, @byMary, @byZeke, nullName, noName, anotherNoName]
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
  
QUnit.module 'Batman.SetIndex',
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
    @authorNameIndex = new Batman.SetIndex(@base, 'author.name')
    
    # not yet in the set:
    @byJill = Batman author: @jill
    @anotherByZeke = Batman author: @zeke

test "new Batman.SetIndex(set, key) constructs an index on the set for that keypath", ->
  equal @authorNameIndex.base, @base
  equal @authorNameIndex.key, 'author.name'

test "get(value) returns a Batman.Set of items indexed on that value for the index's key", ->
  allByFred = @authorNameIndex.get("Fred")
  
  equal allByFred.length, 2
  ok allByFred.has(@byFred)
  ok allByFred.has(@anotherByFred)

test "the result set from get(value) should be updated to remove items which are removed from the underlying set", ->
  allByFred = @authorNameIndex.get("Fred")
  allByFred.observe 'itemsWereRemoved', observer = createSpy()
  @base.remove(@anotherByFred)
  
  equal observer.lastCallArguments.length, 1
  ok observer.lastCallArguments[0] is @anotherByFred
  equal allByFred.has(@anotherByFred), false

test "the result set from get(value) should be updated to add matching items when they are added to the underlying set", ->
  allByZeke = @authorNameIndex.get("Zeke")
  allByZeke.observe 'itemsWereAdded', observer = createSpy()
  @base.add @anotherByZeke
  
  equal observer.lastCallArguments.length, 1
  ok observer.lastCallArguments[0] is @anotherByZeke
  equal allByZeke.has(@anotherByZeke), true

test "the result set from get(value) should not be updated to add items which don't match the value", ->
  allByFred = @authorNameIndex.get("Fred")
  allByFred.observe 'itemsWereAdded', observer = createSpy()
  @base.add @anotherByZeke
  
  equal observer.called, false
  equal allByFred.has(@anotherByZeke), false

test "adding items with as-yet-unused index keys should add them to the appropriate result sets", ->
  @base.add @byJill
  allByJill = @authorNameIndex.get("Jill")
  
  equal allByJill.length, 1
  ok allByJill.has(@byJill)

test "setting a new value of the indexed property on one of the items triggers an update", ->
  allByFred = @authorNameIndex.get("Fred")
  allByMary = @authorNameIndex.get("Mary")
  
  @byFred.set('author', @mary)
  
  equal allByFred.has(@byFred), false
  equal allByMary.has(@byFred), true

test "setting a new value of the indexed property on an item which has been removed should not trigger an update", ->
  allByMary = @authorNameIndex.get("Mary")
  
  @base.remove(@byFred)
  @byFred.set('author', @mary)
  
  equal allByMary.has(@byFred), false

test "items with undefined values for the indexed key are grouped together as with any other value, and don't collide with null values", ->
  noAuthor = Batman()
  anotherNoAuthor = Batman()
  nullAuthor = Batman
    author: Batman
      name: null
  @base.add noAuthor
  @base.add anotherNoAuthor
  allByNobody = @authorNameIndex.get(undefined)
  equal allByNobody.length, 2
  equal allByNobody.has(noAuthor), true
  equal allByNobody.has(anotherNoAuthor), true
  equal allByNobody.has(Batman()), false

test "stopObserving() forgets all observers", ->
  @authorNameIndex.stopObserving()
  
  @base.add @byJill
  equal @authorNameIndex.get("Jill").length, 0
  
  @base.remove @byZeke
  equal @authorNameIndex.get("Zeke").length, 1
  
  @byFred.set('author', @mary)
  equal @authorNameIndex.get("Fred").has(@byFred), true
  equal @authorNameIndex.get("Mary").has(@byFred), false
  
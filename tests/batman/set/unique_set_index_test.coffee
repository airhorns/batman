QUnit.module 'Batman.UniqueSetIndex',
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
    @authorNameIndex = new Batman.UniqueSetIndex(@base, 'author.name')

    # not yet in the set:
    @byJill = Batman author: @jill
    @anotherByZeke = Batman author: @zeke

test "new Batman.SetIndex(set, key) constructs an index on the set for that keypath", ->
  equal @authorNameIndex.base, @base
  equal @authorNameIndex.key, 'author.name'

test "get(value) returns undefined when there are no matching items", ->
  equal @authorNameIndex.get("Zenu"), undefined

test "get(value) returns the first item matching the given value for the index's key", ->
  equal @authorNameIndex.get("Fred"), @byFred

test "get(value) continues to return the same item if other matching items are added or removed", ->
  @base.add(Batman name: 'Fred')
  equal @authorNameIndex.get("Fred"), @byFred
  @base.remove(@anotherByFred)
  equal @authorNameIndex.get("Fred"), @byFred

test "get(value) returns another matching item when the first is removed", ->
  @base.remove(@byFred)
  equal @authorNameIndex.get("Fred"), @anotherByFred

test "get(value) returns another matching item when the first no longer matches", ->
  @byFred.set('author', @jill)
  equal @authorNameIndex.get("Fred"), @anotherByFred

test "get(value) returns a newly added matching item", ->
  @base.add(@byJill)
  equal @authorNameIndex.get("Jill"), @byJill

test "get(value) returns a newly matching item", ->
  @byFred.set('author', @jill)
  equal @authorNameIndex.get("Jill"), @byFred

test "get(value) returns undefined if a matching item is removed and there are no others to take its place", ->
  @base.remove(@byMary)
  equal @authorNameIndex.get("Mary"), undefined

test "get(value) returns undefined if a previously matching item no longer matches and there are no others to take its place", ->
  @byMary.set('author', @jill)
  equal @authorNameIndex.get("Mary"), undefined

test "setting a new value of the indexed property on an item which has been removed should not trigger an update", ->
  @base.remove(@byFred)
  @byFred.set('author', @jill)

  equal @authorNameIndex.get("Jill"), undefined

test "stopObserving() forgets all observers", ->
  @authorNameIndex.stopObserving()

  @base.add @byJill
  equal @authorNameIndex.get("Jill"), undefined

  @base.remove @byZeke
  equal @authorNameIndex.get("Zeke"), @byZeke

  @byFred.set('author', @mary)
  equal @authorNameIndex.get("Fred"), @byFred
  equal @authorNameIndex.get("Mary"), @byMary


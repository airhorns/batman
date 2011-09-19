QUnit.module 'Batman.SortableSet',
  setup: ->
    @set = new Batman.SortableSet
    @zekes = Batman
      id: 1
      updated_at: new Date("2008-01-10T11:00:00-05:00")
      owner: Batman
        name: 'Zeke'
    @marys = Batman
      id: 2
      updated_at: new Date("2008-01-10T11:00:00-05:00")
      owner: Batman
        name: 'Mary'
    @freds = Batman
      id: 3
      updated_at: new Date("2009-01-10T11:00:00-05:00")
      owner: Batman
        name: 'Fred'
    @set.add @marys
    @set.add @freds
    @set.add @zekes

test "sortBy(keypath) adds an index to be maintained and makes it the default sort order", ->
  @set.sortBy 'owner.name'

  ary = @set.toArray()
  equal ary.length, 3
  ok ary[0] is @freds
  ok ary[1] is @marys
  ok ary[2] is @zekes

  @set.sortBy 'id'

  ary = @set.toArray()
  equal ary.length, 3
  ok ary[0] is @zekes
  ok ary[1] is @marys
  ok ary[2] is @freds

test "sortBy('keypath DESC') adds an index in descending order", ->
  @set.sortBy 'owner.name ASC'

  ary = @set.toArray()
  equal ary.length, 3
  ok ary[0] is @freds
  ok ary[1] is @marys
  ok ary[2] is @zekes

  @set.sortBy 'owner.name DESC'

  ary = @set.toArray()
  equal ary.length, 3
  ok ary[0] is @zekes
  ok ary[1] is @marys
  ok ary[2] is @freds

test "sortBy(keypath) can sort by a date", ->
  @set.sortBy 'updated_at'

  ary = @set.toArray()
  equal ary.length, 3
  ok ary[0] is @marys
  ok ary[1] is @zekes
  ok ary[2] is @freds

test "add(item) updates the indexes", ->
  @set.sortBy 'owner.name'
  james = Batman
    id: 4
    updated_at: new Date("2011-01-10T11:00:00-05:00")
    owner:
      name: 'James'

  @set.add james

  ary = @set.toArray()
  equal ary.length, 4
  ok ary[0] is @freds
  ok ary[1] is james
  ok ary[2] is @marys
  ok ary[3] is @zekes

test "remove(item) updates the indexes", ->
  @set.sortBy 'owner.name'
  @set.remove @marys

  ary = @set.toArray()
  equal ary.length, 2
  ok ary[0] is @freds
  ok ary[1] is @zekes

test "clear() updates the indexes", ->
  @set.sortBy 'owner.name'
  @set.clear()
  ary = @set.toArray()
  equal ary.length, 0

test "undefined values have undefined sort order, but don't explode anything", ->
  noOwner = Batman
    id: 3
    updated_at: new Date("2009-01-10T11:00:00-05:00")
  @set.add noOwner

  @set.sortBy 'owner.name'

  ary = @set.toArray()
  equal ary.length, 4
  ok ary[0] is @freds
  ok ary[1] is @marys
  ok ary[2] is @zekes
  ok ary[3] is noOwner

test "isSorted() returns true if and only if the set has a valid active index", ->
  equal @set.isSorted(), false
  @set.sortBy 'owner.name'
  equal @set.isSorted(), true


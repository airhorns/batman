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

test "addIndex(keypath) adds an index to be maintained and makes it the default sort order", ->
  @set.addIndex 'owner.name'
  
  ary = @set.toArray()
  equal ary.length, 3
  equal ary[0], @freds
  equal ary[1], @marys
  equal ary[2], @zekes
  
  @set.addIndex 'id'
  
  ary = @set.toArray()
  equal ary.length, 3
  equal ary[0], @zekes
  equal ary[1], @marys
  equal ary[2], @freds

test "addIndex('keypath DESC') adds an index in descending order", ->
  @set.addIndex 'owner.name ASC'
  
  ary = @set.toArray()
  equal ary.length, 3
  equal ary[0], @freds
  equal ary[1], @marys
  equal ary[2], @zekes
  
  @set.addIndex 'owner.name DESC'
  
  ary = @set.toArray()
  equal ary.length, 3
  equal ary[0], @zekes
  equal ary[1], @marys
  equal ary[2], @freds
  
test "addIndex(keypath) sorts by date", ->
  @set.addIndex 'updated_at'
  
  ary = @set.toArray()
  equal ary.length, 3
  equal ary[0], @marys
  equal ary[1], @zekes
  equal ary[2], @freds

test "add(item) updates the indexes", ->
  @set.addIndex 'owner.name'
  james = Batman
    id: 4
    updated_at: new Date("2011-01-10T11:00:00-05:00")
    owner:
      name: 'James'
  
  @set.add james
  
  ary = @set.toArray()
  equal ary.length, 4
  equal ary[0], @freds
  equal ary[1], james
  equal ary[2], @marys
  equal ary[3], @zekes

test "remove(item) updates the indexes", ->
  @set.addIndex 'owner.name'
  @set.remove @marys
  
  ary = @set.toArray()
  equal ary.length, 2
  equal ary[0], @freds
  equal ary[1], @zekes

test "undefined values have undefined sort order, but don't explode anything", ->
  noOwner = Batman
    id: 3
    updated_at: new Date("2009-01-10T11:00:00-05:00")
  @set.add noOwner
  
  @set.addIndex 'owner.name'
  
  ary = @set.toArray()
  equal ary.length, 4
  equal ary[0], @freds
  equal ary[1], @marys
  equal ary[2], @zekes
  equal ary[3], noOwner
  
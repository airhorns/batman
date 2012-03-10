QUnit.module "Batman.SetUnion"
  setup: ->
    @left = new Batman.Set("a", "b", "c")
    @right = new Batman.Set("c", "d", "e")
    @union = new Batman.SetUnion(@left, @right)

membersEqual = (set, members) ->
  deepEqual set.toArray().sort(), members.sort()
  equal set.get('length'), members.length
  equal set.length, members.length

test "unions should contain items from both sets", ->
  membersEqual @union, ["a", "b", "c", "d", "e"]

test "unions should be empty if both sets are empty", ->
  @left.clear()
  @right.clear()
  membersEqual @union, []

test "unions should observe additions to either set and add the added item to themselves", ->
  @left.add "d"
  membersEqual @union, ["a", "b", "c", "d", "e"]

  @left.add "f"
  membersEqual @union, ["a", "b", "c", "d", "e", "f"]

  @right.add "a"
  membersEqual @union, ["a", "b", "c", "d", "e", "f"]

  @right.add "g"
  membersEqual @union, ["a", "b", "c", "d", "e", "f", "g"]

test "unions should observe removals to either set and remove the item from themselves", ->
  @left.remove "a"
  membersEqual @union, ["b", "c", "d", "e"]

  @right.remove "c"
  membersEqual @union, ["b", "c", "d", "e"]

  @left.remove "c"
  membersEqual @union, ["b", "d", "e"]

  @right.remove "d"
  membersEqual @union, ["b", "e"]

test "unions should emit addition and removal events", ->
  @union.on 'itemsWereAdded', addedSpy = createSpy()
  @union.on 'itemsWereRemoved', removedSpy = createSpy()

  @right.add "f"
  deepEqual addedSpy.lastCallArguments, ['f']

  @left.remove "a"
  deepEqual removedSpy.lastCallArguments, ['a']

test "merging a union should return a set which no longer updates", ->
  @merged = @union.merge new Batman.Set("e", "f", "g")
  membersEqual @merged, ["a", "b", "c", "d", "e", "f", "g"]
  @left.add "h"
  membersEqual @merged, ["a", "b", "c", "d", "e", "f", "g"]

test "unions should be chainable", ->
  @middle = new Batman.Set "d", "f"

  subUnion = new Batman.SetUnion(@middle, @union)
  membersEqual subUnion, ["a", "b", "c", "d", "e", "f"]

  @right.add "g"
  membersEqual subUnion, ["a", "b", "c", "d", "e", "f", "g"]

  @left.add "h"
  membersEqual subUnion, ["a", "b", "c", "d", "e", "f", "g", "h"]

  @middle.add "i"
  membersEqual subUnion, ["a", "b", "c", "d", "e", "f", "g", "h", "i"]

  @right.remove "e"
  membersEqual subUnion, ["a", "b", "c", "d", "f", "g", "h", "i"]

  @left.remove "a"
  membersEqual subUnion, ["b", "c", "d", "f", "g", "h", "i"]

  @middle.remove "f"
  membersEqual subUnion, ["b", "c", "d", "g", "h", "i"]

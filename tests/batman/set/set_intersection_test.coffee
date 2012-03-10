QUnit.module "Batman.SetIntersection"
  setup: ->
    @left = new Batman.Set("a", "b", "c")
    @right = new Batman.Set("c", "d", "e")
    @intersection = new Batman.SetIntersection(@left, @right)

membersEqual = (set, members) ->
  deepEqual set.toArray().sort(), members.sort()
  equal set.get('length'), members.length
  equal set.length, members.length

test "intersections should be empty if either set is empty", ->
  @left.clear() # one empty
  membersEqual @intersection, []

  @right.clear() # both empty
  membersEqual @intersection, []

  @left.add("a", "b") # other empty
  membersEqual @intersection, []

test "intersections should contain items present only in both sets", ->
  membersEqual @intersection, ["c"]

test "intersections should observe additions to either set and add the added item to themselves if present in the other set", ->
  @left.add "f"
  membersEqual @intersection, ["c"]

  @left.add "d"
  membersEqual @intersection, ["c", "d"]

  @right.add "g"
  membersEqual @intersection, ["c", "d"]

  @right.add "b"
  membersEqual @intersection, ["c", "d", "b"]

test "intersections should observe removals to either set and remove the removed item from themselves", ->
  @left.remove "a"
  membersEqual @intersection, ["c"]

  @left.remove "c"
  membersEqual @intersection, []

  @left.add "c"
  membersEqual @intersection, ["c"]

  @right.remove "c"
  membersEqual @intersection, []

test "intersections should emit addition and removal events", ->
  @intersection.on 'itemsWereAdded', addedSpy = createSpy()
  @intersection.on 'itemsWereRemoved', removedSpy = createSpy()

  @left.add "d"
  deepEqual addedSpy.lastCallArguments, ['d']

  @right.remove "d"
  deepEqual removedSpy.lastCallArguments, ['d']

test "intersections should be chainable", ->
  @middle = new Batman.Set "b", "c"

  subIntersection = new Batman.SetIntersection(@middle, @intersection)
  membersEqual subIntersection, ["c"]

  @right.add "b"
  membersEqual subIntersection, ["b", "c"]

  @left.remove "c"
  membersEqual subIntersection, ["b"]

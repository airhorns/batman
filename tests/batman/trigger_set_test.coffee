QUnit.module 'Batman.TriggerSet',
  setup: ->
    observable = (obj) -> Batman.mixin(obj, Batman.Observable)
    @obj = observable
      foo: observable
        bar: observable
          baz: observable
            qux: 'quxVal'
    @keypath = new Batman.Keypath(@obj, 'foo.bar.baz.qux')
    @set = new Batman.TriggerSet()


###
# constructor
###
test "initializes with an empty array of triggers", ->
  deepEqual @set.triggers, []


###
# add
###
test "add(keypath, depth) when an equivalent trigger isn't there yet results in a trigger with those properties being added", ->
  @set.add(@keypath, 2)
  @set.add(@keypath, 3)
  equal @set.triggers.length, 2
  deepEqual @set.triggers[0], {keypath: @keypath, depth: 2, observerCount: 1}
  deepEqual @set.triggers[1], {keypath: @keypath, depth: 3, observerCount: 1}
  
test "add(keypath, depth) when an equivalent trigger is already there results in the already-present trigger's observerCount being incremented", ->
  @set.add(@keypath, 2)
  @set.add(@keypath, 2)
  deepEqual @set.triggers, [{keypath: @keypath, depth: 2, observerCount: 2}]


###
# remove
###
test "remove(keypath, depth) on an empty TriggerSet returns undefined", ->
  equal typeof(@set.remove(@keypath, 2)), 'undefined'
  deepEqual @set.triggers, []
  
  
test "remove(keypath, depth) when a matching trigger is there with an observerCount of 1 splices the trigger out and returns it", ->
  @set.add(@keypath, 1)
  @set.add(@keypath, 2)
  @set.add(@keypath, 3)
  @set.remove(@keypath, 2)
  equal @set.triggers.length, 2
  deepEqual @set.triggers[0], {keypath: @keypath, depth: 1, observerCount: 1}
  deepEqual @set.triggers[1], {keypath: @keypath, depth: 3, observerCount: 1}
  equal typeof(@set.triggers[2]), 'undefined'
  
  
test "remove(keypath, depth) when a matching trigger is there with an observerCount of more than 1 simply decrements that count", ->
  @set.add(@keypath, 1)
  @set.add(@keypath, 2)
  @set.add(@keypath, 2)
  @set.add(@keypath, 2)
  @set.add(@keypath, 3)
  @set.remove(@keypath, 2)
  equal @set.triggers.length, 3
  deepEqual @set.triggers[0], {keypath: @keypath, depth: 1, observerCount: 1}
  deepEqual @set.triggers[1], {keypath: @keypath, depth: 2, observerCount: 2}
  deepEqual @set.triggers[2], {keypath: @keypath, depth: 3, observerCount: 1}


###
# _indexOfTrigger(keypath, depth)
###
test "_indexOfTrigger(keypath, depth) returns the index of a trigger if it is already in the set with an equal keypath and depth", ->
  @set.add(@keypath, 1)
  @set.add(@keypath, 2)
  equal @set._indexOfTrigger(new Batman.Keypath(@obj, 'foo.bar.baz.qux'), 2), 1
  
test "_indexOfTrigger(keypath, depth) returns -1 if there is no trigger with the same keypath and depth", ->
  @set.add(@keypath, 1)
  @set.add(@keypath, 2)
  equal @set._indexOfTrigger(new Batman.Keypath(@obj, 'foo.bar.baz.qux'), 3), -1
  equal @set._indexOfTrigger(new Batman.Keypath(@obj, 'foo.bar.baz'), 2), -1


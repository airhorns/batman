QUnit.module 'Batman.TriggerSet',
  setup: ->
    observable = (obj) -> Batman.mixin(obj, Batman.Observable)
    @obj = observable
      foo: observable
        bar: observable
          baz: observable
            qux: 'quxVal'
    @keypath = new Batman.Keypath(@obj, 'foo.bar.baz.qux')
    @set = new Batman.TriggerSet(@obj.foo, 'bar')
    @callback = createSpy()
    @trigger = new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback)


###
# constructor
###
test "initializes with an empty array of triggers and keypaths", ->
  deepEqual @set.triggers, []
  deepEqual @set.keypaths, []


###
# add(trigger)
###
test "add(trigger) adds a trigger to the set and the trigger's keypath to the set's keypaths", ->
  @set.add(@trigger)
  equal @set.triggers.length, 1
  ok @set.triggers[0] is @trigger
  equal @set.keypaths.length, 1
  ok @set.keypaths[0] is @keypath
  
test "add(trigger) does not add duplicate triggers", ->
  @set.add(trigger1 = new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback))
  @set.add(trigger2 = new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback))
  equal @set.triggers.length, 1
  ok @set.triggers[0] is trigger1
  equal @set.keypaths.length, 1
  ok @set.keypaths[0] is @keypath
  
test "add(trigger) does not add duplicate keypaths", ->
  @set.add(trigger1 = new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback))
  @set.add(trigger2 = new Batman.Trigger(@obj.foo, 'bar', new Batman.Keypath(@obj, 'foo.bar.baz.qux'), ->))
  equal @set.triggers.length, 2
  ok @set.triggers[0] is trigger1
  ok @set.triggers[1] is trigger2
  equal @set.keypaths.length, 1
  ok @set.keypaths[0] is @keypath
  


###
# remove(trigger)
###
test "remove(trigger) returns undefined and does not remove matching keypaths if there is no matching trigger in the set", ->
  @set.add(@trigger)
  result = @set.remove(new Batman.Trigger(@obj.foo.bar, 'baz', @keypath, @callback))
  equal typeof(result), 'undefined'
  equal @set.triggers.length, 1
  ok @set.triggers[0] is @trigger
  equal @set.keypaths.length, 1
  ok @set.keypaths[0] is @keypath
  
  
test "remove(trigger) removes a matching trigger and its associated keypath if it's the only trigger in the set with an equivalent keypath", ->
  @set.add(@trigger)
  result = @set.remove(new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback))
  ok result is @trigger
  equal @set.triggers.length, 0
  equal @set.keypaths.length, 0
  
test "remove(trigger) removes a matching trigger but leaves the associated keypath alone if there's another trigger with an equivalent keypath", ->
  @set.add(trigger1 = new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback))
  @set.add(trigger2 = new Batman.Trigger(@obj.foo, 'bar', new Batman.Keypath(@obj, 'foo.bar.baz.qux'), ->))
  
  result = @set.remove(trigger1)
  ok result is trigger1
  
  equal @set.triggers.length, 1
  ok @set.triggers[0] is trigger2
  equal @set.keypaths.length, 1
  ok @set.keypaths[0] is @keypath
  

###
# rememberOldValues()
###
test "rememberOldValues() populates the an oldValues array with the current values referenced by each keypath, in the same order as the keypaths array", ->
  @set.add(new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback))
  @set.add(new Batman.Trigger(@obj.foo, 'bar', new Batman.Keypath(@obj.foo, 'bar.baz'), @callback))
  
  @set.rememberOldValues()
  
  equal @set.oldValues.length, 2
  equal @set.oldValues[0], 'quxVal'
  equal @set.oldValues[1], @obj.foo.bar.baz
  

###
# forgetOldValues()
###
test "forgetOldValues() sets oldValues to a blank array", ->
  @set.oldValues = ['val1', 'val2']
  @set.forgetOldValues()
  deepEqual @set.oldValues, []
  

###
# fireAll()
###
test "fireAll() calls fire() on each keypath's base with keypath.path(), getting the new value from keypath.resolve(), and getting the old value from this.oldValues", ->
  spyOn(@obj, 'fire')
  spyOn(@obj.foo, 'fire')
  @set.add(new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback))
  @set.add(new Batman.Trigger(@obj.foo, 'bar', new Batman.Keypath(@obj.foo, 'bar.baz'), @callback))
  
  @set.oldValues = ['oldVal1', 'oldVal2']
  @set.fireAll()
  
  equal @obj.fire.callCount, 1
  [key, value, oldValue] = @obj.fire.lastCallArguments
  equal key, 'foo.bar.baz.qux'
  equal value, 'quxVal'
  equal oldValue, 'oldVal1'
  
  equal @obj.foo.fire.callCount, 1
  [key, value, oldValue] = @obj.foo.fire.lastCallArguments
  equal key, 'bar.baz'
  equal value, @obj.foo.bar.baz
  equal oldValue, 'oldVal2'
  

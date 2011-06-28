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
test "initializes with an empty set of triggers", ->
  deepEqual @set.triggers, new Batman.Set


###
# add(trigger)
###
test "add(trigger) adds a trigger to the set", ->
  @set.add(@trigger)
  equal @set.triggers.toArray().length, 1
  ok @set.triggers.has(@trigger)
  
test "add(trigger) does not add duplicate triggers", ->
  @set.add(trigger1 = new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback))
  @set.add(trigger2 = new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback))
  equal @set.triggers.toArray().length, 1
  ok @set.triggers.has(@trigger)
  
test "add(trigger) does not add duplicate keypaths", ->
  @set.add(trigger1 = new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback))
  @set.add(trigger2 = new Batman.Trigger(@obj.foo, 'bar', new Batman.Keypath(@obj, 'foo.bar.baz.qux'), ->))
  equal @set.triggers.toArray().length, 2
  ok @set.triggers.has(trigger1)
  ok @set.triggers.has(trigger2)



###
# keypaths()
###
  
test "keypaths() returns a Batman.Set of the triggers' target keypaths", ->
  @set.add(new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback))
  @set.add(new Batman.Trigger(@obj.foo, 'bar', new Batman.Keypath(@obj, 'foo.bar.baz.qux'), ->))
  @set.add(new Batman.Trigger(@obj.foo, 'bar', new Batman.Keypath(@obj, 'foo.bar.baz'), ->))
  keypaths = @set.keypaths()
  equal keypaths.toArray().length, 2
  ok keypaths.has(@keypath)
  ok keypaths.has(new Batman.Keypath(@obj, 'foo.bar.baz'))


###
# remove(trigger)
###
test "remove(triggers...) returns an empty array and does not remove anything if there is no matching trigger in the set", ->
  @set.add(@trigger)
  result = @set.remove(new Batman.Trigger(@obj.foo.bar, 'baz', @keypath, @callback))
  deepEqual result, []
  equal @set.triggers.toArray().length, 1
  ok @set.triggers.has(@trigger)
  
  
test "remove(triggers...) removes a matching trigger", ->
  @set.add(@trigger)
  result = @set.remove(new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback))
  ok result[0] is @trigger
  equal @set.triggers.toArray().length, 0
  

###
# rememberOldValues()
###
test "rememberOldValues() populates the an oldValues hash with the current values referenced by each keypath", ->
  @set.add(new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback))
  @set.add(new Batman.Trigger(@obj.foo, 'bar', new Batman.Keypath(@obj.foo, 'bar.baz'), @callback))
  
  @set.rememberOldValues()
  
  equal @set.oldValues.get(@keypath), 'quxVal'
  equal @set.oldValues.get(new Batman.Keypath(@obj.foo, 'bar.baz')), @obj.foo.bar.baz
  

###
# fireAll()
###
test "fireAll() calls fire() on each keypath's base with keypath.path(), getting the new value from keypath.resolve(), and getting the old value from this.oldValues", ->
  spyOn(@obj, 'fire')
  spyOn(@obj.foo, 'fire')
  @set.add(new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback))
  @set.add(new Batman.Trigger(@obj.foo, 'bar', (kp2 = new Batman.Keypath(@obj.foo, 'bar.baz')), @callback))
  
  @set.oldValues = new Batman.Hash
  @set.oldValues.set @keypath, 'oldVal1'
  @set.oldValues.set kp2, 'oldVal2'
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
  

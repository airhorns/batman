QUnit.module 'Batman.Trigger',
  setup: ->
    observable = (obj) -> Batman.mixin(obj, Batman.Observable)
    @obj = observable
      foo: observable
        bar: observable
          baz: observable
            qux: 'quxVal'
    @keypath = new Batman.Keypath(@obj, 'foo.bar.baz.qux')
    @callback = createSpy()
    @trigger = new Batman.Trigger(@obj.foo, 'bar', @keypath, @callback)
    


###
# constructor
###
test "initialize adds the trigger to the appropriate trigger sets", ->
  outboundTriggers = @obj.foo._batman.outboundTriggers['bar'].triggers
  equal outboundTriggers.length, 1
  ok outboundTriggers[0] is @trigger
  
  inboundTriggers = @obj._batman.inboundTriggers['foo.bar.baz.qux'].triggers
  equal inboundTriggers.length, 1
  ok inboundTriggers[0] is @trigger


###
# isEqual
###
test "isEqual(other) returns true when keypaths are equivalent and other properties are the same objects", ->
  callback = ->
  trigger1 = new Batman.Trigger(@obj.foo, 'bar', new Batman.Keypath(@obj, 'foo.bar.baz.qux'), callback)
  trigger2 = new Batman.Trigger(@obj.foo, 'bar', new Batman.Keypath(@obj, 'foo.bar.baz.qux'), callback)
  ok trigger1.isEqual(trigger2)
  ok trigger2.isEqual(trigger1)

test "isEqual(other) returns false when keypaths are not equivalent or when any other properties are not the same objects", ->
  callback = ->
  trigger1 = new Batman.Trigger(@obj.foo, 'bar', new Batman.Keypath(@obj, 'foo.bar.baz.qux'), callback)
  trigger2 = new Batman.Trigger(@obj.foo, 'bar', new Batman.Keypath(@obj, 'foo.bar.baz.qux'), ->)
  trigger3 = new Batman.Trigger(@obj.foo, 'bar', new Batman.Keypath(@obj, 'foo.bar.baz'), callback)
  trigger4 = new Batman.Trigger(@obj.foo.bar, 'baz', new Batman.Keypath(@obj, 'foo.bar.baz.qux'), callback)
  ok not trigger1.isEqual(trigger2)
  ok not trigger2.isEqual(trigger1)
  ok not trigger1.isEqual(trigger3)
  ok not trigger3.isEqual(trigger1)
  ok not trigger1.isEqual(trigger4)
  ok not trigger4.isEqual(trigger1)


###
# isValid()
###
test "isValid() returns true if the trigger's base and key form a minimal pair within the targetKeypath, false otherwise", ->
  ok @trigger.isValid()
  oldFoo = @obj.foo
  @obj.foo = 'newVal'
  ok not @trigger.isValid()
  @obj.foo = oldFoo
  ok @trigger.isValid()
  
  deeperTrigger = new Batman.Trigger(@obj.foo.bar.baz, 'qux', @keypath, @callback)
  ok deeperTrigger.isValid()
  oldBar = @obj.foo.bar
  @obj.foo.bar = 'newVal'
  ok not deeperTrigger.isValid()
  @obj.foo.bar = oldBar
  ok deeperTrigger.isValid()


###
# remove()
###
test "remove() removes the trigger from the inbound and outbound trigger sets which reference it", ->
  @trigger.remove()

  outboundTriggers = @obj.foo._batman.outboundTriggers['bar'].triggers
  equal outboundTriggers.length, 0
  
  inboundTriggers = @obj._batman.inboundTriggers['foo.bar.baz.qux'].triggers
  equal inboundTriggers.length, 0

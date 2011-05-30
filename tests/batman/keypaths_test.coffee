QUnit.module 'Batman.Keypaths',
  setup: ->
    @obj = Batman
      foo: Batman
        bar: Batman
          baz: Batman
            qux: 'pew pew'

test "Batman.Keypath.eachKeypath", ->
  expect 12
  objects = [@obj, @obj.foo, @obj.foo.bar, @obj.foo.bar.baz]
  strings = ['foo.bar.baz.qux', 'bar.baz.qux', 'baz.qux', 'qux']
  expectedKeyIndex = 0
  @obj.keypath('foo.bar.baz.qux').eachKeypath (keypath, index) ->
    equal keypath.base, objects.shift()
    equal keypath.string, strings.shift()
    equal index, expectedKeyIndex++

# test "Batman.Keypath.eachKey", ->
#   expect 8
#   keys = ['foo', 'bar', 'baz', 'qux']
#   expectedKeyIndex = 0
#   @obj.keypath('foo.bar.baz.qux').eachKey (key, index) ->
#     equal key, keys.shift()
#     equal index, expectedKeyIndex++

test "Batman.Keypath.eachValue", ->
  expect 8
  values = [@obj.foo, @obj.foo.bar, @obj.foo.bar.baz, @obj.foo.bar.baz.qux]
  expectedKeyIndex = 0
  @obj.keypath('foo.bar.baz.qux').eachValue (value, index) ->
    equal value, values.shift()
    equal index, expectedKeyIndex++
    
test 'get and set', ->
  equal @obj.get('foo.bar.baz.qux'), 'pew pew'
  
  @obj.set 'foo.bar.baz.qux', 'blah'
  equal @obj.get('foo.bar').get('baz.qux'), 'blah'


test 'observing', ->
  expect 1
  @obj.observe 'foo.bar', (val) ->
    ok false
  @obj.observe 'foo.bar.baz.qux', (val) ->
    equal val, 'james'
  
  @obj.set 'foo.bar.baz.qux', 'james'


test 'snipping off a branch', ->
  expect 2
  @obj.observe 'foo.bar', (val) ->
    equal val, 'jsconf'
  @obj.observe 'foo.bar.baz.qux', (val) ->
    equal (typeof val), 'undefined'
  
  @obj.set 'foo.bar', 'jsconf'


test 'observing a cached something or other', ->
  cachedBar = @obj.get 'foo.bar'
  @obj.set 'foo.bar', 'jsconf'
  
  expect 2
  @obj.observe 'foo.bar', (val) ->
    equal cachedBar, val
  deepObserver = (val) ->
    equal 'pew pew', val
  @obj.observe 'foo.bar.baz.qux', deepObserver
  
  @obj.set 'foo.bar', cachedBar
  
  @obj.forget('foo.bar.baz.qux', deepObserver)


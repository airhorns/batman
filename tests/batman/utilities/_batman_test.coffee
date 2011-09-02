


QUnit.module "_Batman",
  setup: ->
    class @Animal extends Batman.Object
      Batman.initializeObject @::

    class @Snake extends @Animal
      Batman.initializeObject @::

    class @BlackMamba extends @Snake
      Batman.initializeObject @::

    @mamba = new @BlackMamba()
    @snake = new @Snake()
    true

deepSortedEqual = (a,b,message) ->
  deepEqual(a.sort(), b.sort(), message)

test "correct ancestors are returned", ->
  deepEqual @snake._batman.object, @snake
  expected = [@Snake::, @Animal::, Batman.Object::, Object.prototype]
  window.SnakeClass = @Snake
  @snake._batman.ancestors()

  for k, v of @snake._batman.ancestors()
    equal v, expected[k]

test "primitives are traversed in _batman lookups", ->
  @Animal::_batman.set 'primitive_key', 1
  @Snake::_batman.set 'primitive_key', 2
  @BlackMamba::_batman.set 'primitive_key', 3

  deepSortedEqual @snake._batman.get('primitive_key'), [1,2]
  deepSortedEqual @mamba._batman.get('primitive_key'), [1,2,3]

  @mamba._batman.set 'primitive_key', 4
  @snake._batman.set 'primitive_key', 5
  deepSortedEqual @mamba._batman.get('primitive_key'), [1,2,3,4]
  deepSortedEqual @snake._batman.get('primitive_key'), [1,2,5]

test "array keys are traversed and merged in _batman lookups", ->
  @Animal::_batman.set 'array_key', [1,2,3]
  @Snake::_batman.set 'array_key', [4,5,6]
  @BlackMamba::_batman.set 'array_key', [7,8,9]

  deepSortedEqual @snake._batman.get('array_key'), [1,2,3,4,5,6]
  deepSortedEqual @mamba._batman.get('array_key'), [1,2,3,4,5,6,7,8,9]

  @mamba._batman.set 'array_key', [10,11]
  @snake._batman.set 'array_key', [12,13]
  deepSortedEqual @snake._batman.get('array_key'), [1,2,3,4,5,6,12,13]
  deepSortedEqual @mamba._batman.get('array_key'), [1,2,3,4,5,6,7,8,9,10,11]

test "hash keys are traversed and merged in _batman lookups", ->
  @Animal::_batman.set 'hash_key', new Batman.SimpleHash
  @Animal::_batman.hash_key.set 'foo', 'bar'

  @Snake::_batman.set 'hash_key', new Batman.SimpleHash
  @Snake::_batman.hash_key.set 'baz', 'qux'

  @BlackMamba::_batman.set 'hash_key', new Batman.SimpleHash
  @BlackMamba::_batman.hash_key.set 'wibble', 'wobble'

  for k, v of {wibble: 'wobble', baz: 'qux', foo: 'bar'}
    equal @mamba._batman.get('hash_key').get(k), v

  @mamba._batman.set 'hash_key', new Batman.SimpleHash

  @mamba._batman.hash_key.set 'winnie', 'pooh'
  ok !@mamba._batman.get('hash_key').isEmpty()
  for k, v of {wibble: 'wobble', baz: 'qux', foo: 'bar', winnie:'pooh'}
    equal @mamba._batman.get('hash_key').get(k), v

test "hash keys from closer ancestors replace those from further ancestors", ->
  @Animal::_batman.set 'hash_key', new Batman.SimpleHash
  @Animal::_batman.hash_key.set 'foo', 'bar'

  @Snake::_batman.set 'hash_key', new Batman.SimpleHash
  @Snake::_batman.hash_key.set 'foo', 'baz'

  @BlackMamba::_batman.set 'hash_key', new Batman.SimpleHash
  @BlackMamba::_batman.hash_key.set 'foo', 'qux'

  equal @snake._batman.get('hash_key').get('foo'), 'baz'
  equal @mamba._batman.get('hash_key').get('foo'), 'qux'

  for obj in [@snake, @mamba]
    obj._batman.hash_key = new Batman.SimpleHash
    obj._batman.hash_key.set('foo', 'corge')
    equal obj._batman.get('hash_key').get('foo'), 'corge'

test "set keys are traversed and merged in _batman lookups", ->
  @Animal::_batman.set 'set_key', new Batman.SimpleSet
  @Animal::_batman.set_key.add 'foo', 'bar'

  @Snake::_batman.set 'set_key', new Batman.SimpleSet
  @Snake::_batman.set_key.add 'baz', 'qux'

  @BlackMamba::_batman.set 'set_key', new Batman.SimpleSet
  @BlackMamba::_batman.set_key.add 'wibble', 'wobble'

  for k in ['wibble', 'wobble', 'baz', 'qux', 'foo', 'bar']
    ok @mamba._batman.get('set_key').has(k)
  equal @mamba._batman.get('set_key').length, 6

  @mamba._batman.set 'set_key', new Batman.SimpleSet
  equal @mamba._batman.get('set_key').length, 6

  @mamba._batman.set_key.add 'winnie', 'pooh'
  for k in ['wibble', 'wobble', 'baz', 'qux', 'foo', 'bar', 'winnie', 'pooh']
    ok @mamba._batman.get('set_key').has(k)
  equal @mamba._batman.get('set_key').length, 8

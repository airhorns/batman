QUnit.module "Batman.ParamsReplacer",
  setup: ->
    @navigator =
      replace: createSpy()
      push: createSpy()
    @params = new Batman.Hash
      foo: 'fooVal'
      bar: 'barVal'
    @replacer = new Batman.ParamsReplacer(@navigator, @params)

test "toObject() delegates to the wrapped params hash", ->
  deepEqual @replacer.toObject(), @params.toObject()

test "get(key) delegates to the wrapped params hash", ->
  equal @replacer.get('foo'), 'fooVal'

test "set(key, value) delegates to the wrapped params hash and redirects in-place", ->
  @replacer.set('foo', 'newFoo')
  equal @params.get('foo'), 'newFoo'
  equal @navigator.replace.callCount, 1
  deepEqual @navigator.replace.lastCallArguments, [{foo: 'newFoo', bar: 'barVal'}]

test "unset(key) delegates to the wrapped params hash and redirects in-place", ->
  @replacer.unset('foo')
  equal @params.hasKey('foo'), false
  equal @navigator.replace.callCount, 1
  deepEqual @navigator.replace.lastCallArguments, [{bar: 'barVal'}]

test "replace(params) delegates to the wrapped params hash and redirects in-place", ->
  @replacer.replace foo: 'newFoo', baz: 'bazVal'
  expected = foo: 'newFoo', baz: 'bazVal'
  deepEqual @params.toObject(), expected
  equal @navigator.replace.callCount, 1
  deepEqual @navigator.replace.lastCallArguments, [expected]

test "update(params) delegates to the wrapped params hash and redirects in-place", ->
  @replacer.update foo: 'newFoo', baz: 'bazVal'
  expected = foo: 'newFoo', bar: 'barVal', baz: 'bazVal'
  deepEqual @params.toObject(), expected
  equal @navigator.replace.callCount, 1
  deepEqual @navigator.replace.lastCallArguments, [expected]

test "clear() delegates to the wrapped params hash and redirects in-place", ->
  @replacer.clear()
  deepEqual @params.toObject(), {}
  equal @navigator.replace.callCount, 1
  deepEqual @navigator.replace.lastCallArguments, [{}]

test "ParamsPusher subclass uses @navigator.push to redirect", ->
  @pusher = new Batman.ParamsPusher(@navigator, @params)
  @pusher.set('foo', 'newFoo')
  equal @navigator.push.callCount, 1
  deepEqual @navigator.push.lastCallArguments, [{foo: 'newFoo', bar: 'barVal'}]

  @pusher.unset('foo')
  equal @navigator.push.callCount, 2
  deepEqual @navigator.push.lastCallArguments, [{bar: 'barVal'}]

  @pusher.replace foo: 'newFoo', bar: 'barVal'
  equal @navigator.push.callCount, 3
  deepEqual @navigator.push.lastCallArguments, [{foo: 'newFoo', bar: 'barVal'}]

  @pusher.update foo: 'newerFoo', baz: 'bazVal'
  equal @navigator.push.callCount, 4
  deepEqual @navigator.push.lastCallArguments, [{foo: 'newerFoo', bar: 'barVal', baz: 'bazVal'}]

  @pusher.clear()
  equal @navigator.push.callCount, 5
  deepEqual @navigator.push.lastCallArguments, [{}]

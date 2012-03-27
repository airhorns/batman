Batman.exportHelpers(this)

QUnit.module "Batman.get"

test "should invoke obj.get if it is a function", ->
  obj = get: createSpy()

  Batman.get obj, 'foo'
  ok obj.get.called
  equal obj.get.lastCall.arguments[0], 'foo'

test "should call Batman.Property.forBaseAndKey if obj.get is not a function", ->
  obj = new Batman.Object x: 'x', get: null

  spyOnDuring Batman.Property, 'forBaseAndKey', (spy) ->
    Batman.get obj, 'x'
    deepEqual spy.lastCallArguments, [obj, 'x']


QUnit.module "Batman.getPath",
  setup: ->
    @complexObject = new Batman.Object
      hash: new Batman.Hash
        foo: new Batman.Object(bar: 'nested value'),
        "foo.bar": 'flat value'


test "takes a base and an array of keys and returns the corresponding nested value", ->
  equal Batman.getPath(@complexObject, ['hash', 'foo', 'bar']), 'nested value'
  equal Batman.getPath(@complexObject, ['hash', 'foo.bar']), 'flat value'
  strictEqual Batman.getPath(@complexObject, ['hash', 'not-foo', 'bar']), undefined

test "returns just the base if the key array is empty", ->
  strictEqual Batman.getPath(@complexObject, []), @complexObject
  strictEqual Batman.getPath(null, []), null

test "returns undefined if the base is null-ish", ->
  strictEqual Batman.getPath(null, ['foo']), undefined
  strictEqual Batman.getPath(undefined, ['foo']), undefined

test "returns falsy values", ->
  strictEqual Batman.getPath(num: 0, ['num']), 0


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

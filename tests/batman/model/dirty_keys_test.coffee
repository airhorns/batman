{TestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

QUnit.module "Batman.Model dirty key tracking",
  setup: ->
    Batman.developer.suppress()
    class @Product extends Batman.Model
      @persist TestStorageAdapter
  teardown: ->
    Batman.developer.unsuppress()

test "no keys are dirty upon creation", ->
  product = new @Product
  equal product.get('dirtyKeys').length, 0

test "old values are tracked in the dirty keys hash", ->
  product = new @Product
  product.set 'foo', 'bar'
  product.set 'foo', 'baz'
  equal(product.get('dirtyKeys.foo'), 'bar')

test "creating instances by passing attributes sets those attributes as dirty", ->
  product = new @Product foo: 'bar'
  equal(product.get('dirtyKeys').length, 1)
  equal(product.lifecycle.get('state'), 'dirty')

asyncTest "saving clears dirty keys", ->
  product = new @Product foo: 'bar', id: 1
  product.save (err) ->
    throw err if err
    equal(product.dirtyKeys.length, 0)
    notEqual(product.lifecycle.get('state'), 'dirty')
    QUnit.start()


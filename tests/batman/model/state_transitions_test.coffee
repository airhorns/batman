{TestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

QUnit.module "Batman.Model state transitions",
  setup: ->
    class @Product extends Batman.Model
      @persist TestStorageAdapter

test "new instances start 'empty'", ->
  product = new @Product
  ok product.isNew()
  equal product.state(), 'empty'

asyncTest "loaded instances start 'loaded'", 2, ->
  product = new @Product(10)
  product.load (err, product) ->
    throw err if err
    ok !product.isNew()
    equal product.state(), 'loaded'
    QUnit.start()

asyncTest "instances has state transitions for observation", 1, ->
  product = new @Product
  product.transition 'loading', 'loaded', spy = createSpy()
  product.loading()
  product.loaded()

  delay ->
    ok spy.called

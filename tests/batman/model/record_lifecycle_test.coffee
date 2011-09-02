{TestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

QUnit.module "Batman.Model record lifecycle",
  setup: ->
    class @Product extends Batman.Model
      @persist TestStorageAdapter

asyncTest "new record lifecycle callbacks fire in order", ->
  callOrder = []

  product = new @Product()
  product.dirty -> callOrder.push(0)
  product.validating -> callOrder.push(1)
  product.validated -> callOrder.push(2)
  product.saving -> callOrder.push(3)
  product.creating -> callOrder.push(4)
  product.created -> callOrder.push(5)
  product.saved -> callOrder.push(6)
  product.destroying -> callOrder.push(8)
  product.destroyed -> callOrder.push(9)
  product.set('foo', 'bar')
  product.save (err) ->
    throw err if err
    callOrder.push(7)
    product.destroy (err) ->
      throw err if err
      deepEqual(callOrder, [0,1,2,0,3,4,5,6,7,8,9])
      QUnit.start()

asyncTest "existing record lifecycle callbacks fire in order", ->
  callOrder = []

  @Product.find 10, (err, product) ->
    product.validating -> callOrder.push(1)
    product.validated -> callOrder.push(2)
    product.saving -> callOrder.push(3)
    product.saved -> callOrder.push(4)
    product.destroying -> callOrder.push(6)
    product.destroyed -> callOrder.push(7)
    product.save (err) ->
      throw err if err
      callOrder.push(5)
      product.destroy (err) ->
        throw err if err
        deepEqual(callOrder, [1,2,3,4,5,6,7])
        QUnit.start()

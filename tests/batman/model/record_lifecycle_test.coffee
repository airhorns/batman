{TestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

QUnit.module "Batman.Model record lifecycle",
  setup: ->
    class @Product extends Batman.Model
      @encode 'name'
      @persist TestStorageAdapter

asyncTest "new record lifecycle callbacks fire in order", ->
  callOrder = []

  product = new @Product()
  product.lifecycle.onEnter 'dirty', -> callOrder.push(0)
  product.lifecycle.onEnter 'validating', -> callOrder.push(1)
  product.lifecycle.onEnter 'validated', -> callOrder.push(2)
  product.lifecycle.onEnter 'creating', -> callOrder.push(3)
  product.lifecycle.onEnter 'created', -> callOrder.push(4)
  product.lifecycle.onEnter 'loaded', -> callOrder.push(5)
  product.lifecycle.onEnter 'destroying', -> callOrder.push(7)
  product.lifecycle.onEnter 'destroyed', -> callOrder.push(8)
  product.set('foo', 'bar')
  Batman.developer.suppress()
  product.save (err) ->
    throw err if err
    callOrder.push(6)
    product.destroy (err) ->
      throw err if err
      deepEqual(callOrder, [0,1,2,0,3,4,5,6,7,8])
      Batman.developer.unsuppress()
      QUnit.start()

asyncTest "existing record lifecycle callbacks fire in order", ->
  callOrder = []

  Batman.developer.suppress()
  @Product.find 10, (err, product) ->
    product.lifecycle.onEnter 'validating', -> callOrder.push(1)
    product.lifecycle.onEnter 'validated', -> callOrder.push(2)
    product.lifecycle.onEnter 'saving', -> callOrder.push(3)
    product.lifecycle.onEnter 'saved', -> callOrder.push(4)
    product.lifecycle.onEnter 'destroying', -> callOrder.push(6)
    product.lifecycle.onEnter 'destroyed', -> callOrder.push(7)
    product.save (err) ->
      throw err if err
      callOrder.push(5)
      product.destroy (err) ->
        throw err if err
        deepEqual(callOrder, [1,2,3,4,5,6,7])
        Batman.developer.unsuppress()
        QUnit.start()

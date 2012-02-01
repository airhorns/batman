{TestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

QUnit.module "Batman.Model record lifecycle",
  setup: ->
    class @Product extends Batman.Model
      @encode 'name'
      @persist TestStorageAdapter

asyncTest "new record lifecycle callbacks fire in order", ->
  callOrder = []

  product = new @Product()
  product.on 'dirty', -> callOrder.push(0)
  product.on 'validating', -> callOrder.push(1)
  product.on 'validated', -> callOrder.push(2)
  product.on 'saving', -> callOrder.push(3)
  product.on 'creating', -> callOrder.push(4)
  product.on 'created', -> callOrder.push(5)
  product.on 'saved', -> callOrder.push(6)
  product.on 'destroying', -> callOrder.push(8)
  product.on 'destroyed', -> callOrder.push(9)
  product.set('foo', 'bar')
  Batman.developer.suppress()
  product.save (err) ->
    throw err if err
    callOrder.push(7)
    product.destroy (err) ->
      throw err if err
      deepEqual(callOrder, [0,1,2,0,3,4,5,6,7,8,9])
      Batman.developer.unsuppress()
      QUnit.start()

asyncTest "existing record lifecycle callbacks fire in order", ->
  callOrder = []

  Batman.developer.suppress()
  @Product.find 10, (err, product) ->
    product.on 'validating', -> callOrder.push(1)
    product.on 'validated', -> callOrder.push(2)
    product.on 'saving', -> callOrder.push(3)
    product.on 'saved', -> callOrder.push(4)
    product.on 'destroying', -> callOrder.push(6)
    product.on 'destroyed', -> callOrder.push(7)
    product.save (err) ->
      throw err if err
      callOrder.push(5)
      product.destroy (err) ->
        throw err if err
        deepEqual(callOrder, [1,2,3,4,5,6,7])
        Batman.developer.unsuppress()
        QUnit.start()

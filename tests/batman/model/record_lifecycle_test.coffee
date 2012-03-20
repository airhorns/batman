{TestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

QUnit.module "Batman.Model record lifecycle",
  setup: ->
    class @Product extends Batman.Model
      @encode 'name'
      @persist TestStorageAdapter

asyncTest "new record lifecycle callbacks fire in order", ->
  callOrder = []

  product = new @Product()
  product.get('lifecycle').onEnter 'dirty', -> callOrder.push(0)
  product.get('lifecycle').onEnter 'creating', -> callOrder.push(1)
  product.get('lifecycle').onEnter 'clean', -> callOrder.push(2)
  product.get('lifecycle').onEnter 'destroying', -> callOrder.push(4)
  product.get('lifecycle').onEnter 'destroyed', -> callOrder.push(5)

  product.set('foo', 'bar')

  product.save (err) ->
    throw err if err
    callOrder.push(3)

    product.destroy (err) ->
      throw err if err
      deepEqual(callOrder, [0,1,2,3,4,5])
      QUnit.start()

asyncTest "existing record lifecycle callbacks fire in order", ->
  callOrder = []

  @Product.find 10, (err, product) ->
    product.get('lifecycle').onEnter 'saving', -> callOrder.push(0)
    product.get('lifecycle').onEnter 'clean', -> callOrder.push(1)
    product.get('lifecycle').onEnter 'destroying', -> callOrder.push(3)
    product.get('lifecycle').onEnter 'destroyed', -> callOrder.push(4)

    product.save (err) ->
      throw err if err
      callOrder.push(2)

      product.destroy (err) ->
        throw err if err
        deepEqual(callOrder, [0,1,2,3,4])
        QUnit.start()

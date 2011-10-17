{TestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

QUnit.module "Batman.Model state transitions",
  setup: ->
    class @Product extends Batman.Model
      @persist TestStorageAdapter

test "new instances start 'clean'", ->
  product = new @Product
  ok product.isNew()
  equal product.get('lifecycle').get('state'), 'clean'

asyncTest "loaded instances start 'clean'", 2, ->
  product = new @Product(10)
  product.load (err, product) ->
    throw err if err
    ok !product.isNew()
    equal product.get('lifecycle').get('state'), 'clean'
    QUnit.start()

test "instances have state transitions for observation", 1, ->
  product = new @Product
  product.get('lifecycle').onTransition 'clean', 'dirty', spy = createSpy()
  product.set('foo', true)
  ok spy.called

asyncTest "instance loads can be nested", 1, ->
  product = new @Product(10)
  product.load (err, product) ->
    throw err if err
    product.load (err, product) ->
      throw err if err
      ok product
      QUnit.start()

asyncTest "class loads can be nested", 1, ->
  @Product.load (err, products) =>
    throw err if err
    @Product.load (err, products) ->
      throw err if err
      ok products
      QUnit.start()

#asyncTest "instance loads can occur simultaneously", 4, ->
  #old = TestStorageAdapter::read
  #TestStorageAdapter::read = (args..., callback) ->
    #old.call @, args..., (error, records) ->
      #setTimeout ->
        #callback(error, records)
      #, 20

  #done = 0
  #product = new @Product(10)

  #for i in [0..3]
    #product.load (err, product) =>
      #throw err if err
      #ok product
      #if ++done == 4
        #TestStorageAdapter::read = old
        #QUnit.start()

asyncTest "class loads can occur simultaneously", 4, ->
  old = TestStorageAdapter::readAll
  TestStorageAdapter::readAll = (args..., callback) ->
    old.call @, args..., (error, records) ->
      setTimeout ->
        callback(error, records)
      , 20

  done = 0

  for i in [0..3]

    @Product.load (err, products) =>
      throw err if err
      ok products
      if ++done == 4
        TestStorageAdapter::readAll = old
        QUnit.start()

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

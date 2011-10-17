{TestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

stateTransitionSuite = ->
  test "new instances start 'clean'", ->
    product = @subject()
    ok product.isNew()
    equal product.get('lifecycle').get('state'), 'clean'

  asyncTest "loaded instances start 'clean'", 2, ->
    product = @subject(10)
    product.load (err, product) ->
      throw err if err
      ok !product.isNew()
      equal product.get('lifecycle').get('state'), 'clean'
      QUnit.start()

  test "instances have state transitions for observation", 1, ->
    product = @subject()
    product.get('lifecycle').onTransition 'clean', 'dirty', spy = createSpy()
    product.set('foo', true)
    ok spy.called

  asyncTest "instance loads can be nested", 1, ->
    product = @subject(10)
    product.load (err, product) ->
      throw err if err
      product.load (err, product) ->
        throw err if err
        ok product
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

QUnit.module "Batman.Model record state transitions",
  setup: ->
    class @Product extends Batman.Model
      @persist TestStorageAdapter

    @subject = => new @Product(arguments...)

stateTransitionSuite()

asyncTest "class loads can be nested", 1, ->
  @Product.load (err, products) =>
    throw err if err
    @Product.load (err, products) ->
      throw err if err
      ok products
      QUnit.start()

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

  product = @subject()
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

  subject = @subject(10)
  subject.load (err, product) ->
    subject.get('lifecycle').onEnter 'saving', -> callOrder.push(0)
    subject.get('lifecycle').onEnter 'clean', -> callOrder.push(1)
    subject.get('lifecycle').onEnter 'destroying', -> callOrder.push(3)
    subject.get('lifecycle').onEnter 'destroyed', -> callOrder.push(4)
    subject.save (err) ->
      throw err if err
      callOrder.push(2)
      subject.destroy (err) ->
        throw err if err
        deepEqual(callOrder, [0,1,2,3,4])
        QUnit.start()

QUnit.module "Batman.Model draft state transitions",
  setup: ->
    class @Product extends Batman.Model
      @persist TestStorageAdapter

    @subject = => (new @Product(arguments...)).draft()

stateTransitionSuite()

asyncTest "new draftlifecycle callbacks fire in order", ->
  callOrder = []

  product = @subject()
  product.get('lifecycle').onEnter 'dirty', -> callOrder.push(0)
  product.get('lifecycle').onEnter 'creating', -> callOrder.push(1)
  product.get('lifecycle').onEnter 'clean', -> callOrder.push(2)
  product.set('foo', 'bar')
  product.save (err) ->
    throw err if err
    callOrder.push(3)
    deepEqual(callOrder, [0,1,2,3])
    QUnit.start()

asyncTest "existing draft lifecycle callbacks fire in order", ->
  callOrder = []

  subject = @subject(10)
  subject.load (err, product) ->
    subject.get('lifecycle').onEnter 'saving', -> callOrder.push(0)
    subject.get('lifecycle').onEnter 'clean', -> callOrder.push(1)
    subject.save (err) ->
      throw err if err
      callOrder.push(2)
      deepEqual(callOrder, [0,1,2])
      QUnit.start()

asyncTest "existing draft destruction lifecycle callbacks fire in order", ->
  callOrder = []

  subject = @subject(10)
  subject.load (err, product) ->
    subject.get('lifecycle').onEnter 'destroying', -> callOrder.push(0)
    subject.get('lifecycle').onEnter 'destroyed', -> callOrder.push(1)
    subject.destroy (err) ->
      throw err if err
      callOrder.push 2
      deepEqual(callOrder, [0,1,2])
      QUnit.start()

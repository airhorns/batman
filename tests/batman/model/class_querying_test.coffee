{TestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

QUnit.module "Batman.Model class finding"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'

    @adapter = new TestStorageAdapter(@Product)
    @adapter.storage =
      'products1': {name: "One", cost: 10, id:1}
      'products2': {name: "Two", cost: 5, id:2}

    @Product.persist @adapter

test "will error unless a callback is provided", ->
  raises (=> @Product.find 1),
    (message) -> message is "missing callback"

asyncTest "models will find an instance in the store", ->
  @Product.find 1, (err, product) ->
    throw err if err
    equal product.get('name'), 'One'
    QUnit.start()

asyncTest "found models should end up in the all set", ->
  @Product.find 1, (err, firstProduct) =>
    throw err if err
    equal @Product.get('all').length, 1
    QUnit.start()

asyncTest "models will find the same instance if called twice", ->
  @Product.find 1, (err, firstProduct) =>
    throw err if err
    @Product.find 1, (err, secondProduct) =>
      throw err if err
      equal firstProduct, secondProduct
      equal @Product.get('all').length, 1
      QUnit.start()

QUnit.module "Batman.Model class loading"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'

    @adapter = new TestStorageAdapter(@Product)
    @adapter.storage =
      'products1': {name: "One", cost: 10, id:1}
      'products2': {name: "Two", cost: 5, id:2}

    @Product.persist @adapter

asyncTest "models will load all their records", ->
  @Product.load (err, products) =>
    throw err if err
    equal products.length, 2
    equal @Product.get('all.length'), 2
    QUnit.start()

asyncTest "classes fire their loading/loaded callbacks", ->
  callOrder = []
  @Product.loading -> callOrder.push 1
  @Product.loaded -> callOrder.push 2

  @Product.load (err, products) =>
    delay ->
      deepEqual callOrder, [1,2]

asyncTest "models will load all their records matching an options hash", ->
  @Product.load {name: 'One'}, (err, products) ->
    equal products.length, 1
    QUnit.start()

asyncTest "models will maintain the all set", ->
  @Product.load {name: 'One'}, (err, products) =>
    equal @Product.get('all').length, 1, 'Products loaded are added to the set'

    @Product.load {name: 'Two'}, (err, products) =>
      equal @Product.get('all').length, 2, 'Products loaded are added to the set'

      @Product.load {name: 'Two'}, (err, products) =>
        equal @Product.get('all').length, 2, "Duplicate products aren't added to the set."

        QUnit.start()

asyncTest "models will maintain the all set if no callbacks are given", ->
  @Product.load {name: 'One'}
  delay =>
    equal @Product.get('all').length, 1, 'Products loaded are added to the set'
    @Product.load {name: 'Two'}
    delay =>
      equal @Product.get('all').length, 2, 'Products loaded are added to the set'
      @Product.load {name: 'Two'}
      delay =>
        equal @Product.get('all').length, 2, "Duplicate products aren't added to the set."

asyncTest "loading the same models will return the same instances", ->
  @Product.load {name: 'One'}, (err, productsOne) =>
    equal @Product.get('all').length, 1

    @Product.load {name: 'One'}, (err, productsTwo) =>
      deepEqual productsOne, productsTwo
      equal @Product.get('all').length, 1
      QUnit.start()

test "models without storage adapters should throw errors when trying to be loaded", 1, ->
  class Silly extends Batman.Model
  try
    Silly.load()
  catch e
    ok e


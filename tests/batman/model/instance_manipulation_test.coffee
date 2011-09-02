{TestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

QUnit.module "Batman.Model instance loading"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'

    @adapter = new TestStorageAdapter(@Product)
    @adapter.storage =
      'products1': {name: "One", cost: 10, id:1}

    @Product.persist @adapter

asyncTest "instantiated instances can load their values", ->
  product = new @Product(1)
  product.load (err, product) =>
    throw err if err
    equal product.get('name'), 'One'
    equal product.get('id'), 1
    QUnit.start()

asyncTest "instantiated instances can load their values", ->
  product = new @Product(1110000) # Non existant primary key.
  product.load (err, product) =>
    ok err
    QUnit.start()

asyncTest "loading instances should add them to the all set", ->
  product = new @Product(1)
  product.load (err, product) =>
    equal @Product.get('all').length, 1
    QUnit.start()

asyncTest "loading instances should add them to the all set if no callbacks are given", ->
  product = new @Product(1)
  product.load()
  delay =>
    equal @Product.get('all').length, 1

QUnit.module "Batman.Model instance saving"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'

    @adapter = new TestStorageAdapter(@Product)
    @Product.persist @adapter

test "model instances should save", ->
  product = new @Product()
  product.save (err, product) =>
    throw err if err?
    ok product.get('id') # We rely on the test storage adapter to add an ID, simulating what might actually happen IRL

test "new instances should be added to the identity map", ->
  product = new @Product()
  equal @Product.get('all.length'), 0
  product.save (err, product) =>
    throw err if err?
    equal @Product.get('all.length'), 1

asyncTest "new instances should be added to the identity map even if no callback is given", ->
  product = new @Product()
  equal @Product.get('all.length'), 0
  product.save()
  delay =>
    throw err if err?
    equal @Product.get('all.length'), 1


test "existing instances shouldn't be re added to the identity map", ->
  product = new @Product(10)
  product.load (err, product) =>
    throw err if err
    equal @Product.get('all.length'), 1
    product.save (err, product) =>
      throw err if err?
      equal @Product.get('all.length'), 1

test "model instances should throw if they can't be saved", ->
  product = new @Product()
  @adapter.create = (record, options, callback) -> callback(new Error("couldn't save for some reason"))
  product.save (err, product) =>
    ok err

test "model instances shouldn't save if they don't validate", ->
  @Product.validate 'name', presence: yes
  product = new @Product()
  product.save (err, product) ->
    equal err.length, 1

test "model instances shouldn't save if they have been destroyed", ->
  p = new @Product(10)
  p.destroy (err) =>
    throw err if err
    p.save (err) ->
      ok err

QUnit.module "Batman.Model instance destruction"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'

    @adapter = new TestStorageAdapter(@Product)
    @Product.persist @adapter

asyncTest "model instances should be destroyable", ->
  @Product.find 10, (err, product) =>
    throw err if err
    equal @Product.get('all').length, 1

    product.destroy (err) =>
      throw err if err
      equal @Product.get('all').length, 0, 'instances should be removed from the identity map upon destruction'
      QUnit.start()

asyncTest "model instances which don't exist in the store shouldn't be destroyable", ->
  p = new @Product(11000)
  p.destroy (err) =>
    ok err
    QUnit.start()


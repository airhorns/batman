{TestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

loadSuite = (name) ->
  asyncTest "instantiated #{name} can load their values", ->
    product = @subject(1)
    product.load (err, product) =>
      throw err if err
      equal product.get('name'), 'One'
      equal product.get('id'), 1
      QUnit.start()

  asyncTest "non-existant #{name} instances throw an error", ->
    product = @subject(1000000) # Non existant primary key.
    equal @Product.get('loaded').length, 0
    product.load (err, product) =>
      ok err
      equal @Product.get('loaded').length, 0, "Non existant #{name} aren\'t added to the all set"
      QUnit.start()

  asyncTest "loading #{name} should add them to the all set", ->
    product = @subject(1)
    equal @Product.get('loaded').length, 0
    product.load (err, product) =>
      throw err if err
      equal @Product.get('loaded').length, 1
      QUnit.start()

  asyncTest "loading #{name} should add them to the all set if no callbacks are given", ->
    product = new @Product(1)
    equal @Product.get('loaded').length, 0
    product.load()
    delay =>
      equal @Product.get('loaded').length, 1

loadSetup = ->
  class @Product extends Batman.Model
    @encode 'name', 'cost'

  @adapter = new TestStorageAdapter(@Product)
  @adapter.storage =
    'products1': {name: "One", cost: 10, id:1}

  @Product.persist @adapter

QUnit.module "Batman.Model record instance loading"
  setup: ->
    loadSetup.call(@)
    @subject = => new @Product(arguments...)

loadSuite('record instances')

QUnit.module "Batman.Model draft instance loading"
  setup: ->
    loadSetup.call(@)
    @subject = => (new @Product(arguments...)).draft()

loadSuite('draft instances')

saveSetup = ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'

    @adapter = new TestStorageAdapter(@Product)
    @Product.persist @adapter

saveSuite = (name) ->
  asyncTest "new #{name} should save", ->
    product = @subject()
    product.save (err, product) =>
      throw err if err?
      ok product.get('id') # We rely on the test storage adapter to add an ID, simulating what might actually happen IRL
      QUnit.start()

  asyncTest "new #{name} should be added to the identity map", ->
    product = @subject()
    equal @Product.get('loaded.length'), 0
    product.save (err, product) =>
      throw err if err?
      equal @Product.get('loaded').length, 1
      QUnit.start()

  asyncTest "new #{name} should be added to the identity map even if no callback is given", ->
    product = @subject()
    equal @Product.get('loaded.length'), 0
    product.save()
    delay =>
      throw err if err?
      equal @Product.get('loaded').length, 1

  asyncTest "existing #{name} shouldn't be re added to the identity map", ->
    product = @subject(10)
    product.load (err, product) =>
      throw err if err
      equal @Product.get('loaded').length, 1
      product.save (err, product) =>
        throw err if err?
        equal @Product.get('loaded').length, 1
        QUnit.start()

  asyncTest "existing #{name} should be updated with incoming attributes", ->
    @adapter.storage = {"products10": {name: "override"}}
    product = @subject(id: 10, name: "underneath")
    product.load (err, product) =>
      throw err if err
      equal product.get('name'), 'override'
      QUnit.start()

  asyncTest "#{name} should throw if they can't be saved", ->
    product = @subject()
    @adapter.create = (record, options, callback) -> callback(new Error("couldn't save for some reason"))
    product.save (err, product) =>
      ok err
      QUnit.start()

  asyncTest "#{name} shouldn't save if they don't validate", ->
    @Product.validate 'name', presence: yes
    product = @subject()
    product.save (err, product) ->
      equal err.length, 1
      QUnit.start()

  asyncTest "#{name} shouldn't save if they have been destroyed", ->
    p = @subject(10)
    p.destroy (err) =>
      throw err if err
      p.save (err) ->
        ok err
        p.load (err) ->
          ok err
        QUnit.start()

  asyncTest "string ids are coerced into integers when possible", ->
    product = @subject()
    product.save (err) =>
      throw err if err
      id = product.get('id')
      @Product.find ""+id, (err, foundProduct) ->
        throw err if err
        equal foundProduct.record(), product.record()
        QUnit.start()

QUnit.module "Batman.Model record instance saving"
  setup: ->
    saveSetup.call(@)
    @subject = => new @Product(arguments...)

saveSuite('record instances')

asyncTest "create method returns an instance of a model while saving it", ->
  result = @Product.create (err, product) =>
    throw err if err
    ok product instanceof @Product
    QUnit.start()
  ok result instanceof @Product

QUnit.module "Batman.Model draft instance saving"
  setup: ->
    saveSetup.call(@)
    @subject = => (new @Product(arguments...)).draft()

saveSuite('draft instances')


destroySuite = (name) ->
  asyncTest "#{name} should be destroyable", ->
    product = @subject(10)
    product.load (err, product) =>
      throw err if err
      equal @Product.get('loaded').length, 1

      product.destroy (err) =>
        throw err if err
        equal @Product.get('loaded').length, 0, 'all record instances should be removed from the identity map upon destruction'
        QUnit.start()

  asyncTest "#{name} which don't exist in the store shouldn't be destroyable", ->
    p = @subject(11000)
    p.destroy (err) =>
      ok err
      QUnit.start()

destroySetup = (name) ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'

    @adapter = new TestStorageAdapter(@Product)
    @Product.persist @adapter

QUnit.module "Batman.Model record instance destruction"
  setup: ->
    destroySetup.call(@)
    @subject = => new @Product(arguments...)

destroySuite("record instances")

QUnit.module "Batman.Model draft instance destruction"
  setup: ->
    destroySetup.call(@)
    @subject = => (new @Product(arguments...)).draft()

destroySuite("draft instances")

class TestStorageAdapter extends Batman.StorageAdapter
  constructor: ->
    super
    @counter = 10
    @storage = {}
    @lastQuery = false
    @create(new @model, {}, ->)

  update: (record, options, callback) ->
    id = record.get('id')
    if id
      @storage[@modelKey + id] = record.toJSON()
      callback(undefined, record)
    else
      callback(new Error("Couldn't get record primary key."))

  create: (record, options, callback) ->
    id = record.set('id', @counter++)
    if id
      @storage[@modelKey + id] = record.toJSON()
      callback(undefined, record)
    else
      callback(new Error("Couldn't get record primary key."))

  read: (record, options, callback) ->
    id = record.get('id')
    if id
      attrs = @storage[@modelKey + id]
      if attrs
        record.fromJSON(attrs)
        callback(undefined, record)
      else
        callback(new Error("Couldn't find record!"))
    else
      callback(new Error("Couldn't get record primary key."))

  readAll: (_, options, callback) ->
    records = []
    for storageKey, data of @storage
      match = true
      for k, v of options
        if data[k] != v
          match = false
          break
      records.push data if match

    callback(undefined, @getRecordsFromData(records))

  destroy: (record, options, callback) ->
    id = record.get('id')
    if id
      key = @modelKey + id
      if @storage[key]
        delete @storage[key]
        callback(undefined, record)
      else
        callback(new Error("Can't delete nonexistant record!"), record)
    else
      callback(new Error("Can't delete record without an primary key!"), record)

class @Product extends Batman.Model
  @persist TestStorageAdapter

QUnit.module "Batman.Model",
  setup: ->
    class @Product extends Batman.Model

test "constructors should always be called with new", ->
  raises (-> product = Product()),
    (message) -> 
      message is "constructors must be called with new"

test "primary key is undefined on new models", ->
  product = new @Product
  ok product.isNew()
  equal typeof product.get('id'), 'undefined'

test "primary key is 'id' by default", ->
  product = new @Product(id: 10)
  equal product.get('id'), 10

test "primary key can be changed by setting primary key on the model class", ->
  @Product.primaryKey = 'uuid'
  product = new @Product(uuid: "abc123")
  equal product.get('id'), 'abc123'

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

QUnit.module "Batman.Model dirty key tracking",
  setup: ->
    class @Product extends Batman.Model
      @persist TestStorageAdapter

test "no keys are dirty upon creation", ->
  product = new @Product
  equal product.get('dirtyKeys').length, 0

test "old values are tracked in the dirty keys hash", ->
  product = new @Product
  product.set 'foo', 'bar'
  product.set 'foo', 'baz'
  equal(product.get('dirtyKeys.foo'), 'bar')

test "creating instances by passing attributes sets those attributes as dirty", ->
  product = new @Product foo: 'bar'
  equal(product.get('dirtyKeys').length, 1)
  equal(product.get('state'), 'dirty')

asyncTest "saving clears dirty keys", ->
  product = new @Product foo: 'bar', id: 1
  product.save (err) ->
    throw err if err
    equal(product.dirtyKeys.length, 0)
    notEqual(product.get('state'), 'dirty')
    QUnit.start()

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
  raises (-> @Product.find 1),
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

QUnit.module "Batman.Model: encoding/decoding to/from JSON"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'
      @accessor 'excitingName'
        get: -> @get('name').toUpperCase()

test "keys marked for encoding should be encoded", ->
  p = new @Product {name: "Cool Snowboard", cost: 12.99}
  deepEqual p.toJSON(), {name: "Cool Snowboard", cost: 12.99}

test "undefined keys marked for encoding shouldn't be encoded", ->
  p = new @Product {name: "Cool Snowboard"}
  deepEqual p.toJSON(), {name: "Cool Snowboard"}

test "accessor keys marked for encoding should be encoded", ->
  class TestProduct extends @Product
    @encode 'excitingName'

  p = new TestProduct {name: "Cool Snowboard", cost: 12.99}
  deepEqual p.toJSON(), {name: "Cool Snowboard", cost: 12.99, excitingName: 'COOL SNOWBOARD'}

test "keys marked for decoding should be decoded", ->
  p = new @Product
  json = {name: "Cool Snowboard", cost: 12.99}

  p.fromJSON(json)
  equal p.get('name'), "Cool Snowboard"
  equal p.get('cost'), 12.99

test "keys not marked for encoding shouldn't be encoded", ->
  p = new @Product {name: "Cool Snowboard", cost: 12.99, wibble: 'wobble'}
  deepEqual p.toJSON(), {name: "Cool Snowboard", cost: 12.99}

test "keys not marked for decoding shouldn't be decoded", ->
  p = new @Product
  json = {name: "Cool Snowboard", cost: 12.99, wibble: 'wobble'}

  p.fromJSON(json)
  equal p.get('name'), "Cool Snowboard"
  equal p.get('cost'), 12.99
  equal p.get('wibble'), undefined

test "models without any decoders should decode all keys with camelization", ->

  class TestProduct extends Batman.Model
    # No encoders.

  p = new TestProduct
  p.fromJSON {name: "Cool Snowboard", cost: 12.99, rails_is_silly: "yup"}

  equal p.get('name'), "Cool Snowboard"
  equal p.get('cost'), 12.99
  equal p.get('railsIsSilly'), 'yup'

QUnit.module "Batman.Model: encoding: custom encoders/decoders"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', (unencoded) -> unencoded.toUpperCase()

      @encode 'date',
        encode: (unencoded) -> "zzz"
        decode: (encoded) -> "yyy"

test "custom encoders with an encode and a decode implementation should be recognized", ->
  p = new @Product(date: "clobbered")
  deepEqual p.toJSON(), {date: "zzz"}

  json =   p = new @Product
  p.fromJSON({date: "clobbered"})
  equal p.get('date'), "yyy"

test "passing a function should shortcut to passing an encoder", ->
  p = new @Product(name: "snowboard")
  deepEqual p.toJSON(), {name: "SNOWBOARD"}

QUnit.module "Batman.Model: validations"

asyncTest "validation shouldn leave the model in the same state it left it", ->
  class Product extends Batman.Model
    @validate 'name', presence: yes

  p = new Product
  oldState = p.state()
  p.validate (result, errors) ->
    equal p.state(), oldState
    QUnit.start()

asyncTest "length", 3, ->
  class Product extends Batman.Model
    @validate 'exact', length: 5
    @validate 'max', maxLength: 4
    @validate 'range', lengthWithin: [3, 5]

  p = new Product exact: '12345', max: '1234', range: '1234'
  p.validate (result) ->
    ok result

    p.set 'exact', '123'
    p.set 'max', '12345'
    p.set 'range', '12'

    p.validate (result, errors) ->
      ok !result
      equal errors.length, 3
      QUnit.start()

asyncTest "presence", 2, ->
  class Product extends Batman.Model
    @validate 'name', presence: yes

  p = new Product name: 'nick'
  p.validate (result, errors) ->
    ok result
    p.unset 'name'
    p.validate (result, errors) ->
      ok !result
      QUnit.start()

asyncTest "custom async validations", ->
  letItPass = true
  class Product extends Batman.Model
    @validate 'name', (errors, record, key, callback) ->
      setTimeout ->
        errors.get('name').add "didn't validate" unless letItPass
        callback()
      , 0
  p = new Product
  p.validate (result, errors) ->
    ok result
    letItPass = false
    p.validate (result, errors) ->
      ok !result
      QUnit.start()

QUnit.module "Batman.Model: storage"

if window? && 'localStorage' in window
  asyncTest "local storage", 1, ->
    localStorage.clear()

    class Product extends Batman.Model
      @persist Batman.LocalStorage
      @encode 'foo'

    p = new Product foo: 'bar'

    p.afterSave ->
      copy = Product.find p.id
      copy.afterLoad ->
        equal copy.get('foo'), 'bar'
        start()

    p.save()

class TestStorageAdapter extends Batman.StorageAdapter
  constructor: ->
    super
    @counter = 10
    @storage = {}
    @lastQuery = false
    @create(new @model, {}, ->)

  update: (record, options, callback) ->
    id = record.get('identifier')
    if id
      @storage[@modelKey + id] = record.toJSON()
      callback(undefined, record)
    else
      callback(new Error("Couldn't get record identifier."))

  create: (record, options, callback) ->
    id = record.set('identifier', @counter++)
    if id
      @storage[@modelKey + id] = record.toJSON()
      callback(undefined, record)
    else
      callback(new Error("Couldn't get record identifier."))

  read: (record, options, callback) ->
    id = record.get('identifier')
    if id
      attrs = @storage[@modelKey + id]
      callback(undefined, record.fromJSON(attrs))
    else
      callback(new Error("Couldn't get record identifier."))

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

  destroy: () ->

class @Product extends Batman.Model
  @persist TestStorageAdapter

QUnit.module "Batman.Model",
  setup: ->
    class @Product extends Batman.Model

test "identifier is undefined on new models", ->
  product = new @Product
  ok product.isNew()
  equal typeof product.get('identifier'), 'undefined'

test "identifier is 'id' by default", ->
  product = new @Product(id: 10)
  equal product.get('identifier'), 10

test "identifier can be changed by setting identifier on the model class", ->
  @Product.identifier = 'uuid'
  product = new @Product(uuid: "abc123")
  equal product.get('identifier'), 'abc123'

QUnit.module "Batman.Model state transitions",
  setup: ->
    class @Product extends Batman.Model
      @persist TestStorageAdapter

test "new instances start 'empty'", ->
  product = new @Product
  ok product.isNew()
  equal product.state(), 'empty'

asyncTest "loaded instances start 'loaded'", 2, ->
  @Product.find 10, (err, product) ->
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
  product.set('foo', 'bar')
  product.save (err) ->
    throw err if err
    callOrder.push(7)
    deepEqual(callOrder, [0,1,2,3,4,5,6,7])
    QUnit.start()

asyncTest "existing record lifecycle callbacks fire in order", ->
  callOrder = []
  classCallOrder = []

  @Product.loading -> classCallOrder.push 1
  @Product.loaded -> classCallOrder.push 2

  @Product.find 10, (err, product) ->
    product.validating -> callOrder.push(1)
    product.validated -> callOrder.push(2)
    product.saving -> callOrder.push(3)
    product.saved -> callOrder.push(4)
    product.save(-> callOrder.push(5))

    deepEqual(callOrder, [1,2,3,4,5])
    deepEqual(classCallOrder, [1,2])
    QUnit.start()

QUnit.module "Batman.Model class loading"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'

    @adapter = new TestStorageAdapter(@Product)
    @adapter.storage =
      'product1': {name: "One", cost: 10, id:1}
      'product2': {name: "Two", cost: 5, id:2}

    @Product.persist @adapter

asyncTest "models will load all their records", ->
  @Product.load (err, products) =>
    throw err if err
    equal products.length, 2
    equal @Product.get('all.length'), 2
    QUnit.start()

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

test "models without storage adapters should throw errors when trying to be loaded", 1, ->
  class Silly extends Batman.Model
  try
    Silly.load()
  catch e
    ok e

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

test "length", ->
  class Product extends Batman.Model
    @validate 'exact', length: 5
    @validate 'max', maxLength: 4
    @validate 'range', lengthWithin: [3, 5]

  p = new Product exact: '12345', max: '1234', range: '1234'
  ok p.isValid()

  p.set 'exact', '123'
  p.set 'max', '12345'
  p.set 'range', '12'
  ok !p.isValid()
  equal p.errors.length, 3

test "presence", ->
  class Product extends Batman.Model
    @validate 'name', presence: yes

  p = new Product name: 'nick'
  ok p.isValid()

  p.unset 'name'
  ok !p.isValid()

asyncTest "async", 2, ->
  hasFailed = no
  class Product extends Batman.Model
    @validate 'email', (validator, record, key, value) ->
      validator.wait()
      setTimeout (->
        if hasFailed
          validator.success()
        else
          validator.error 'email is already taken'
          hasFailed = yes

        validator.resume()
      ), 500

  p = new Product email: 'nick@shopify.com'
  p.validated -> equal(p.errors.length, 1); start()
  ok !p.isValid()

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

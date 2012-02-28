if typeof require isnt 'undefined'
  {restStorageTestSuite} = require('./rest_storage_helper')
else
  {restStorageTestSuite} = window

MockRequest = restStorageTestSuite.MockRequest

oldRequest = Batman.Request
oldExpectedForUrl = MockRequest.getExpectedForUrl

QUnit.module "Batman.RailsStorage"
  setup: ->
    MockRequest.getExpectedForUrl = (url) ->
      @expects[url.slice(0,-5)] || [] # cut off the .json so the fixtures from the test suite work fine

    Batman.Request = MockRequest
    MockRequest.reset()

    class @Store extends Batman.Model
      @encode 'id', 'name'
    @storeAdapter = new Batman.RailsStorage(@Store)
    @Store.persist @storeAdapter

    class @Product extends Batman.Model
      @encode 'id', 'name', 'cost'
    @productAdapter = new Batman.RailsStorage(@Product)
    @Product.persist @productAdapter

    @adapter = @productAdapter # for restStorageTestSuite

  teardown: ->
    Batman.Request = oldRequest
    MockRequest.getExpectedForUrl = oldExpectedForUrl

restStorageTestSuite.testOptionsGeneration('.json')
restStorageTestSuite()

asyncTest 'creating in storage: should callback with the record with errors on it if server side validation fails', ->
  MockRequest.expect
    url: '/products'
    method: 'POST'
  , error:
      status: 422
      response: JSON.stringify
        name: ["can't be test", "must be valid"]

  product = new @Product(name: "test")
  @productAdapter.perform 'create', product, {}, (err, record) =>
    ok err instanceof Batman.ErrorsSet
    ok record
    equal record.get('errors').length, 2
    QUnit.start()

asyncTest 'hasOne formats the URL to /roots/id/singular', 1, ->
  @Store.hasOne 'product', namespace: @
  @Product.belongsTo 'store', namespace: @

  productJSON =
    id: 1
    name: 'Product One'
    cost: 10
    store_id: 1

  MockRequest.expect {
    url: '/stores/1/product' # .json is cut off in setup
    method: 'GET'
  }, [productJSON]

  MockRequest.expect {
    url: '/stores/1'
    method: 'GET'
  }, [{
    id: 1
    name: 'Store One'
  }]

  store = new @Store id: 1
  product = store.get('product')
  delay ->
    deepEqual product.toJSON(), productJSON


asyncTest 'hasMany formats the URL to /roots/id/plural', 1, ->
  @Store.hasMany 'products', namespace: @
  @Product.belongsTo 'store', namespace: @

  productsJSON = [{
    id: 1
    name: 'Product One'
    cost: 10
    store_id: 1
  }, {
    id: 2
    name: 'Product Two'
    cost: 10
    store_id: 1
  }]

  MockRequest.expect {
    url: '/stores/1/products' # .json is cut off in setup
    method: 'GET'
  }, productsJSON

  MockRequest.expect {
    url: '/stores/1'
    method: 'GET'
  }, [
    id: 1
    name: 'Store One'
  ]

  store = new @Store id: 1
  products = store.get('products')
  delay ->
    deepEqual (products.map (product) -> product.toJSON()), productsJSON

asyncTest 'hasMany formats the URL to /roots/id/plural when polymorphic', 1, ->
  @Store.hasMany 'products', {namespace: @, as: 'subject'}
  @Product.belongsTo 'subject', {namespace: @, polymorphic: true}

  productsJSON = [{
    id: 1
    name: 'Product One'
    cost: 10
    subject_id: 1
    subject_type: 'Store'
  }, {
    id: 2
    name: 'Product Two'
    cost: 10
    subject_id: 1
    subject_type: 'Store'
  }]

  MockRequest.expect {
    url: '/stores/1/products' # .json is cut off in setup
    method: 'GET'
  }, productsJSON

  MockRequest.expect {
    url: '/stores/1'
    method: 'GET'
  }, [
    id: 1
    name: 'Store One'
  ]

  store = new @Store id: 1
  products = store.get('products')
  delay ->
    deepEqual (products.map (product) -> product.toJSON()), productsJSON

productJSON =
  product:
    name: 'test'
    id: 10

asyncTest 'updating in storage: should serialize array data without indicies', 1, ->
  MockRequest.expect
    url: '/products'
    method: 'POST'
    data: "product%5Bname%5D%5B%5D=a&product%5Bname%5D%5B%5D=b"
  , productJSON

  MockRequest.expect
    url: '/products/10'
    method: 'PUT'
    data: "product%5Bid%5D=10&product%5Bname%5D=test&product%5Bcost%5D=10"
  , product:
      name: 'test'
      cost: 10

  MockRequest.expect
    url: '/products/10'
    method: 'GET'
  , product:
      name: 'test'
      cost: 10

  product = new @Product(name: ["a", "b"])
  @adapter.perform 'create', product, {}, (err, createdRecord) =>
    throw err if err
    product.set('cost', 10)
    @adapter.perform 'update', product, {}, (err, updatedProduct) =>
      throw err if err
      @adapter.perform 'read', product, {}, (err, readProduct) ->
        throw err if err
        equal readProduct.get('cost', 10), 10
        QUnit.start()

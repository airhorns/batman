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

    class @Product extends Batman.Model
      @encode 'name', 'cost'
    @adapter = new Batman.RailsStorage(@Product)
    @Product.persist @adapter

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
  @adapter.create product, {}, (err, record) =>
    ok err instanceof Batman.ErrorsSet
    ok record
    equal record.get('errors').length, 2
    QUnit.start()

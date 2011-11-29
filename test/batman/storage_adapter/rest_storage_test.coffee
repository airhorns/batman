if typeof require isnt 'undefined'
  {restStorageTestSuite} = require('./rest_storage_helper')
else
  {restStorageTestSuite} = window

oldRequest = Batman.Request

QUnit.module "Batman.RestStorage"
  setup: ->
    Batman.Request = restStorageTestSuite.MockRequest
    restStorageTestSuite.MockRequest.reset()
    class @Product extends Batman.Model
      @encode 'name', 'cost'
    @adapter = new Batman.RestStorage(@Product)
    @Product.persist @adapter

  teardown: ->
    Batman.Request = oldRequest

restStorageTestSuite.testOptionsGeneration()
restStorageTestSuite()

if typeof require isnt 'undefined'
  {sharedStorageTestSuite} = require('./storage_adapter_helper')
else
  {sharedStorageTestSuite} = window

if typeof window.sessionStorage isnt 'undefined'
  QUnit.module "Batman.SessionStorage"
    setup: ->
      window.sessionStorage.clear()
      class @Product extends Batman.Model
        @encode 'name', 'cost'
      @adapter = new Batman.SessionStorage(@Product)
      @Product.persist @adapter

  sharedStorageTestSuite({})

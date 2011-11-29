if typeof require isnt 'undefined'
  {sharedStorageTestSuite} = require('./storage_adapter_helper')
else
  {sharedStorageTestSuite} = window

if typeof window.localStorage isnt 'undefined'
  QUnit.module "Batman.LocalStorage"
    setup: ->
      window.localStorage.clear()
      class @Product extends Batman.Model
        @encode 'name', 'cost'
      @adapter = new Batman.LocalStorage(@Product)
      @Product.persist @adapter

  sharedStorageTestSuite({})

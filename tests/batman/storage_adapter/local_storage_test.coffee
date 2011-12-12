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

  asyncTest 'reading many from storage: should callback with only records matching the options', 4, ->
    product1 = new @Product(name: "testA", cost: 20)
    product2 = new @Product(name: "testB", cost: 10)
    @adapter.perform 'create', product1, {}, (err, createdRecord1) =>
      throw err if err
      @adapter.perform 'create', product2, {}, (err, createdRecord2) =>
        throw err if err
        @adapter.perform 'readAll', product1.constructor::, {data: {cost: 10}}, (err, readProducts) =>
          throw err if err
          equal readProducts.length, 1
          deepEqual readProducts[0].get('name'), "testB"
          @adapter.perform 'readAll', product1.constructor::, {data: {cost: 20}}, (err, readProducts) ->
            throw err if err
            equal readProducts.length, 1
            deepEqual readProducts[0].get('name'), "testA"
            QUnit.start()

# This at some point should be exported so it can be run on custom storage adapters. BUT HOOWWW
sharedStorageTestSuite = ->

  asyncTest 'creating in storage: should succeed if the record doesn\'t already exist', 1, ->
    product = new @Product(name: "test")
    @adapter.create product, {}, (err, record) =>
      throw err if err
      ok record
      QUnit.start()

  asyncTest 'creating in storage: should fail if the record does already exist', 1, ->
    product = new @Product(name: "test")
    @adapter.create product, {}, (err, record) =>
      throw err if err

      @adapter.create record, {}, (err, record) =>
        ok err
        QUnit.start()

  asyncTest "creating in storage: should create a primary key if the record doesn't already have one", 1, ->
    product = new @Product(name: "test")
    @adapter.create product, {}, (err, record) =>
      throw err if err
      ok record.get('id')
      QUnit.start()

  asyncTest 'reading from storage: should callback with the record if the record has been created', 2, ->
    product = new @Product(name: "test")

    @adapter.create product, {}, (err, record) =>
      throw err if err
      createdLater = new @Product(record.get('id'))
      @adapter.read createdLater, {}, (err, foundRecord) ->
        throw err if err
        equal foundRecord.get("name"), "test"
        ok foundRecord.get('id')
        QUnit.start()

  asyncTest 'reading from storage: should callback with an error if the record hasn\'t been created', 1, ->
    product = new @Product(name: "test")
    @adapter.read product, {}, (err, foundRecord) ->
      ok err
      QUnit.start()

  asyncTest 'reading many for storage: should callback with the records if they exist', 1, ->
    product1 = new @Product(name: "testA", cost: 20)
    product2 = new @Product(name: "testB", cost: 10)
    @adapter.create product1, {}, (err, createdRecord1) =>
      throw err if err
      @adapter.create product2, {}, (err, createdRecord2) =>
        throw err if err
        @adapter.readAll undefined, {}, (err, readProducts) ->
          throw err if err
          t = (array) ->
            array.map((p) -> p.get('name')).sort()
          deepEqual t(readProducts), t([createdRecord1, createdRecord2])
          QUnit.start()

  asyncTest 'reading many for storage: should callback with an empty array if no records exist', 1, ->
    @adapter.readAll undefined, {}, (err, readProducts) ->
      throw err if err
      deepEqual readProducts, []
      QUnit.start()

  asyncTest 'updating in storage: should callback with the record if it exists', 1, ->
    product = new @Product(name: "test")
    @adapter.create product, {}, (err, createdRecord) =>
      throw err if err
      product.set('cost', 10)
      @adapter.update product, {}, (err, updatedProduct) =>
        throw err if err
        @adapter.read product, {}, (err, readProduct) ->
          throw err if err
          equal readProduct.get('cost', 10), 10
          QUnit.start()

  asyncTest 'updating in storage: should callback with an error if the record hasn\'t been created', 1, ->
    product = new @Product(name: "test")
    @adapter.update product, {}, (err, foundRecord) ->
      ok err
      QUnit.start()

  asyncTest 'destroying in storage: should succeed if the record exists', 1, ->
    product = new @Product(name: "test")
    @adapter.create product, {}, (err, createdRecord) =>
      throw err if err
      @adapter.destroy product, {}, (err) =>
        throw err if err
        @adapter.read product, {}, (err, readProduct) =>
          ok err
          QUnit.start()

  asyncTest 'destroying in storage: should callback with an error if the record hasn\'t been created', 1, ->
    product = new @Product(name: "test")
    @adapter.destroy product, {}, (err, foundRecord) ->
      ok err
      QUnit.start()

if typeof window.localStorage isnt 'undefined'
  QUnit.module "Batman.LocalStorage"
    setup: ->
      window.localStorage.clear()
      class @Product extends Batman.Model
        @encode 'name', 'cost'
      @adapter = new Batman.LocalStorage(@Product)
      @Product.persist @adapter

  sharedStorageTestSuite()

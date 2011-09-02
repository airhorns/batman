# This at some point should be exported so it can be run on custom storage adapters.
sharedStorageTestSuite = (hooks = {}) ->
  asyncTestWithHooks = (name, count, f) ->
    QUnit.asyncTest name, count, ->
      hooks[name].call(@) if hooks[name]?
      f.call(@)

  asyncTestWithHooks 'creating in storage: should succeed if the record doesn\'t already exist', 1, ->
    product = new @Product(name: "test")
    @adapter.create product, {}, (err, record) =>
      throw err if err
      ok record
      QUnit.start()

  asyncTestWithHooks 'creating in storage: should fail if the record does already exist', 1, ->
    product = new @Product(name: "test")
    @adapter.create product, {}, (err, record) =>
      throw err if err

      @adapter.create record, {}, (err, record) =>
        ok err
        QUnit.start()

  asyncTestWithHooks "creating in storage: should create a primary key if the record doesn't already have one", 1, ->
    product = new @Product(name: "test")
    @adapter.create product, {}, (err, record) =>
      throw err if err
      ok record.get('id')
      QUnit.start()

  asyncTestWithHooks "creating in storage: should encode data before saving it", 1, ->
    @Product.encode 'name', (name) -> name.toUpperCase()
    product = new @Product(name: "test")
    @adapter.create product, {}, (err, record) =>
      throw err if err
      ok record.get('id')
      QUnit.start()

  asyncTestWithHooks 'reading from storage: should callback with the record if the record has been created', 2, ->
    product = new @Product(name: "test")

    @adapter.create product, {}, (err, record) =>
      throw err if err
      createdLater = new @Product(record.get('id'))
      @adapter.read createdLater, {}, (err, foundRecord) ->
        throw err if err
        equal foundRecord.get("name"), "test"
        ok foundRecord.get('id')
        QUnit.start()

  asyncTestWithHooks 'reading from storage: should callback with decoded data after reading it', 2, ->
    @Product.encode 'name',
      encode: (x) -> (x)
      decode: (x) -> x.toUpperCase()
    product = new @Product(name: "test")

    @adapter.create product, {}, (err, record) =>
      throw err if err
      createdLater = new @Product(record.get('id'))
      @adapter.read createdLater, {}, (err, foundRecord) ->
        throw err if err
        equal foundRecord.get("name"), "TEST"
        ok foundRecord.get('id')
        QUnit.start()

  asyncTestWithHooks 'reading from storage: should callback with an error if the record hasn\'t been created', 1, ->
    product = new @Product(name: "test")
    @adapter.read product, {}, (err, foundRecord) ->
      ok err
      QUnit.start()

  t = (array) ->
    array.map((p) -> p.get('name')).sort()

  asyncTestWithHooks 'reading many from storage: should callback with the records if they exist', 1, ->
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

  asyncTestWithHooks 'reading many from storage: should callback with the decoded records if they exist', 1, ->
    @Product.encode 'name',
      encode: (x) -> (x)
      decode: (x) -> x.toUpperCase()
    product1 = new @Product(name: "testA", cost: 20)
    product2 = new @Product(name: "testB", cost: 10)
    @adapter.create product1, {}, (err, createdRecord1) =>
      throw err if err
      @adapter.create product2, {}, (err, createdRecord2) =>
        throw err if err
        @adapter.readAll undefined, {}, (err, readProducts) ->
          throw err if err
          deepEqual t(readProducts), ['TESTA', 'TESTB']
          QUnit.start()

  asyncTestWithHooks 'reading many from storage: should callback with an empty array if no records exist', 1, ->
    @adapter.readAll undefined, {}, (err, readProducts) ->
      throw err if err
      deepEqual readProducts, []
      QUnit.start()

  asyncTestWithHooks 'updating in storage: should callback with the record if it exists', 1, ->
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

  asyncTestWithHooks 'updating in storage: should callback with an error if the record hasn\'t been created', 1, ->
    product = new @Product(name: "test")
    @adapter.update product, {}, (err, foundRecord) ->
      ok err
      QUnit.start()

  asyncTestWithHooks 'destroying in storage: should succeed if the record exists', 1, ->
    product = new @Product(name: "test")
    @adapter.create product, {}, (err, createdRecord) =>
      throw err if err
      @adapter.destroy product, {}, (err) =>
        throw err if err
        @adapter.read product, {}, (err, readProduct) =>
          ok err
          QUnit.start()

  asyncTestWithHooks 'destroying in storage: should callback with an error if the record hasn\'t been created', 1, ->
    product = new @Product(name: "test")
    @adapter.destroy product, {}, (err, foundRecord) ->
      ok err
      QUnit.start()

if typeof exports is 'undefined'
  window.sharedStorageTestSuite = sharedStorageTestSuite
else
  exports.sharedStorageTestSuite = sharedStorageTestSuite

# This at some point should be exported so it can be run on custom storage adapters.
sharedStorageTestSuite = (hooks = {}) ->
  asyncTestWithHooks = (name, count, f) ->
    QUnit.asyncTest name, count, ->
      hooks[name].call(@) if hooks[name]?
      f.call(@)

  test 'instantiating: should use the `storageKey` on the model as a namespace if it exists', ->
    klass = @adapter.constructor
    class Overridden extends Batman.Model
      @storageKey: "custom_key"

    adapter = new klass(Overridden)
    equal adapter.storageKey(), "custom_key"

  test 'instantiating: should use the `storageKey` on the model from a record passed to storageKey', ->
    klass = @adapter.constructor
    class Overridden extends Batman.Model
      @storageKey: "custom_key"

    class Subclass extends Overridden
      @storageKey: "even_more_custom"

    record = new Subclass
    adapter = new klass(Overridden)
    equal adapter.storageKey(record), "even_more_custom"

  test 'instantiating: should use pluralized underscored model name as a namespace if storageKey doesn\'t exist', ->
    klass = @adapter.constructor
    class NotOverridden extends Batman.Model

    adapter = new klass(NotOverridden)
    equal adapter.storageKey(), "not_overriddens"

  test 'instantiating: should use pluralized underscored model name as a namespace if storageKey doesn\'t exist on a passed in record', ->
    klass = @adapter.constructor
    class NotOverridden extends Batman.Model
    class NotOverriddenChild extends NotOverridden
    record = new NotOverriddenChild
    adapter = new klass(NotOverridden)

    equal adapter.storageKey(record), "not_overridden_children"

  asyncTestWithHooks 'creating in storage: should succeed if the record doesn\'t already exist', 1, ->
    product = new @Product(name: "test")
    @adapter.perform 'create', product, {}, (err, record) =>
      throw err if err
      ok record
      QUnit.start()

  asyncTestWithHooks 'creating in storage: should fail if the record does already exist', 1, ->
    product = new @Product(name: "test")
    @adapter.perform 'create', product, {}, (err, record) =>
      throw err if err

      @adapter.perform 'create', record, {}, (err, record) =>
        ok err
        QUnit.start()

  asyncTestWithHooks "creating in storage: should create a primary key if the record doesn't already have one", 1, ->
    product = new @Product(name: "test")
    @adapter.perform 'create', product, {}, (err, record) =>
      throw err if err
      ok record.get('id')
      QUnit.start()

  asyncTestWithHooks "creating in storage: should encode data before saving it", 1, ->
    @Product.encode 'name', (name) -> name.toUpperCase()
    product = new @Product(name: "test")
    @adapter.perform 'create', product, {}, (err, record) =>
      throw err if err
      ok record.get('id')
      QUnit.start()

  runRead = (product) ->
    @adapter.perform 'create', product, {}, (err, record) =>
      throw err if err
      ok record.get('id')
      createdLater = new product.constructor(record.get('id'))
      @adapter.perform 'read', createdLater, {}, (err, foundRecord) ->
        throw err if err
        equal foundRecord.get("name"), product.get('name')
        ok foundRecord.get('id')
        QUnit.start()

  asyncTestWithHooks 'reading from storage: should callback with the record if the record has been created', 3, ->
    product = new @Product(name: "test")
    runRead.call @, product

  asyncTestWithHooks 'reading from storage: should callback with the record if the record has been created and the record is an instance of a subclass', 3, ->
    class SpecialProduct extends @Product
    product = new SpecialProduct(name: "test")
    runRead.call @, product

  asyncTestWithHooks 'reading from storage: should keep records of a class and records of a subclass separate', 2, ->
    class SpecialProduct extends @Product
    subclassProduct = new SpecialProduct(name: "test sub")
    superclassProduct = new @Product(name: "test super")

    @adapter.perform 'create', subclassProduct, {}, (err, subclassRecord) =>
      throw err if err
      @adapter.perform 'create', superclassProduct, {}, (err, superclassRecord) =>
        throw err if err
        createdLater = new @Product(superclassRecord.get('id'))
        @adapter.perform 'read', createdLater, {}, (err, foundSuperclassRecord) =>
          throw err if err
          equal foundSuperclassRecord.get("name"), "test super"
          createdLater = new SpecialProduct(subclassRecord.get('id'))
          @adapter.perform 'read', createdLater, {}, (err, foundSubclassRecord) =>
            equal foundSubclassRecord.get("name"), "test sub"
            QUnit.start()

  asyncTestWithHooks 'reading from storage: should callback with decoded data after reading it', 2, ->
    @Product.encode 'name',
      encode: (x) -> (x)
      decode: (x) -> x.toUpperCase()
    product = new @Product(name: "test 8")

    @adapter.perform 'create', product, {}, (err, record) =>
      throw err if err
      createdLater = new @Product(record.get('id'))
      @adapter.perform 'read', createdLater, {}, (err, foundRecord) ->
        throw err if err
        equal foundRecord.get("name"), "TEST 8"
        ok foundRecord.get('id')
        QUnit.start()

  asyncTestWithHooks 'reading from storage: should callback with an error if the record hasn\'t been created', 1, ->
    product = new @Product(name: "test 9")
    @adapter.perform 'read', product, {}, (err, foundRecord) ->
      ok err
      QUnit.start()

  t = (array) ->
    array.map((p) -> p.get('name')).sort()

  runReadMany = (product1, product2, options = {}) ->
    @adapter.perform 'create', product1, {}, (err, createdRecord1) =>
      throw err if err
      @adapter.perform 'create', product2, {}, (err, createdRecord2) =>
        throw err if err
        @adapter.perform 'readAll', product1.constructor.prototype, {}, (err, readProducts) ->
          throw err if err
          deepEqual t(readProducts), t([createdRecord1, createdRecord2])
          QUnit.start()

  asyncTestWithHooks 'reading many from storage: should callback with the records if they exist', 1, ->
    product1 = new @Product(name: "testA", cost: 20)
    product2 = new @Product(name: "testB", cost: 10)
    runReadMany.call @, product1, product2

  asyncTestWithHooks 'reading many from storage: should callback with subclass records if they exist', 1, ->
    class SpecialProduct extends @Product
    product1 = new SpecialProduct(name: "testA", cost: 20)
    product2 = new SpecialProduct(name: "testB", cost: 10)
    runReadMany.call @, product1, product2

  asyncTestWithHooks 'reading many from storage: should callback with the decoded records if they exist', 1, ->
    @Product.encode 'name',
      encode: (x) -> (x)
      decode: (x) -> x.toUpperCase()
    product1 = new @Product(name: "testA", cost: 20)
    product2 = new @Product(name: "testB", cost: 10)
    @adapter.perform 'create', product1, {}, (err, createdRecord1) =>
      throw err if err
      @adapter.perform 'create', product2, {}, (err, createdRecord2) =>
        throw err if err
        @adapter.perform 'readAll', @Product::, {}, (err, readProducts) ->
          throw err if err
          deepEqual t(readProducts), ['TESTA', 'TESTB']
          QUnit.start()

  asyncTestWithHooks 'reading many from storage: when given options should callback with the records if they exist', 1, ->
    product1 = new @Product(name: "testA", cost: 10)
    product2 = new @Product(name: "testB", cost: 10)
    @adapter.perform 'create', product1, {}, (err, createdRecord1) =>
      throw err if err
      @adapter.perform 'create', product2, {}, (err, createdRecord2) =>
        throw err if err
        @adapter.perform 'readAll', @Product::, {data: {cost: 10}}, (err, readProducts) ->
          throw err if err
          deepEqual t(readProducts), ['testA', 'testB']
          QUnit.start()

  asyncTestWithHooks 'reading many from storage: should callback with an empty array if no records exist', 1, ->
    @adapter.perform 'readAll', @Product::, {}, (err, readProducts) ->
      throw err if err
      deepEqual readProducts, []
      QUnit.start()

  runUpdate = (product) ->
    @adapter.perform 'create', product, {}, (err, createdRecord) =>
      throw err if err
      product.set('cost', 10)
      @adapter.perform 'update', product, {}, (err, updatedProduct) =>
        throw err if err
        @adapter.perform 'read', product, {}, (err, readProduct) ->
          throw err if err
          equal readProduct.get('cost', 10), 10
          QUnit.start()

  asyncTestWithHooks 'updating in storage: should callback with the record if it exists', 1, ->
    product = new @Product(name: "test 10")
    runUpdate.call(@, product)

  asyncTestWithHooks 'updating in storage: should callback with the subclass record if it exists', 1, ->
    class SpecialProduct extends @Product
    product = new SpecialProduct(name: "test 10")
    runUpdate.call(@, product)

  asyncTestWithHooks 'updating in storage: should callback with an error if the record hasn\'t been created', 1, ->
    product = new @Product(name: "test 11")
    @adapter.perform 'update', product, {}, (err, foundRecord) ->
      ok err
      QUnit.start()

  runDestroy = (product) ->
    @adapter.perform 'create', product, {}, (err, createdRecord) =>
      throw err if err
      @adapter.perform 'destroy', product, {}, (err) =>
        throw err if err
        @adapter.perform 'read', product, {}, (err, readProduct) =>
          ok err
          QUnit.start()

  asyncTestWithHooks 'destroying in storage: should succeed if the record exists', 1, ->
    product = new @Product(name: "test 12")
    runDestroy.call @, product

  asyncTestWithHooks 'destroying in storage: should succeed if the subclass record exists', 1, ->
    class SpecialProduct extends @Product
    product = new SpecialProduct(name: "test 13")
    runDestroy.call @, product

  asyncTestWithHooks 'destroying in storage: should callback with an error if the record hasn\'t been created', 1, ->
    product = new @Product(name: "test 14")
    @adapter.perform 'destroy', product, {}, (err, foundRecord) ->
      ok err
      QUnit.start()

if typeof exports is 'undefined'
  window.sharedStorageTestSuite = sharedStorageTestSuite
else
  exports.sharedStorageTestSuite = sharedStorageTestSuite

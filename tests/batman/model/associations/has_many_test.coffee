{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter, generateSorterOnProperty} = if typeof require isnt 'undefined' then require '../model_helper' else window
helpers = if typeof require is 'undefined' then window.viewHelpers else require '../../view/view_helper'

QUnit.module "Batman.Model hasMany Associations"
  setup: ->
    Batman.currentApp = null
    namespace = @namespace = {}

    namespace.Store = class @Store extends Batman.Model
      @encode 'id', 'name'
      @hasMany 'products', namespace: namespace

    @storeAdapter = createStorageAdapter @Store, AsyncTestStorageAdapter,
      stores1:
        name: "Store One"
        id: 1

    namespace.Product = class @Product extends Batman.Model
      @encode 'id', 'name'
      @belongsTo 'store', namespace: namespace
      @hasMany 'productVariants', namespace: namespace

    @productAdapter = createStorageAdapter @Product, AsyncTestStorageAdapter,
      products1:
        name: "Product One"
        id: 1
        store_id: 1
      products2:
        name: "Product Two"
        id: 2
        store_id: 1
      products3:
        name: "Product Three"
        id: 3
        store_id: 1
        productVariants: [{
          id:5
          price:50
          product_id:3
        },{
          id:6
          price:60
          product_id:3
        }]

    namespace.ProductVariant = class @ProductVariant extends Batman.Model
      @encode 'id', 'price'
      @belongsTo 'product', namespace: namespace

    @variantsAdapter = createStorageAdapter @ProductVariant, AsyncTestStorageAdapter,
      product_variants5:
        id:5
        price:50
        product_id:3
      product_variants6:
        id:6
        price:60
        product_id:3

asyncTest "hasMany associations are loaded", 4, ->
  @Store.find 1, (err, store) =>
    throw err if err
    products = store.get 'products'
    delay =>
      products.forEach (product) => ok product instanceof @Product
      deepEqual products.map((x) -> x.get('id')), [1,2,3]

asyncTest "AssociationSet fires loaded event", 1, ->
  @Store.find 1, (err, store) ->
    store.get('products').on 'loaded', ->
      ok true, 'loaded fired'
      QUnit.start()

asyncTest "hasMany associations are loaded using encoders", 1, ->
  @Product.encode 'name'
    encode: (x) -> x
    decode: (x) -> x.toUpperCase()

  @Store.find 1, (err, store) =>
    throw err if err
    products = store.get 'products'
    delay ->
      deepEqual products.map((x) -> x.get('name')), ["PRODUCT ONE", "PRODUCT TWO", "PRODUCT THREE"]

asyncTest "embedded hasMany associations are loaded using encoders", 1, ->
  @ProductVariant.encode 'price'
    encode: (x) -> x
    decode: (x) -> x * 100

  @Product.find 3, (err, product) =>
    throw err if err
    variants = product.get('productVariants')
    deepEqual variants.map((x) -> x.get('price')), [5000, 6000]
    QUnit.start()

asyncTest "hasMany associations are not loaded when autoload is false", 1, ->
  ns = @namespace
  class Store extends Batman.Model
    @encode 'id', 'name'
    @hasMany 'products', {namespace: ns, autoload: false}

  storeAdapter = createStorageAdapter Store, AsyncTestStorageAdapter,
    stores1:
      name: "Store One"
      id: 1

  Store.find 1, (err, store) =>
    throw err if err
    products = store.get 'products'
    delay =>
      equal products.length, 0

asyncTest "hasMany associations can be reloaded", 8, ->
  loadSpy = spyOn(@Product, 'load')
  @Store.find 1, (err, store) =>
    throw err if err
    products = store.get('products')
    ok !products.loaded
    setTimeout =>
      ok products.loaded
      equal loadSpy.callCount, 1

      products.load (err, products) =>
        throw err if err
        equal loadSpy.callCount, 2
        products.forEach (product) => ok product instanceof @Product
        deepEqual products.map((x) -> x.get('id')), [1,2,3]
        QUnit.start()
    , ASYNC_TEST_DELAY

asyncTest "hasMany associations are saved via the parent model", 5, ->
  store = new @Store name: 'Zellers'
  product1 = new @Product name: 'Gizmo'
  product2 = new @Product name: 'Gadget'
  store.set 'products', new Batman.Set(product1, product2)

  storeSaveSpy = spyOn store, 'save'
  store.save (err, record) =>
    throw err if err
    equal storeSaveSpy.callCount, 1
    equal product1.get('store_id'), record.id
    equal product2.get('store_id'), record.id

    @Store.find record.id, (err, store2) =>
      throw err if err
      storedJSON = @storeAdapter.storage["stores#{record.id}"]
      deepEqual store2.toJSON(), storedJSON
      # hasMany saves inline by default
      sorter = generateSorterOnProperty('name')

      deepEqual sorter(storedJSON.products), sorter([
        {name: "Gizmo", store_id: record.id, productVariants: []}
        {name: "Gadget", store_id: record.id, productVariants: []}
      ])
      QUnit.start()

asyncTest "hasMany associations are saved via the child model", 2, ->
  @Store.find 1, (err, store) =>
    throw err if err
    product = new @Product name: 'Gizmo'
    product.set 'store', store
    product.save (err, savedProduct) ->
      equal savedProduct.get('store_id'), store.id
      products = store.get('products')
      ok products.has(savedProduct)
      QUnit.start()

asyncTest "hasMany association can be loaded from JSON data", 14, ->
  @Product.find 3, (err, product) =>
    throw err if err
    variants = product.get('productVariants')
    ok variants instanceof Batman.AssociationSet
    equal variants.length, 2

    variant5 = variants.toArray()[0]
    ok variant5 instanceof @ProductVariant
    equal variant5.get('id'), 5
    equal variant5.get('price'), 50
    equal variant5.get('product_id'), 3
    proxiedProduct = variant5.get('product')
    equal proxiedProduct.get('id'), product.get('id')
    equal proxiedProduct.get('name'), product.get('name')

    variant6 = variants.toArray()[1]
    ok variant6 instanceof @ProductVariant
    equal variant6.get('id'), 6
    equal variant6.get('price'), 60
    equal variant6.get('product_id'), 3
    proxiedProduct = variant6.get('product')
    equal proxiedProduct.get('id'), product.get('id')
    equal proxiedProduct.get('name'), product.get('name')

    QUnit.start()

asyncTest "hasMany associations loaded from JSON should be reloadable", 2, ->
  @Product.find 3, (err, product) =>
    throw err if err
    variants = product.get('productVariants')
    ok variants instanceof Batman.AssociationSet
    variants.load (err, newVariants) =>
      throw err if err
      equal newVariants.length, 2
      QUnit.start()

asyncTest "hasMany associations loaded from JSON should index the loaded set like normal associations", 3, ->
  @Product.find 3, (err, product) =>
    throw err if err
    variants = product.get('productVariants')
    ok variants instanceof Batman.AssociationSet
    equal variants.get('length'), 2
    variant = new @ProductVariant(product_id: 3, name: "Test Variant")
    variant.save (err) ->
      throw err if err
      equal variants.get('length'), 3
      QUnit.start()

asyncTest "hasMany child models are added to the identity map", 2, ->
  equal @ProductVariant.get('loaded').length, 0
  @Product.find 3, (err, product) =>
    equal @ProductVariant.get('loaded').length, 2
    QUnit.start()

asyncTest "unsaved hasMany models should accept associated children", 2, ->
  product = new @Product
  variants = product.get('productVariants')
  delay =>
    equal variants.length, 0
    variant = new @ProductVariant
    variants.add variant
    equal variants.length, 1

asyncTest "unsaved hasMany models should save their associated children", 4, ->
  product = new @Product(name: "Hello!")
  variants = product.get('productVariants')
  variant = new @ProductVariant(price: 100)
  variants.add variant

  # Mock out what a realbackend would do: assign ids to the child records
  # The TestStorageAdapter is smart enough to do this for the parent, but not the children.
  @productAdapter.create = (record, options, callback) ->
    id = record.set('id', @counter++)
    if id
      @storage[@storageKey(record) + id] = record.toJSON()
      record.fromJSON
        id: id
        productVariants: [{
          price: 100
          id: 11
        }]
      callback(undefined, record)
    else
      callback(new Error("Couldn't get record primary key."))

  product.save (err, product) =>
    throw err if err
    storedJSON = @productAdapter.storage["products#{product.get('id')}"]
    deepEqual storedJSON,
      id: 11
      name: "Hello!"
      productVariants:[
        {price: 100, product_id: product.get('id')}
      ]

    ok !product.isNew()
    ok !variant.isNew()
    equal variant.get('product_id'), product.get('id')
    QUnit.start()

asyncTest "unsaved hasMany models should reflect their associated children after save", 3, ->
  product = new @Product(name: "Hello!")
  variants = product.get('productVariants')
  variant = new @ProductVariant(price: 100)
  variants.add variant

  # Mock out what a realbackend would do: assign ids to the child records
  # The TestStorageAdapter is smart enough to do this for the parent, but not the children.
  @productAdapter.create = (record, options, callback) ->
    id = record.set('id', @counter++)
    if id
      @storage[@storageKey(record) + id] = record.toJSON()
      record.fromJSON
        id: id
        productVariants: [{
          price: 100
          id: 11
        }]
      callback(undefined, record)
    else
      callback(new Error("Couldn't get record primary key."))

  product.save (err, product) =>
    throw err if err
    # Mock out what a realbackend would do: assign ids to the child records
    # The TestStorageAdapter is smart enough to do this for the parent, but not the children.
    equal product.get('productVariants.length'), 1
    ok product.get('productVariants').has(variant)
    equal variants.get('length'), 1
    QUnit.start()

asyncTest "hasMany associations render", 4, ->
  @Store.find 1, (err, store) =>
    throw err if err
    source = '<div><span data-foreach-product="store.products" data-bind="product.name"></span></div>'
    context = Batman(store: store)
    helpers.render source, context, (node, view) =>
      setTimeout =>
        equal node.children().get(0)?.innerHTML, 'Product One'
        equal node.children().get(1)?.innerHTML, 'Product Two'
        equal node.children().get(2)?.innerHTML, 'Product Three'

        addedProduct = new @Product(name: 'Product Four', store_id: store.id)
        addedProduct.save (err, savedProduct) ->
          delay ->
            equal node.children().get(3)?.innerHTML, 'Product Four'
      , ASYNC_TEST_DELAY * 2

asyncTest "hasMany adds new related model instances to its set", ->
  @Store.find 1, (err, store) =>
    throw err if err
    addedProduct = new @Product(name: 'Product Four', store_id: store.id)
    addedProduct.save (err, savedProduct) =>
      ok store.get('products').has(savedProduct)
      QUnit.start()

asyncTest "hasMany loads records for each parent instance", 2, ->
  @storeAdapter.storage["stores2"] =
    name: "Store Two"
    id: 2
  @productAdapter.storage["products4"] =
    name: "Product Four"
    id: 4
    store_id: 2

  @Store.find 1, (err, store) =>
    throw err if err
    products = store.get('products')
    setTimeout =>
      equal products.length, 3
      @Store.find 2, (err, store2) =>
        throw err if err
        products2 = store2.get('products')
        delay =>
          equal products2.length, 1
    , ASYNC_TEST_DELAY

asyncTest "hasMany loads after an instance of the related model is saved locally", 2, ->
  product = new @Product
    name: "Local product"
    store_id: 1

  product.save (err, savedProduct) =>
    throw err if err
    @Store.find 1, (err, store) ->
      throw err if err
      products = store.get('products')
      ok products.has(savedProduct)
      delay ->
        equal products.length, 4

asyncTest "hasMany supports custom foreign keys", 1, ->
  namespace = @
  class Shop extends Batman.Model
    @encode 'id', 'name'
    @hasMany 'products', {namespace: namespace, foreignKey: 'store_id'}

  shopAdapter = createStorageAdapter Shop, AsyncTestStorageAdapter,
    'shops1':
      id: 1
      name: 'Shop One'

  Shop.find 1, (err, shop) ->
    products = shop.get('products')
    delay ->
      equal products.length, 3

QUnit.module "Batman.Model hasMany Associations with inverse of"
  setup: ->
    namespace = {}

    namespace.Product = class @Product extends Batman.Model
      @encode 'id', 'name'
      @hasMany 'productVariants', {namespace: namespace, inverseOf: 'product'}

    @productAdapter = createStorageAdapter @Product, AsyncTestStorageAdapter,
      products1:
        name: "Product One"
        id: 1
        productVariants: [{
          id:5
          price:50
        },{
          id:6
          price:60
        }]

    namespace.ProductVariant = class @ProductVariant extends Batman.Model
      @encode 'price'
      @belongsTo 'product', namespace: namespace

    @variantsAdapter = createStorageAdapter @ProductVariant, AsyncTestStorageAdapter,
      product_variants5:
        id:5
        price:50
      product_variants6:
        id:6
        price:60

asyncTest "hasMany sets the foreign key on the inverse relation if the children haven't been loaded", 3, ->
  @Product.find 1, (err, product) =>
    throw err if err
    variants = product.get('productVariants')
    delay ->
      variants = variants.toArray()
      equal variants.length, 2
      ok variants[0].get('product') == product
      ok variants[1].get('product') == product

asyncTest "hasMany sets the foreign key on the inverse relation if the children have already been loaded", 3, ->
  @ProductVariant.load (err, variants) =>
    throw err if err
    @Product.find 1, (err, product) =>
      throw err if err
      variants = product.get('productVariants')
      delay ->
        variants = variants.toArray()
        equal variants.length, 2
        ok variants[0].get('product') == product
        ok variants[1].get('product') == product

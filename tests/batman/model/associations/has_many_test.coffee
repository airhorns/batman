{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter} = if typeof require isnt 'undefined' then require '../model_helper' else window
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
      @encode 'id', 'name', 'store_id'
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
      @encode 'price'
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
    products = store.get 'products'
    delay =>
      products.forEach (product) => ok product instanceof @Product
      deepEqual products.map((x) -> x.get('id')), [1,2,3]

asyncTest "hasMany associations are loaded using encoders", 1, ->
  @Product.encode 'name'
    encode: (x) -> x
    decode: (x) -> x.toUpperCase()

  @Store.find 1, (err, store) =>
    products = store.get 'products'
    delay ->
      deepEqual products.map((x) -> x.get('name')), ["PRODUCT ONE", "PRODUCT TWO", "PRODUCT THREE"]

asyncTest "embedded hasMany associations are loaded using encoders", 1, ->
  @ProductVariant.encode 'price'
    encode: (x) -> x
    decode: (x) -> x * 100

  @Product.find 3, (err, product) =>
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
    store
    products = store.get 'products'
    delay =>
      equal products.length, 0

asyncTest "hasMany associations can be reloaded", 4, ->
  @Store.find 1, (err, store) =>
    store.get('products').load (error, products) =>
      throw error if error
      products.forEach (product) => ok product instanceof @Product
      deepEqual products.map((x) -> x.get('id')), [1,2,3]
      QUnit.start()

asyncTest "hasMany associations are saved via the parent model", 5, ->
  store = new @Store name: 'Zellers'
  product1 = new @Product name: 'Gizmo'
  product2 = new @Product name: 'Gadget'
  store.set 'products', new Batman.Set(product1, product2)

  storeSaveSpy = spyOn store, 'save'
  store.save (err, record) =>
    equal storeSaveSpy.callCount, 1
    equal product1.get('store_id'), record.id
    equal product2.get('store_id'), record.id

    @Store.find record.id, (err, store2) =>
      storedJSON = @storeAdapter.storage["stores#{record.id}"]
      deepEqual store2.toJSON(), storedJSON
      # hasMany saves inline by default
      deepEqual storedJSON.products, [
        {name: "Gizmo", store_id: record.id}
        {name: "Gadget", store_id: record.id}
      ]
      QUnit.start()

asyncTest "hasMany associations are saved via the child model", 2, ->
  @Store.find 1, (err, store) =>
    product = new @Product name: 'Gizmo'
    product.set 'store', store
    product.save (err, savedProduct) ->
      equal savedProduct.get('store_id'), store.id
      products = store.get('products')
      ok products.has(savedProduct)
      QUnit.start()

asyncTest "hasMany association can be loaded from JSON data", 14, ->
  @Product.find 3, (err, product) =>
    variants = product.get('productVariants')
    ok variants instanceof Batman.Set
    equal variants.length, 2

    variant5 = variants.toArray()[0]
    ok variant5 instanceof @ProductVariant
    equal variant5.id, 5
    equal variant5.get('price'), 50
    equal variant5.get('product_id'), 3
    proxiedProduct = variant5.get('product')
    equal proxiedProduct.get('id'), product.get('id')
    equal proxiedProduct.get('name'), product.get('name')

    variant6 = variants.toArray()[1]
    ok variant6 instanceof @ProductVariant
    equal variant6.id, 6
    equal variant6.get('price'), 60
    equal variant6.get('product_id'), 3
    proxiedProduct = variant6.get('product')
    equal proxiedProduct.get('id'), product.get('id')
    equal proxiedProduct.get('name'), product.get('name')

    QUnit.start()

asyncTest "hasMany child models are added to the identity map", 1, ->
  @Product.find 3, (err, product) =>
    equal @ProductVariant.get('loaded').length, 2
    QUnit.start()

asyncTest "hasMany associations render", 4, ->
  @Store.find 1, (err, store) =>
    source = '<div><span data-foreach-product="store.products" data-bind="product.name"></span></div>'
    context = Batman(store: store)
    helpers.render source, context, (node, view) =>
      equal node.children().get(0)?.innerHTML, 'Product One'
      equal node.children().get(1)?.innerHTML, 'Product Two'
      equal node.children().get(2)?.innerHTML, 'Product Three'

      addedProduct = new @Product(name: 'Product Four', store_id: store.id)
      addedProduct.save (err, savedProduct) ->
        delay ->
          equal node.children().get(3)?.innerHTML, 'Product Four'

asyncTest "hasMany adds new related model instances to its set", ->
  @Store.find 1, (err, store) =>
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
    products = store.get('products')
    equal products.length, 3
    @Store.find 2, (err, store2) =>
      products2 = store2.get('products')
      equal products2.length, 1
      QUnit.start()

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
      equal variants[0].get('product'), product
      equal variants[1].get('product'), product

asyncTest "hasMany sets the foreign key on the inverse relation if the children have already been loaded", 3, ->
  @ProductVariant.load (err, variants) =>
    throw err if err
    @Product.find 1, (err, product) =>
      throw err if err
      variants = product.get('productVariants')
      delay ->
        variants = variants.toArray()
        equal variants.length, 2
        equal variants[0].get('product'), product
        equal variants[1].get('product'), product


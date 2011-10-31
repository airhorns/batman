{TestStorageAdapter, AsyncTestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window
helpers = if typeof require is 'undefined' then window.viewHelpers else require '../view/view_helper'

QUnit.module "Associations"

asyncTest "support custom model namespaces", 2, ->
  namespace = {}
  class namespace.Store extends Batman.Model

  class Product extends Batman.Model
    @belongsTo 'store', namespace
  productAdapter = new AsyncTestStorageAdapter Product
  productAdapter.storage =
    'products2': {name: "Product Two", id: 2, store: {id:3, name:"JSON Store"}}
  Product.persist productAdapter

  Product.find 2, (err, product) ->
    store = product.get('store')
    ok store instanceof namespace.Store
    equal store.get('id'), 3
    QUnit.start()

asyncTest "work with model classes that haven't been loaded yet", ->
  namespace = this
  class @Blog extends Batman.Model
    @encode 'id', 'name'
    @hasOne 'customer', namespace
  blogAdapter = new AsyncTestStorageAdapter @Blog
  blogAdapter.storage = 'blogs1': {name: "Blog One", id: 1}
  @Blog.persist blogAdapter

  setTimeout (=>
    class @Customer extends Batman.Model
      @encode 'id', 'name'
    customerAdapter = new AsyncTestStorageAdapter @Customer
    customerAdapter.storage =
      'customer1': {name: "Customer One", id: 1, blog_id: 1}
    @Customer.persist customerAdapter

    @Blog.find 1, (err, blog) =>
      customer = blog.get 'customer'
      ok customer instanceof @Customer
      equal customer.get('id'), 1
      equal customer.get('name'), 'Customer One'
      QUnit.start()
  ), ASYNC_TEST_DELAY

asyncTest "models can save while related records are loading", 1, ->
  namespace = this
  class @Store extends Batman.Model
    @hasOne 'product', namespace
  storeAdapter = new AsyncTestStorageAdapter @Store
  storeAdapter.storage =
    "stores1": {id: 1, name: "Store One", product: {id: 1, name: "JSON product"}}
  @Store.persist storeAdapter

  class @Product extends Batman.Model
  productAdapter = new AsyncTestStorageAdapter @Product
  productAdapter.storage = {"products500": {id:500}}
  @Product.persist productAdapter

  @Store.find 1, (err, store) ->
    product = store.get 'product'
    product._batman.state = 'loading'
    store.save (err, savedStore) ->
      ok !err
      QUnit.start()

QUnit.module "belongsTo Associations"
  setup: ->
    namespace = this
    class @Store extends Batman.Model
      @encode 'id', 'name'
    @storeAdapter = new AsyncTestStorageAdapter @Store
    @storeAdapter.storage =
      'stores1': {name: "Store One", id: 1}
      'stores2': {name: "Store Two", id: 2, product: {id:3, name:"JSON Product"}}
    @Store.persist @storeAdapter

    class @Product extends Batman.Model
      @encode 'id', 'name'
      @belongsTo 'store', namespace
    @productAdapter = new AsyncTestStorageAdapter @Product
    @productAdapter.storage = 'products1': {name: "Product One", id: 1, store_id: 1}
    @Product.persist @productAdapter

asyncTest "belongsTo yields the related model when toJSON is called", 1, ->
  @Product.find 1, (err, product) =>
    storeJSON = product.get('store').toJSON()
    # store will encode its product
    delete storeJSON.product

    deepEqual storeJSON, @storeAdapter.storage["stores1"]
    QUnit.start()

asyncTest "belongsTo associations are loaded via ID", 2, ->
  @Product.find 1, (err, product) =>
    store = product.get 'store'
    ok store instanceof @Store
    equal store.id, 1
    QUnit.start()

asyncTest "belongsTo associations are saved", 6, ->
  store = new @Store name: 'Zellers'
  product = new @Product name: 'Gizmo'
  product.set 'store', store

  productSaveSpy = spyOn product, 'save'
  product.save (err, record) =>
    equal productSaveSpy.callCount, 1
    equal record.get('store_id'), store.id
    storedJSON = @productAdapter.storage["products#{record.id}"]
    deepEqual storedJSON, product.toJSON()

    store = record.get('store')
    equal storedJSON.store_id, undefined
    deepEqual storedJSON.store, store.toJSON()

    @Product.find record.get('id'), (err, product2) ->
      deepEqual product2.toJSON(), storedJSON 
      QUnit.start()

asyncTest "belongsTo associations render", 1, ->
  @Product.find 1, (err, product) ->
    source = '<span data-bind="product.store.name"></span>'
    context = Batman(product: product)
    helpers.render source, context, (node) =>
      equal node[0].innerHTML, 'Store One'
      QUnit.start()

QUnit.module "hasOne Associations"
  setup: ->
    namespace = this
    class @Store extends Batman.Model
      @encode 'id', 'name'
      @hasOne 'product', namespace
    @storeAdapter = new AsyncTestStorageAdapter @Store
    @storeAdapter.storage =
      'stores1': {name: "Store One", id: 1}
      'stores2': {name: "Store Two", id: 2, product: {id:3, name:"JSON Product"}}
    @Store.persist @storeAdapter

    class @Product extends Batman.Model
      @encode 'id', 'name'
    @productAdapter = new AsyncTestStorageAdapter @Product
    @productAdapter.storage = 'products1': {name: "Product One", id: 1, store_id: 1}
    @Product.persist @productAdapter

asyncTest "hasOne yields the related model when toJSON is called", 1, ->
  @Store.find 1, (err, store) =>
    deepEqual store.toJSON().product, @productAdapter.storage['products1']
    QUnit.start()

asyncTest "hasOne associations are loaded via ID", 2, ->
  @Store.find 1, (err, store) =>
    product = store.get 'product'
    ok product instanceof @Product
    equal product.id, 1
    QUnit.start()

asyncTest "hasOne associations are loaded via JSON", 3, ->
  @Store.find 2, (err, store) =>
    product = store.get 'product'
    ok product instanceof @Product
    equal product.get('id'), 3
    equal product.get('name'), "JSON Product"
    QUnit.start()

asyncTest "hasOne associations are saved", 5, ->
  store = new @Store name: 'Zellers'
  product = new @Product name: 'Gizmo'
  store.set 'product', product

  storeSaveSpy = spyOn store, 'save'
  store.save (err, record) =>
    equal storeSaveSpy.callCount, 1
    equal product.get('store_id'), record.id

    storedJSON = @storeAdapter.storage["stores#{record.id}"]
    deepEqual storedJSON, store.toJSON()
    deepEqual storedJSON.product,
      name: "Gizmo"
      store_id: record.id

    @Store.find record.get('id'), (err, store2) =>
      deepEqual store2.toJSON(), storedJSON
      QUnit.start()

asyncTest "hasOne associations render", 1, ->
  @Store.find 1, (err, store) ->
    source = '<span data-bind="store.product.name"></span>'
    context = Batman(store: store)
    helpers.render source, context, (node) ->
      equal node[0].innerHTML, 'Product One'
      QUnit.start()

QUnit.module "hasMany Associations"
  setup: ->
    namespace = this

    class @Store extends Batman.Model
      @encode 'id', 'name'
      @hasMany 'products', namespace
    @storeAdapter = new AsyncTestStorageAdapter @Store
    @storeAdapter.storage =
      'stores1': {name: "Store One", id: 1}
    @Store.persist @storeAdapter

    class @Product extends Batman.Model
      @encode 'id', 'name', 'store_id'
      @belongsTo 'store', namespace
      @hasMany 'productVariants', namespace
    @productAdapter = new AsyncTestStorageAdapter @Product
    @productAdapter.storage =
      'products1': {name: "Product One", id: 1, store_id: 1}
      'products2': {name: "Product Two", id: 2, store_id: 1}
      'products3':
        name: "Product Three",
        id: 3,
        store_id: 1,
        productVariants: [
          {id:5, price:50, product_id:3},
          {id:6, price:60, product_id:3}
        ]
    @Product.persist @productAdapter

    class @ProductVariant extends Batman.Model
      @encode 'price'
      @belongsTo 'product', namespace
    variantAdapter = new AsyncTestStorageAdapter @ProductVariant
    @ProductVariant.persist variantAdapter

asyncTest "hasMany associations are loaded", 6, ->
  @Store.find 1, (err, store) =>
    products = store.get 'products'
    delay =>
      trackedIds = {1: no, 2: no, 3: no}
      products.forEach (product) =>
        ok product instanceof @Product
        trackedIds[product.id] = true
      equal trackedIds[1], yes
      equal trackedIds[2], yes
      equal trackedIds[3], yes

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

    storedJSON = @storeAdapter.storage["stores#{record.id}"]
    deepEqual storedJSON.products, 
      [{name: "Gizmo", store_id: record.id},
       {name: "Gadget", store_id: record.id}]

    @Store.find record.get('id'), (err, store2) ->
      deepEqual store2.toJSON(), storedJSON
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

asyncTest "hasMany association can be loaded from JSON data", 12, ->
  @Product.find 3, (err, product) =>
    variants = product.get('productVariants')
    ok variants instanceof Batman.Set
    equal variants.length, 2

    variant5 = variants.toArray()[0]
    ok variant5 instanceof @ProductVariant
    equal variant5.id, 5
    equal variant5.get('price'), 50
    equal variant5.get('product_id'), 3
    equal variant5.get('product'), product

    variant6 = variants.toArray()[1]
    ok variant6 instanceof @ProductVariant
    equal variant6.id, 6
    equal variant6.get('price'), 60
    equal variant6.get('product_id'), 3
    equal variant6.get('product'), product

    QUnit.start()

asyncTest "hasMany associations render", 3, ->
  @Store.find 1, (err, store) ->
    source = '<div><span data-foreach-product="store.products" data-bind="product.name"></span></div>'
    context = Batman(store: store)
    helpers.render source, context, (node) ->
      equal node.children().get(0).innerHTML, 'Product One'
      equal node.children().get(1).innerHTML, 'Product Two'
      equal node.children().get(2).innerHTML, 'Product Three'
      QUnit.start()


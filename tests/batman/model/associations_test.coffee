{TestStorageAdapter, AsyncTestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window
helpers = if typeof require is 'undefined' then window.viewHelpers else require '../view/view_helper'

QUnit.module "Batman.Model One-To-One Associations"
  setup: ->
    class @App extends Batman.App
    class @App.Store extends Batman.Model
      @encode 'id', 'name'
      @hasOne 'product'

    @storeAdapter = new AsyncTestStorageAdapter @App.Store
    @storeAdapter.storage =
      'stores1': {name: "Store One", id: 1}
    @App.Store.persist @storeAdapter

    class @App.Product extends Batman.Model
      @encode 'id', 'name'
      @belongsTo 'store'

    @productAdapter = new AsyncTestStorageAdapter @App.Product
    @productAdapter.storage = 'products1': {name: "Product One", id: 1, store_id: 1}
    @App.Product.persist @productAdapter

    @App.run()

asyncTest "should work with model classes that haven't been loaded yet", ->
  class @App.Blog extends Batman.Model
    @encode 'id', 'name'
    @hasOne 'customer'
  blogAdapter = new AsyncTestStorageAdapter @App.Blog
  blogAdapter.storage =
    'blogs1': {name: "Blog One", id: 1}
  @App.Blog.persist blogAdapter

  setTimeout (=>
    class @App.Customer extends Batman.Model
      @encode 'id', 'name'
    customerAdapter = new AsyncTestStorageAdapter @App.Customer
    customerAdapter.storage =
      'customer1': {name: "Customer One", id: 1, blog_id: 1}
    @App.Customer.persist customerAdapter

    @App.Blog.find 1, (err, blog) =>
      customer = blog.get 'customer'
      ok customer instanceof @App.Customer
      equal customer.get('id'), 1
      equal customer.get('name'), 'Customer One'
      QUnit.start()
  ), ASYNC_TEST_DELAY

asyncTest "belongsTo associations are loaded", 2, ->
  @App.Product.find 1, (err, product) =>
    store = product.get 'store'
    ok store instanceof @App.Store
    equal store.id, 1
    QUnit.start()

asyncTest "belongsTo associations are saved", 2, ->
  store = new @App.Store name: 'Zellers'
  product = new @App.Product name: 'Gizmo'
  product.set 'store', store

  productSaveSpy = spyOn product, 'save'
  product.save (err, record) ->
    equal productSaveSpy.callCount, 1
    equal record.get('store_id'), store.id
    QUnit.start()

asyncTest "hasOne associations are loaded", 2, ->
  @App.Store.find 1, (err, store) =>
    product = store.get 'product'
    ok product instanceof @App.Product
    equal product.id, 1
    QUnit.start()

asyncTest "hasOne associations are saved", 2, ->
  store = new @App.Store name: 'Zellers'
  product = new @App.Product name: 'Gizmo'
  store.set 'product', product

  storeSaveSpy = spyOn store, 'save'
  store.save (err, record) ->
    equal storeSaveSpy.callCount, 1
    equal product.get('store_id'), record.id
    QUnit.start()

asyncTest "hasOne associations can be destroyed safely", 2, ->
  @App.Store.find 1, (err, store) =>
    @App.Product.find 1, (err, product) ->
      store.destroy()
      equal product.get('store_id'), undefined
      equal product._batman.attributes['store'], undefined
      QUnit.start()

asyncTest "Models can save while related records are loading", 1, ->
  @App.Store.find 1, (err, store) ->
    product = store.get 'product'
    product._batman.state = 'loading'
    store.save (err, savedStore) ->
      ok !err
      QUnit.start()

asyncTest "hasOne association can be loaded from JSON", 3, ->
  @storeAdapter.storage['stores2'] =
    name: 'Two'
    id: 2
    product: '{"id": 5, "name": "JSON product"}'

  @App.Store.find 2, (err, store) =>
    product = store._batman.attributes.product
    ok product instanceof @App.Product
    equal product.get('id'), 5
    equal product.get('name'), "JSON product"
    QUnit.start()

asyncTest "belongsTo association can be loaded from JSON", ->
  @productAdapter.storage['products2'] =
    name: 'Two'
    id: 2
    store: '{"id": 5, "name": "JSON store"}'

  @App.Product.find 2, (err, product) =>
    store = product._batman.attributes.store
    ok store instanceof @App.Store
    equal store.get('id'), 5
    equal store.get('name'), "JSON store"
    QUnit.start()

asyncTest "belongsTo associations render", 1, ->
  @App.Product.find 1, (err, product) ->
    source = '<span data-bind="product.store.name"></span>'
    context = Batman(product: product)
    helpers.render source, context, (node) =>
      equal node[0].innerHTML, 'Store One'
      QUnit.start()

asyncTest "hasOne associations render", 1, ->
  @App.Store.find 1, (err, store) ->
    source = '<span data-bind="store.product.name"></span>'
    context = Batman(store: store)
    helpers.render source, context, (node) ->
      equal node[0].innerHTML, 'Product One'
      QUnit.start()

QUnit.module "Batman.Model One-To-Many Associations"
  setup: ->
    class @App extends Batman.App

    class @App.Store extends Batman.Model
      @encode 'id', 'name'
      @hasMany 'products'

    @storeAdapter = new AsyncTestStorageAdapter @App.Store
    @storeAdapter.storage =
      'stores1': {name: "Store One", id: 1}
    @App.Store.persist @storeAdapter

    class @App.Product extends Batman.Model
      @encode 'id', 'name', 'store_id'
      @belongsTo 'store'
      @hasMany 'productVariants'

    @productAdapter = new AsyncTestStorageAdapter @App.Product
    @productAdapter.storage =
      'products1': {name: "Product One", id: 1, store_id: 1}
      'products2': {name: "Product Two", id: 2, store_id: 1}
      'products3': {name: "Product Three", id: 3, store_id: 1, productVariants: '{"productvariants5":{"price":50,"product_id":3},"productvariants6":{"price":60,"product_id":3}}'
      }
    @App.Product.persist @productAdapter

    class @App.ProductVariant extends Batman.Model
      @encode 'price'
      @belongsTo 'product'
    variantAdapter = new AsyncTestStorageAdapter @App.ProductVariant
    @App.ProductVariant.persist variantAdapter

    @App.run()

asyncTest "hasMany associations are loaded", 6, ->
  @App.Store.find 1, (err, store) =>
    products = store.get 'products'
    trackedIds = {1: no, 2: no, 3: no}
    products.forEach (product) =>
      ok product instanceof @App.Product
      trackedIds[product.id] = true
    equal trackedIds[1], yes
    equal trackedIds[2], yes
    equal trackedIds[3], yes
    QUnit.start()

asyncTest "hasMany associations are saved via the parent model", 3, ->
  store = new @App.Store name: 'Zellers'
  product1 = new @App.Product name: 'Gizmo'
  product2 = new @App.Product name: 'Gadget'
  store.set 'products', new Batman.Set(product1, product2)

  storeSaveSpy = spyOn store, 'save'
  store.save (err, record) ->
    equal storeSaveSpy.callCount, 1
    equal product1.get('store_id'), record.id
    equal product2.get('store_id'), record.id
    QUnit.start()

asyncTest "hasMany associations are saved via the child model", 2, ->
  @App.Store.find 1, (err, store) =>
    product = new @App.Product name: 'Gizmo'
    product.set 'store', store
    product.save (err, savedProduct) ->
      equal savedProduct.get('store_id'), store.id
      products = store.get('products')
      ok products.has(savedProduct)
      QUnit.start()

asyncTest "hasMany associations can be destroyed safely", 6, ->
  @App.Store.find 1, (err, store) =>
    products = store.get('products')
    store.destroy()
    products.forEach (product) =>
      equal product.get('store_id'), undefined
      equal product._batman.attributes['store'], undefined
    QUnit.start()

asyncTest "hasMany association can be loaded from JSON data", 12, ->
  @App.Product.find 3, (err, product) =>
    variants = product.get('productVariants')
    ok variants instanceof Batman.Set
    equal variants.length, 2

    variant5 = variants.toArray()[0]
    ok variant5 instanceof @App.ProductVariant
    equal variant5.id, 5
    equal variant5.get('price'), 50
    equal variant5.get('product_id'), 3
    equal variant5.get('product'), product

    variant6 = variants.toArray()[1]
    ok variant6 instanceof @App.ProductVariant
    equal variant6.id, 6
    equal variant6.get('price'), 60
    equal variant6.get('product_id'), 3
    equal variant6.get('product'), product

    QUnit.start()

asyncTest "hasMany associations render", 3, ->
  @App.Store.find 1, (err, store) ->
    source = '<div><span data-foreach-product="store.products" data-bind="product.name"></span></div>'
    context = Batman(store: store)
    helpers.render source, context, (node) ->
      equal node.children().get(0).innerHTML, 'Product One'
      equal node.children().get(1).innerHTML, 'Product Two'
      equal node.children().get(2).innerHTML, 'Product Three'
      QUnit.start()


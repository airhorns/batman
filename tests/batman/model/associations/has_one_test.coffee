{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter} = if typeof require isnt 'undefined' then require '../model_helper' else window
helpers = if typeof require is 'undefined' then window.viewHelpers else require '../../view/view_helper'

QUnit.module "Batman.Model hasOne Associations"
  setup: ->
    namespace = @namespace = {}

    class @Store extends Batman.Model
      @encode 'id', 'name'
      @hasOne 'product', namespace: namespace

    @storeAdapter = createStorageAdapter @Store, AsyncTestStorageAdapter,
      'stores1': {name: "Store One", id: 1}
      'stores2': {name: "Store Two", id: 2, product: {id:3, name:"JSON Product"}}

    namespace.Product = class @Product extends Batman.Model
      @encode 'id', 'name'
      @belongsTo 'store'

    @productAdapter = createStorageAdapter @Product, AsyncTestStorageAdapter,
      'products1': {name: "Product One", id: 1, store_id: 1}
      'products3': {name: "JSON Product", id: 3, store_id: 2}

asyncTest "hasOne associations are loaded via ID", 2, ->
  @Store.find 1, (err, store) =>
    product = store.get 'product'
    delay ->
      equal product.get('id'), 1
      equal product.get('name'), 'Product One'

asyncTest "hasOne associations are not loaded when autoload is false", 2, ->
  ns = @namespace
  class Store extends Batman.Model
    @encode 'id', 'name'
    @hasOne 'product', {namespace: ns, autoload: false}

  storeAdapter = createStorageAdapter Store, AsyncTestStorageAdapter,
    'stores1': {name: "Store One", id: 1}
    'stores2': {name: "Store Two", id: 2, product: {id:3, name:"JSON Product"}}

  Store.find 1, (err, store) =>
    product = store.get 'product'
    equal (typeof product.get('name')), 'undefined'
    delay ->
      equal (typeof store.get('product.name')), 'undefined'

asyncTest "hasOne associations can be reloaded", 4, ->
  @Store.find 1, (err, store) =>
    returnedProduct = store.get('product')
    returnedProduct.load (error, product) =>
      ok product instanceof @Product
      equal product.get('id'), 1
      equal product.get('name'), 'Product One'
      equal returnedProduct.get('name'), 'Product One'
      QUnit.start()

asyncTest "hasOne associations are loaded via JSON", 3, ->
  productLoadSpy = spyOn @productAdapter, 'read'

  # This store has a product inline in it's JSON
  @Store.find 2, (err, store) =>
    product = store.get 'product'
    delay =>
      equals productLoadSpy.callCount, 0
      equal product.get('id'), 3
      equal product.get('name'), "JSON Product"

asyncTest "hasOne associations loaded via JSON should not do an implicit remote fetch", 3, ->
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
    # hasOne saves inline save by default
    deepEqual storedJSON.product, {name: "Gizmo", store_id: record.id}

    @Store.find record.get('id'), (err, store2) =>
      deepEqual store2.toJSON(), storedJSON
      QUnit.start()

asyncTest "hasOne child models are added to the identity map", 1, ->
  @Store.find 2, (err, product) =>
    equal @Product.get('loaded').length, 1
    QUnit.start()

asyncTest "hasOne child models are passed through the identity map", 2, ->
  @Product.find 3, (err, product) =>
    throw err if err
    @Store.find 2, (err, store) =>
      equal @Product.get('loaded').length, 1
      ok store.get('product') == product
      QUnit.start()

asyncTest "hasOne associations render", 1, ->
  @Store.find 1, (err, store) ->
    source = '<span data-bind="store.product.name"></span>'
    context = Batman(store: store)
    helpers.render source, context, (node) ->
      delay ->
        equal node[0].innerHTML, 'Product One'

asyncTest "hasOne associations make the load method available", 3, ->
  @storeAdapter.storage["stores200"] =
    id: 200
    name: "Store 200"

  @Store.find 200, (err, store) =>
    product = store.get('product')
    equal product.get('id'), undefined

    @productAdapter.storage["products404"] =
      id: 404
      name: "Product 404"
      store_id: 200

    product.load (err, loadedProduct) ->
      # Proxies mark themselves as loaded
      equal product.get('loaded'), true
      equal loadedProduct.get('name'), "Product 404"
      QUnit.start()

asyncTest "hasOne supports custom foreign keys", 1, ->
  ns = @
  class Shop extends Batman.Model
    @encode 'id', 'name'
    @hasOne 'product', {namespace: ns, foreignKey: 'store_id'}
  shopAdapter = createStorageAdapter Shop, AsyncTestStorageAdapter,
    'shops1':
      id: 1
      name: 'Shop One'

  Shop.find 1, (err, shop) ->
    product = shop.get('product')
    delay ->
      equal product.get('name'), 'Product One'

QUnit.module "Batman.Model hasOne Associations with inverseOf"
  setup: ->
    namespace = {}

    namespace.Store = class @Store extends Batman.Model
      @encode 'id', 'name'
      @hasOne 'product', {namespace: namespace, inverseOf: 'store'}

    @storeAdapter = createStorageAdapter @Store, AsyncTestStorageAdapter,
      stores1:
        name: "Store One"
        id: 1
        product:
          name: "Product One"
          id: 1

    namespace.Product = class @Product extends Batman.Model
      @encode 'id', 'name'
      @belongsTo 'store', namespace: namespace

    @productAdapter = createStorageAdapter @Product, AsyncTestStorageAdapter,
      products1:
        name: "Product One"
        id: 1

asyncTest "hasOne sets the foreign key on the inverse relation if the child hasn't been loaded", 1, ->
  @Store.find 1, (err, store) =>
    throw err if err
    product = store.get('product')
    delay ->
      ok product.get('store') == store

asyncTest "hasOne sets the foreign key on the inverse relation if the child has already been loaded", 1, ->
  @Product.find 1, (err, product) =>
    throw err if err
    @Store.find 1, (err, store) =>
      throw err if err
      product = store.get('product')
      delay ->
        ok product.get('store') == store


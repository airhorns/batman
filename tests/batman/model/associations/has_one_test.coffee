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

    @productAdapter = createStorageAdapter @Product, AsyncTestStorageAdapter,
      'products1': {name: "Product One", id: 1, store_id: 1}

asyncTest "hasOne associations are loaded via ID", 3, ->
  @Store.find 1, (err, store) =>
    product = store.get 'product'
    ok product instanceof @Product
    equal product.get('id'), 1
    delay ->
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

asyncTest "hasOne associations render", 1, ->
  @Store.find 1, (err, store) ->
    source = '<span data-bind="store.product.name"></span>'
    context = Batman(store: store)
    helpers.render source, context, (node) ->
      equal node[0].innerHTML, 'Product One'
      QUnit.start()


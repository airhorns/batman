{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter} = if typeof require isnt 'undefined' then require '../model_helper' else window
helpers = if typeof require is 'undefined' then window.viewHelpers else require '../../view/view_helper'

QUnit.module "Batman.Model belongsTo Associations"
  setup: ->
    namespace = @namespace = this
    class @Store extends Batman.Model
      @encode 'id', 'name'

    @storeAdapter = createStorageAdapter @Store, AsyncTestStorageAdapter,
      'stores1': {name: "Store One", id: 1}
      'stores2': {name: "Store Two", id: 2, product: {id:3, name:"JSON Product"}}

    class @Product extends Batman.Model
      @encode 'id', 'name'
      @belongsTo 'store', namespace: namespace
    @productAdapter = createStorageAdapter @Product, AsyncTestStorageAdapter,
      'products1': {name: "Product One", id: 1, store_id: 1}

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

asyncTest "belongsTo associations are not loaded when autoload is off", 1, ->
  class Product extends Batman.Model
    @encode 'id', 'name'
    @belongsTo 'store', {namespace: @namespace, autoload: false}

  productAdapter = createStorageAdapter Product, AsyncTestStorageAdapter,
    'products1': {name: "Product One", id: 1, store_id: 1}

  Product.find 1, (err, product) =>
    store = product.get 'store'
    equal (typeof store), 'undefined'
    QUnit.start()

asyncTest "belongsTo associations are saved", 5, ->
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

asyncTest "belongsTo supports inline saving", 1, ->
  namespace = this
  class @InlineProduct extends Batman.Model
    @encode 'name'
    @belongsTo 'store', namespace: namespace, saveInline: true
  storageAdapter = createStorageAdapter @InlineProduct, AsyncTestStorageAdapter

  product = new @InlineProduct name: "Inline Product"
  store = new @Store name: "Inline Store"
  product.set 'store', store

  product.save (err, record) =>
    deepEqual storageAdapter.storage["inline_products#{record.get('id')}"],
      name: "Inline Product"
      store: {name: "Inline Store"}
    QUnit.start()

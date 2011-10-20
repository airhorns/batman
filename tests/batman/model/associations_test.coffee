{TestStorageAdapter, AsyncTestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

QUnit.module "Batman.Model One-To-One Associations"
  setup: ->
    class @Store extends Batman.Model
      @encode 'id', 'name'

    storeAdapter = new AsyncTestStorageAdapter @Store
    storeAdapter.storage =
      'stores1': {name: "One", id: 1}
    @Store.persist storeAdapter

    class @Product extends Batman.Model
      @encode 'id', 'name', 'store_id'

    productAdapter = new AsyncTestStorageAdapter @Product
    productAdapter.storage =
      'products1': {name: "One", id: 1, store_id: 1}
      'products2': {name: "Two", id: 2, store_id: 1}
    @Product.persist productAdapter

    @Product.belongsTo 'store', @Store
    @Store.hasOne 'product', @Product

asyncTest "belongsTo associations are loaded", 2, ->
  @Product.find 1, (err, product) =>
    store = product.get 'store'
    delay =>
      ok store instanceof @Store
      equal store.id, 1

asyncTest "belongsTo associations are saved", 1, ->
  store = new @Store name: 'Zellers'
  product = new @Product name: 'Gizmo'
  product.set 'store', store
  product.save (err, record) ->
    equal record.get('store_id'), store.id
    QUnit.start()

asyncTest "hasOne associations are loaded", 2, ->
  @Store.find 1, (err, store) =>
    product = store.get 'product'
    delay =>
      ok product instanceof @Product
      equal product.id, 1

asyncTest "hasOne associations are saved", 1, ->
  store = new @Store name: 'Zellers'
  product = new @Product name: 'Gizmo'
  store.set 'product', product
  store.save (err, record) ->
    equal product.get('store_id'), record.id
    QUnit.start()

QUnit.module "Batman.Model One-To-Many Associations"
  setup: ->
    class @Store extends Batman.Model
      @encode 'id', 'name'

    storeAdapter = new AsyncTestStorageAdapter @Store
    storeAdapter.storage =
      'stores1': {name: "One", id: 1}
    @Store.persist storeAdapter

    class @Product extends Batman.Model
      @encode 'id', 'name', 'store_id'

    productAdapter = new AsyncTestStorageAdapter @Product
    productAdapter.storage =
      'products1': {name: "One", id: 1, store_id: 1}
      'products2': {name: "Two", id: 2, store_id: 1}
    @Product.persist productAdapter

    @Store.hasMany 'products', @Product
    @Product.belongsTo 'store', @Store

asyncTest "hasMany associations are loaded", 5, ->
  @Store.find 1, (err, store) =>
    products = store.get 'products'
    delay =>
      trackedIds = {1: no, 2: no}

      equal products.length, 2
      products.forEach (product) =>
        ok product instanceof @Product
        trackedIds[product.id] = true
      equal trackedIds[1], yes
      equal trackedIds[2], yes

asyncTest "hasMany associations are saved", ->
  store = new @Store name: 'Zellers'
  product1 = new @Product name: 'Gizmo'
  product2 = new @Product name: 'Gadget'
  store.set 'products', new Batman.Set(product1, product2)
  store.save (err, record) ->
    equal product1.get('store_id'), record.id
    equal product2.get('store_id'), record.id
    QUnit.start()


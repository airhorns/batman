{TestStorageAdapter, AsyncTestStorageAdapter} = if typeof require isnt 'undefined' then require './model_helper' else window

QUnit.module "Batman.Model One-To-One Associations"
  setup: ->
    class @Store extends Batman.Model
      @encode 'id', 'name'

    @storeAdapter = new AsyncTestStorageAdapter @Store
    @storeAdapter.storage =
      'stores1': {name: "One", id: 1}
    @Store.persist @storeAdapter

    class @Product extends Batman.Model
      @encode 'id', 'name'

    @productAdapter = new AsyncTestStorageAdapter @Product
    @productAdapter.storage = 'products1': {name: "One", id: 1, store_id: 1}
    @Product.persist @productAdapter

    @Product.belongsTo 'store', @Store
    @Store.hasOne 'product', @Product

asyncTest "belongsTo associations are loaded", 2, ->
  @Product.find 1, (err, product) =>
    store = product.get 'store'
    delay =>
      ok store instanceof @Store
      equal store.id, 1

asyncTest "belongsTo associations are saved", 2, ->
  store = new @Store name: 'Zellers'
  product = new @Product name: 'Gizmo'
  product.set 'store', store

  productSaveSpy = spyOn product, 'save'
  product.save (err, record) ->
    equal productSaveSpy.callCount, 1
    equal record.get('store_id'), store.id
    QUnit.start()

asyncTest "hasOne associations are loaded", 2, ->
  @Store.find 1, (err, store) =>
    product = store.get 'product'
    delay =>
      ok product instanceof @Product
      equal product.id, 1

asyncTest "hasOne associations are saved", 2, ->
  store = new @Store name: 'Zellers'
  product = new @Product name: 'Gizmo'
  store.set 'product', product

  storeSaveSpy = spyOn store, 'save'
  store.save (err, record) ->
    equal storeSaveSpy.callCount, 1
    equal product.get('store_id'), record.id
    QUnit.start()

asyncTest "hasOne associations can be destroyed safely", 2, ->
  @Store.find 1, (err, store) =>
    @Product.find 1, (err, product) ->
      store.destroy()
      equal product.get('store_id'), undefined
      equal product._batman.attributes['store'], undefined
      QUnit.start()

asyncTest "Models can save while related records are loading", 1, ->
  @Store.find 1, (err, store) ->
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

  @Store.find 2, (err, store) =>
    product = store._batman.attributes.product
    ok product instanceof @Product
    equal product.get('id'), 5
    equal product.get('name'), "JSON product"
    QUnit.start()

asyncTest "belongsTo association can be loaded from JSON", ->
  @productAdapter.storage['products2'] =
    name: 'Two'
    id: 2
    store: '{"id": 5, "name": "JSON store"}'

  @Product.find 2, (err, product) =>
    store = product._batman.attributes.store
    ok store instanceof @Store
    equal store.get('id'), 5
    equal store.get('name'), "JSON store"
    QUnit.start()

QUnit.module "Batman.Model One-To-Many Associations"
  setup: ->
    class @Store extends Batman.Model
      @encode 'id', 'name'

    @storeAdapter = new AsyncTestStorageAdapter @Store
    @storeAdapter.storage =
      'stores1': {name: "One", id: 1}
    @Store.persist @storeAdapter

    class @Product extends Batman.Model
      @encode 'id', 'name', 'store_id'

    @productAdapter = new AsyncTestStorageAdapter @Product
    @productAdapter.storage =
      'products1': {name: "One", id: 1, store_id: 1}
      'products2': {name: "Two", id: 2, store_id: 1}
    @Product.persist @productAdapter

    @Store.hasMany 'products', @Product
    @Product.belongsTo 'store', @Store

asyncTest "hasMany associations are loaded", 4, ->
  @Store.find 1, (err, store) =>
    products = store.get 'products'
    delay =>
      trackedIds = {1: no, 2: no}

      products.forEach (product) =>
        ok product instanceof @Product
        trackedIds[product.id] = true
      equal trackedIds[1], yes
      equal trackedIds[2], yes

asyncTest "hasMany associations are saved via the parent model", 3, ->
  store = new @Store name: 'Zellers'
  product1 = new @Product name: 'Gizmo'
  product2 = new @Product name: 'Gadget'
  store.set 'products', new Batman.Set(product1, product2)

  storeSaveSpy = spyOn store, 'save'
  store.save (err, record) ->
    equal storeSaveSpy.callCount, 1
    equal product1.get('store_id'), record.id
    equal product2.get('store_id'), record.id
    QUnit.start()

asyncTest "hasMany associations are saved via the child model", 2, ->
  @Store.find 1, (err, store) =>
    product = new @Product name: 'Gizmo'
    product.set 'store', store
    product.save (err, savedProduct) ->
      equal savedProduct.get('store_id'), store.id

      products = store.get('products')
      delay =>
        ok products.has(savedProduct)

asyncTest "hasMany associations can be destroyed safely", 4, ->
  store = @Store.find 1, (err, store) =>
    products = @Product.get('all')
    store.destroy()
    products.forEach (product) =>
      equal product.get('store_id'), undefined
      equal product._batman.attributes['store'], undefined
    QUnit.start()

asyncTest "hasMany association can be loaded from JSON data", 12, ->
  class @ProductVariant extends Batman.Model
    @encode 'price'

  @productAdapter.storage['products3'] =
    name: 'Three'
    id: 3
    variants: '{"productvariants5":{"price":50,"product_id":3},"productvariants6":{"price":60,"product_id":3}}'

  @Product.hasMany 'variants', @ProductVariant
  @ProductVariant.belongsTo 'product', @Product

  @Product.find 3, (err, product) =>
    variants = product.get 'variants'
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

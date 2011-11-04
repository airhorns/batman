{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter} = if typeof require isnt 'undefined' then require '../model_helper' else window
helpers = if typeof require is 'undefined' then window.viewHelpers else require '../../view/view_helper'

QUnit.module "Batman.Model hasMany Associations"
  setup: ->
    namespace = this

    class @Store extends Batman.Model
      @encode 'id', 'name'
      @hasMany 'products', namespace: namespace
    @storeAdapter = createStorageAdapter @Store, AsyncTestStorageAdapter,
      'stores1': {name: "Store One", id: 1}

    class @Product extends Batman.Model
      @encode 'id', 'name', 'store_id'
      @belongsTo 'store', namespace: namespace
      @hasMany 'productVariants', namespace: namespace
    @productAdapter = createStorageAdapter @Product, AsyncTestStorageAdapter,
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

    class @ProductVariant extends Batman.Model
      @encode 'price'
      @belongsTo 'product', namespace: namespace
    variantAdapter = createStorageAdapter @ProductVariant, AsyncTestStorageAdapter

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

asyncTest "hasMany associations render", 4, ->
  @Store.find 1, (err, store) =>
    source = '<div><span data-foreach-product="store.products" data-bind="product.name"></span></div>'
    context = Batman(store: store)
    helpers.render source, context, (node) =>
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

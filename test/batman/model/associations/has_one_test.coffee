{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter} = if IN_NODE then require '../model_helper' else window
helpers = if !IN_NODE then window.viewHelpers else require '../../view/view_helper'

suite "Batman.Model Associations", ->
  suite "hasOne", ->
    namespace = false
    Store = false
    Product = false
    storeAdapter = false
    productAdapter = false

    setup ->
      namespace = {}

      class Store extends Batman.Model
        @encode 'id', 'name'
        @hasOne 'product', namespace: namespace

      storeAdapter = createStorageAdapter Store, AsyncTestStorageAdapter,
        'stores1': {name: "Store One", id: 1}
        'stores2': {name: "Store Two", id: 2, product: {id:3, name:"JSON Product"}}

      namespace.Product = class Product extends Batman.Model
        @encode 'id', 'name'
        @belongsTo 'store'

      productAdapter = createStorageAdapter Product, AsyncTestStorageAdapter,
        'products1': {name: "Product One", id: 1, store_id: 1}
        'products3': {name: "JSON Product", id: 3, store_id: 2}

    test "hasOne associations are loaded via ID", (done) ->
      Store.find 1, (err, store) =>
        product = store.get 'product'
        assert.equal product.get('id'), 1
        delay {done}, ->
          assert.equal product.get('name'), 'Product One'

    test "hasOne associations are not loaded when autoload is false", (done) ->
      ns = @namespace
      class Store extends Batman.Model
        @encode 'id', 'name'
        @hasOne 'product', {namespace: ns, autoload: false}

      storeAdapter = createStorageAdapter Store, AsyncTestStorageAdapter,
        'stores1': {name: "Store One", id: 1}
        'stores2': {name: "Store Two", id: 2, product: {id:3, name:"JSON Product"}}

      Store.find 1, (err, store) =>
        product = store.get 'product'
        assert.equal (typeof product.get('name')), 'undefined'
        delay {done}, ->
          assert.equal (typeof store.get('product.name')), 'undefined'

    test "hasOne associations can be reloaded", (done) ->
      Store.find 1, (err, store) =>
        returnedProduct = store.get('product')
        returnedProduct.load (error, product) =>
          assert.ok product instanceof Product
          assert.equal product.get('id'), 1
          assert.equal product.get('name'), 'Product One'
          assert.equal returnedProduct.get('name'), 'Product One'
          done()

    test "hasOne associations are loaded via JSON", (done) ->
      Store.find 2, (err, store) =>
        product = store.get 'product'
        assert.ok product instanceof Product
        assert.equal product.get('id'), 3
        assert.equal product.get('name'), "JSON Product"
        done()

    test "hasOne associations are saved", (done) ->
      store = new Store name: 'Zellers'
      product = new Product name: 'Gizmo'
      store.set 'product', product

      storeSaveSpy = spyOn store, 'save'
      store.save (err, record) =>
        assert.equal storeSaveSpy.callCount, 1
        assert.equal product.get('store_id'), record.id

        storedJSON = storeAdapter.storage["stores#{record.id}"]
        assert.deepEqual storedJSON, store.toJSON()
        # hasOne saves inline save by default
        assert.deepEqual storedJSON.product, {name: "Gizmo", store_id: record.id}

        Store.find record.get('id'), (err, store2) =>
          assert.deepEqual store2.toJSON(), storedJSON
          done()

    test "hasOne child models are added to the identity map", (done) ->
      Store.find 2, (err, product) =>
        assert.equal Product.get('loaded').length, 1
        done()

    test "hasOne child models are passed through the identity map", (done) ->
      Product.find 3, (err, product) =>
        throw err if err
        Store.find 2, (err, store) =>
          assert.equal Product.get('loaded').length, 1
          assert.equal store.get('product'), product
          done()

    test "hasOne associations render", (done) ->
      Store.find 1, (err, store) ->
        source = '<span data-bind="store.product.name"></span>'
        context = Batman(store: store)
        helpers.render source, context, (node) ->
          assert.equal node[0].innerHTML, 'Product One'
          done()

    test "hasOne associations make the load method available", (done) ->
      storeAdapter.storage["stores200"] =
        id: 200
        name: "Store 200"

      Store.find 200, (err, store) =>
        product = store.get('product')
        assert.equal product.get('id'), undefined

        productAdapter.storage["products404"] =
          id: 404
          name: "Product 404"
          store_id: 200

        product.load (err, loadedProduct) ->
          # Proxies mark themselves as loaded
          assert.equal product.get('loaded'), true
          assert.equal loadedProduct.get('name'), "Product 404"
          done()

    test "hasOne supports custom foreign keys", (done) ->
      class Shop extends Batman.Model
        @encode 'id', 'name'
        @hasOne 'product', {namespace: namespace, foreignKey: 'store_id'}

      shopAdapter = createStorageAdapter Shop, AsyncTestStorageAdapter,
        'shops1':
          id: 1
          name: 'Shop One'

      Shop.find 1, (err, shop) ->
        product = shop.get('product')
        assert.equal product.get('name'), 'Product One'
        done()

    suite "with inverseOf to belongsTo", ->
      Store = false
      Product = false

      setup ->
        namespace = {}

        namespace.Store = class Store extends Batman.Model
          @encode 'id', 'name'
          @hasOne 'product', {namespace: namespace, inverseOf: 'store'}

        storeAdapter = createStorageAdapter Store, AsyncTestStorageAdapter,
          stores1:
            name: "Store One"
            id: 1
            product:
              name: "Product One"
              id: 1

        namespace.Product = class Product extends Batman.Model
          @encode 'id', 'name'
          @belongsTo 'store', namespace: namespace

        productAdapter = createStorageAdapter Product, AsyncTestStorageAdapter,
          products1:
            name: "Product One"
            id: 1

      test "hasOne sets the foreign key on the inverse relation if the child hasn't been loaded", (done) ->
        Store.find 1, (err, store) =>
          throw err if err
          product = store.get('product')
          delay {done}, ->
            assert.equal product.get('store'), store

      test "hasOne sets the foreign key on the inverse relation if the child has already been loaded", (done) ->
        Product.find 1, (err, product) =>
          throw err if err
          Store.find 1, (err, store) =>
            throw err if err
            product = store.get('product')
            delay {done}, ->
              assert.equal product.get('store'), store

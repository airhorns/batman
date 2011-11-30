{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter} = if IN_NODE then require '../model_helper' else window
helpers = if !IN_NODE then window.viewHelpers else require '../../view/view_helper'

suite "Batman Model Associations", ->
  suite "hasMany", ->
    namespace = false
    Store = false
    Product = false
    ProductVariant = false
    storeAdapter = false
    productAdapter = false

    setup ->
      namespace = {}

      namespace.Store = class Store extends Batman.Model
        @encode 'id', 'name'
        @hasMany 'products', namespace: namespace

      storeAdapter = createStorageAdapter Store, AsyncTestStorageAdapter,
        stores1:
          name: "Store One"
          id: 1

      namespace.Product = class Product extends Batman.Model
        @encode 'id', 'name', 'store_id'
        @belongsTo 'store', namespace: namespace
        @hasMany 'productVariants', namespace: namespace

      productAdapter = createStorageAdapter Product, AsyncTestStorageAdapter,
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

      namespace.ProductVariant = class ProductVariant extends Batman.Model
        @encode 'price'
        @belongsTo 'product', namespace: namespace

      variantsAdapter = createStorageAdapter ProductVariant, AsyncTestStorageAdapter,
        product_variants5:
          id:5
          price:50
          product_id:3
        product_variants6:
          id:6
          price:60
          product_id:3

    test "hasMany associations are loaded", (done) ->
      Store.find 1, (err, store) =>
        products = store.get 'products'
        delay {done}, =>
          products.forEach (product) => assert.ok product instanceof Product
          assert.deepEqual products.map((x) -> x.get('id')), [1,2,3]

    test "hasMany associations are loaded using encoders", (done) ->
      Product.encode 'name'
        encode: (x) -> x
        decode: (x) -> x.toUpperCase()

      Store.find 1, (err, store) =>
        products = store.get 'products'
        delay {done}, ->
          assert.deepEqual products.map((x) -> x.get('name')), ["PRODUCT ONE", "PRODUCT TWO", "PRODUCT THREE"]

    test "embedded hasMany associations are loaded using encoders", (done) ->
      ProductVariant.encode 'price'
        encode: (x) -> x
        decode: (x) -> x * 100

      Product.find 3, (err, product) =>
        variants = product.get('productVariants')
        assert.deepEqual variants.map((x) -> x.get('price')), [5000, 6000]
        done()

    test "hasMany associations are not loaded when autoload is false", (done) ->
      class Store extends Batman.Model
        @encode 'id', 'name'
        @hasMany 'products', {namespace: namespace, autoload: false}

      storeAdapter = createStorageAdapter Store, AsyncTestStorageAdapter,
        stores1:
          name: "Store One"
          id: 1

      Store.find 1, (err, store) =>
        store
        products = store.get 'products'
        delay {done}, =>
          assert.equal products.length, 0

    test "hasMany associations can be reloaded", (done) ->
      loadSpy = spyOn(Product, 'load')
      Store.find 1, (err, store) =>
        products = store.get('products')
        assert.ok products.loaded
        assert.equal loadSpy.callCount, 1

        products.load (error, products) =>
          throw error if error
          assert.equal loadSpy.callCount, 2
          products.forEach (product) => assert.ok product instanceof Product
          assert.deepEqual products.map((x) -> x.get('id')), [1,2,3]
          done()

    test "hasMany associations are saved via the parent model", (done) ->
      store = new Store name: 'Zellers'
      product1 = new Product name: 'Gizmo'
      product2 = new Product name: 'Gadget'
      store.set 'products', new Batman.Set(product1, product2)

      storeSaveSpy = spyOn store, 'save'
      store.save (err, record) =>
        assert.equal storeSaveSpy.callCount, 1
        assert.equal product1.get('store_id'), record.id
        assert.equal product2.get('store_id'), record.id

        Store.find record.id, (err, store2) =>
          storedJSON = storeAdapter.storage["stores#{record.id}"]
          assert.deepEqual store2.toJSON(), storedJSON
          # hasMany saves inline by default
          assert.deepEqual storedJSON.products, [
            {name: "Gizmo", store_id: record.id}
            {name: "Gadget", store_id: record.id}
          ]
          done()

    test "hasMany associations are saved via the child model", (done) ->
      Store.find 1, (err, store) =>
        product = new Product name: 'Gizmo'
        product.set 'store', store
        product.save (err, savedProduct) ->
          assert.equal savedProduct.get('store_id'), store.id
          products = store.get('products')
          assert.ok products.has(savedProduct)
          done()

    test "hasMany association can be loaded from JSON data", (done) ->
      Product.find 3, (err, product) =>
        variants = product.get('productVariants')
        assert.ok variants instanceof Batman.Set
        assert.equal variants.length, 2

        variant5 = variants.toArray()[0]
        assert.ok variant5 instanceof ProductVariant
        assert.equal variant5.id, 5
        assert.equal variant5.get('price'), 50
        assert.equal variant5.get('product_id'), 3
        proxiedProduct = variant5.get('product')
        assert.equal proxiedProduct.get('id'), product.get('id')
        assert.equal proxiedProduct.get('name'), product.get('name')

        variant6 = variants.toArray()[1]
        assert.ok variant6 instanceof ProductVariant
        assert.equal variant6.id, 6
        assert.equal variant6.get('price'), 60
        assert.equal variant6.get('product_id'), 3
        proxiedProduct = variant6.get('product')
        assert.equal proxiedProduct.get('id'), product.get('id')
        assert.equal proxiedProduct.get('name'), product.get('name')

        done()

    test "hasMany child models are added to the identity map", (done) ->
      Product.find 3, (err, product) =>
        assert.equal ProductVariant.get('loaded').length, 2
        done()

    test "hasMany associations render", (done) ->
      Store.find 1, (err, store) =>
        source = '<div><span data-foreach-product="store.products" data-bind="product.name"></span></div>'
        context = Batman(store: store)
        helpers.render source, context, (node, view) =>
          assert.equal node.children().get(0)?.innerHTML, 'Product One'
          assert.equal node.children().get(1)?.innerHTML, 'Product Two'
          assert.equal node.children().get(2)?.innerHTML, 'Product Three'

          addedProduct = new Product(name: 'Product Four', store_id: store.id)
          addedProduct.save (err, savedProduct) ->
            delay {done}, ->
              assert.equal node.children().get(3)?.innerHTML, 'Product Four'

    test "hasMany adds new related model instances to its set", (done) ->
      Store.find 1, (err, store) =>
        addedProduct = new Product(name: 'Product Four', store_id: store.id)
        addedProduct.save (err, savedProduct) =>
          assert.ok store.get('products').has(savedProduct)
          done()

    test "hasMany loads records for each parent instance", (done) ->
      storeAdapter.storage["stores2"] =
        name: "Store Two"
        id: 2
      productAdapter.storage["products4"] =
        name: "Product Four"
        id: 4
        store_id: 2

      Store.find 1, (err, store) =>
        products = store.get('products')
        assert.equal products.length, 3
        Store.find 2, (err, store2) =>
          products2 = store2.get('products')
          assert.equal products2.length, 1
          done()

    test "hasMany loads after an instance of the related model is saved locally", (done) ->
      product = new Product
        name: "Local product"
        store_id: 1

      product.save (err, savedProduct) =>
        Store.find 1, (err, store) ->
          products = store.get('products')
          assert.ok products.has(savedProduct)
          assert.equal products.length, 4
          done()

    test "hasMany supports custom foreign keys", (done) ->
      class Shop extends Batman.Model
        @encode 'id', 'name'
        @hasMany 'products', {namespace: namespace, foreignKey: 'store_id'}
      shopAdapter = createStorageAdapter Shop, AsyncTestStorageAdapter,
        'shops1':
          id: 1
          name: 'Shop One'

      Shop.find 1, (err, shop) ->
        products = shop.get('products')
        assert.equal products.length, 3
        done()

    suite "with inverseOf belongsTo", ->
      Product = false
      ProductVariant = false
      setup ->
        namespace = {}

        namespace.Product = class Product extends Batman.Model
          @encode 'id', 'name'
          @hasMany 'productVariants', {namespace: namespace, inverseOf: 'product'}

        productAdapter = createStorageAdapter Product, AsyncTestStorageAdapter,
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

        namespace.ProductVariant = class ProductVariant extends Batman.Model
          @encode 'price'
          @belongsTo 'product', namespace: namespace

        variantsAdapter = createStorageAdapter ProductVariant, AsyncTestStorageAdapter,
          product_variants5:
            id:5
            price:50
          product_variants6:
            id:6
            price:60

      test "hasMany sets the foreign key on the inverse relation if the children haven't been loaded", (done) ->
        Product.find 1, (err, product) =>
          throw err if err
          variants = product.get('productVariants')
          delay {done}, ->
            variants = variants.toArray()
            assert.equal variants.length, 2
            assert.equal variants[0].get('product'), product
            assert.equal variants[1].get('product'), product

      test "hasMany sets the foreign key on the inverse relation if the children have already been loaded", (done) ->
        ProductVariant.load (err, variants) =>
          throw err if err
          Product.find 1, (err, product) =>
            throw err if err
            variants = product.get('productVariants')
            delay {done}, ->
              variants = variants.toArray()
              assert.equal variants.length, 2
              assert.equal variants[0].get('product'), product
              assert.equal variants[1].get('product'), product

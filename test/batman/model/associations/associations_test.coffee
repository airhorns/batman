{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter} = if IN_NODE then require '../model_helper' else window
helpers = if !IN_NODE then window.viewHelpers else require '../../view/view_helper'

suite "Batman.Model", ->
  suite "Associations", ->
    test "support custom model namespaces and class names", (done) ->
      namespace = {}
      class namespace.Walmart extends Batman.Model
        @encode 'name', 'id'

      class Product extends Batman.Model
        @belongsTo 'store',
          namespace: namespace
          name: 'Walmart'
        @encode 'name', 'id'

      productAdapter = createStorageAdapter Product, AsyncTestStorageAdapter,
        'products2': {name: "Product Two", id: 2, store: {id:3, name:"JSON Store"}}
      Product.find 2, (err, product) ->
        store = product.get('store')
        assert.ok store instanceof namespace.Walmart
        assert.equal store.get('id'), 3
        done()

    test "associations can be inherited", (done) ->
      namespace = {}
      class namespace.Store extends Batman.Model
        @encode 'name', 'id'
        @hasMany 'products', {namespace: namespace, autoload: false}

      class namespace.TestModel extends Batman.Model
        @belongsTo 'store', {namespace: namespace}

      class namespace.Product extends namespace.TestModel
        @encode 'name', 'id'

      productAdapter = createStorageAdapter namespace.Product, AsyncTestStorageAdapter,
        'products2': {name: "Product Two", id: 2, store_id: 3}

      store = new namespace.Store({id:3, name:"JSON Store"})
      store.get('products').load (err, products) ->
        product = products.get('toArray.0')
        assert.equal product.get('id'), 2
        assert.ok product instanceof namespace.Product
        done()

    test "support model classes that haven't been loaded yet", (done) ->
      namespace = {}
      class Blog extends Batman.Model
        @encode 'id', 'name'
        @hasOne 'customer', namespace: namespace
      blogAdapter = createStorageAdapter Blog, AsyncTestStorageAdapter,
        'blogs1': {name: "Blog One", id: 1}

      setTimeout (=>
        Customer = class namespace.Customer extends Batman.Model
          @encode 'id', 'name'
        customerAdapter = new AsyncTestStorageAdapter Customer
        customerAdapter.storage =
          'customer1': {name: "Customer One", id: 1, blog_id: 1}
        Customer.persist customerAdapter

        Blog.find 1, (err, blog) =>
          customer = blog.get 'customer'
          assert.equal customer.get('id'), 1
          assert.equal customer.get('name'), 'Customer One'
          done()
      ), ASYNC_TEST_DELAY

    test "models can save while related records are loading", (done) ->
      namespace = {}
      class Store extends Batman.Model
        @hasOne 'product', namespace: namespace
      storeAdapter = createStorageAdapter Store, AsyncTestStorageAdapter,
        "stores1": {id: 1, name: "Store One", product: {id: 1, name: "JSON product"}}

      Product = class namespace.Product extends Batman.Model
      productAdapter = createStorageAdapter Product, AsyncTestStorageAdapter

      Batman.developer.suppress =>
        Store.find 1, (err, store) ->
          product  = store.get 'product'
          product._batman.state = 'loading'
          store.save (err, savedStore) ->
            assert.ok !err
            done()

    test "inline saving can be disabled", (done) ->
      namespace = this
      class Store extends Batman.Model
        @hasMany 'products',
          namespace: namespace
          saveInline: false
      storeAdapter = createStorageAdapter Store, AsyncTestStorageAdapter,
        "stores1": {id: 1, name: "Store One"}

      class Product extends Batman.Model
      productAdapter = createStorageAdapter Product, AsyncTestStorageAdapter

      Store.find 1, (err, store) =>
        store.set 'products', new Batman.Set(new Product)
        store.save (err, savedStore) =>
          assert.equal storeAdapter.storage.stores1["products"], undefined
          done()

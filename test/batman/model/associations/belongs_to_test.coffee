{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter} = if IN_NODE then require '../model_helper' else window
helpers = if !IN_NODE then window.viewHelpers else require '../../view/view_helper'

suite "Batman Model Associations", ->
  suite "belongsTo", ->
    namespace = false
    Store = false
    Product = false
    productAdapter = false
    storeAdapter = false

    setup ->
        namespace = {}
        Store = class namespace.Store extends Batman.Model
          @encode 'id', 'name'

        storeAdapter = createStorageAdapter Store, AsyncTestStorageAdapter,
          'stores1':
            name: "Store One"
            id: 1
          'stores2':
            name: "Store Two"
            id: 2
            product:
              id:3
              name:"JSON Product"
          'stores3':
            name: "Store Three"
            id: 3

        Product = class namespace.Product extends Batman.Model
          @encode 'id', 'name'
          @belongsTo 'store', namespace: namespace
        productAdapter = createStorageAdapter Product, AsyncTestStorageAdapter,
          'products1':
            name: "Product One"
            id: 1
            store_id: 1
          'products4':
            name: "Product One"
            id: 1
            store:
              name: "Store Three",
              id: 3

    test "belongsTo yields the related model when toJSON is called", (done) ->
      Product.find 1, (err, product) =>
        store = product.get('store')
        storeJSON = store.toJSON()
        # store will encode its product
        delete storeJSON.product

        assert.deepEqual storeJSON, storeAdapter.storage["stores1"]
        done()

    test "belongsTo associations are loaded via ID", (done) ->
      Product.find 1, (err, product) =>
        store = product.get 'store'
        assert.equal store.get('id'), 1
        done()

    test "belongsTo associations are not loaded when autoload is off", (done) ->
      class Product extends Batman.Model
        @encode 'id', 'name'
        @belongsTo 'store', {namespace: @namespace, autoload: false}

      productAdapter = createStorageAdapter Product, AsyncTestStorageAdapter,
        'products1': {name: "Product One", id: 1, store_id: 1}

      Product.find 1, (err, product) =>
        store = product.get 'store'
        assert.equal (typeof store), 'undefined'
        done()

    test "belongsTo associations are saved", (done) ->
      store = new Store name: 'Zellers'
      product = new Product name: 'Gizmo'
      product.set 'store', store

      productSaveSpy = spyOn product, 'save'
      product.save (err, record) =>
        assert.equal productSaveSpy.callCount, 1
        assert.equal record.get('store_id'), store.id
        storedJSON = productAdapter.storage["products#{record.id}"]
        assert.deepEqual storedJSON, product.toJSON()

        store = record.get('store')
        assert.equal storedJSON.store_id, undefined

        Product.find record.get('id'), (err, product2) ->
          assert.deepEqual product2.toJSON(), storedJSON
          done()

    test "belongsTo parent models are added to the identity map", (done) ->
      Product.find 4, (err, product) =>
        assert.equal Store.get('loaded').length, 1
        done()

    test "belongsTo parent models are passed through the identity map", (done) ->
      Store.find 3, (err, store) =>
        throw err if err
        Product.find 4, (err, product) =>
          assert.equal Store.get('loaded').length, 1
          assert.equal product.get('store'), store
          done()

    test "belongsTo associations render", (done) ->
      Product.find 1, (err, product) ->
        source = '<span data-bind="product.store.name"></span>'
        context = Batman(product: product)
        helpers.render source, context, (node) =>
          assert.equal node[0].innerHTML, 'Store One'
          done()

    test "belongsTo supports inline saving", (done) ->
      namespace = this
      class InlineProduct extends Batman.Model
        @encode 'name'
        @belongsTo 'store', namespace: namespace, saveInline: true
      storageAdapter = createStorageAdapter InlineProduct, AsyncTestStorageAdapter

      product = new InlineProduct name: "Inline Product"
      store = new Store name: "Inline Store"
      product.set 'store', store

      product.save (err, record) =>
        assert.deepEqual storageAdapter.storage["inline_products#{record.get('id')}"],
          name: "Inline Product"
          store: {name: "Inline Store"}
        done()

    test "belongsTo supports custom local keys", (done) ->
      class Shirt extends Batman.Model
        @encode 'id', 'name'
        @belongsTo 'store', namespace: namespace, localKey: 'shop_id'
      shirtAdapter = createStorageAdapter Shirt, AsyncTestStorageAdapter,
        'shirts1':
          id: 1
          name: 'Shirt One'
          shop_id: 1

      Shirt.find 1, (err, shirt) ->
        store = shirt.get('store')
        assert.equal store.get('name'), 'Store One'
        done()

    suite "with inverseOf to a hasMany", ->
      Customer = false
      Order = false

      setup ->
        namespace = {}
        Order = class namespace.Order extends Batman.Model
          @encode 'id', 'name'
          @belongsTo 'customer', {namespace: namespace, inverseOf: 'orders'}

        orderAdapter = createStorageAdapter Order, AsyncTestStorageAdapter,
          'orders1':
            name: "Order One"
            id: 1
            customer:
              name: "Customer One"
              id: 1
          'orders2':
            name: "Order Two"
            id: 1
            customer:
              name: "Customer One"
              id: 1

        Customer = class namespace.Customer extends Batman.Model
          @encode 'id', 'name'
          @hasMany 'orders', namespace: namespace

        customerAdapter = createStorageAdapter Customer, AsyncTestStorageAdapter,
          'customers1':
            name: "Customer One"
            id: 1

      test "belongsTo sets the foreign key on itsself so the parent relation SetIndex adds it, if the parent hasn't been loaded", (done) ->
        Order.find 1, (err, order) =>
          throw err if err
          customer = order.get('customer')
          delay {done}, ->
            assert.ok customer.get('orders').has(order)

      test "belongsTo sets the foreign key on itself so the parent relation SetIndex adds it, if the parent has already been loaded", (done) ->
        Customer.find 1, (err, customer) =>
          throw err if err
          Order.find 1, (err, order) =>
            throw err if err
            customer = order.get('customer')
            delay {done}, ->
              assert.ok customer.get('orders').has(order)

      test "belongsTo sets the foreign key foreign key on itself such that many loads are picked up by the parent", (done) ->
        Customer.find 1, (err, customer) =>
          throw err if err
          Order.find 1, (err, order) =>
            throw err if err
            assert.equal customer.get('orders').length, 1
            Order.find 2, (err, order) =>
              throw err if err
              assert.equal customer.get('orders').length, 2
              assert.equal Customer.get('loaded').length, 1, 'Only one parent record should be created'
              done()

    suite "with inverseOf to a hasOne", ->
      Order = false
      Customer = false

      setup ->
        namespace = {}
        Order = class namespace.Order extends Batman.Model
          @encode 'id', 'name'
          @belongsTo 'customer', {namespace: namespace, inverseOf: 'order'}

        orderAdapter = createStorageAdapter Order, AsyncTestStorageAdapter,
          'orders1':
            name: "Order One"
            id: 1
            customer:
              name: "Customer One"
              id: 1

        Customer = class namespace.Customer extends Batman.Model
          @encode 'id', 'name'
          @hasOne 'order', namespace: namespace

        customerAdapter = createStorageAdapter Customer, AsyncTestStorageAdapter,
          'customers1':
            name: "Customer One"
            id: 1

      test "belongsTo sets the inverse relation if the parent hasn't been loaded", (done) ->
        Order.find 1, (err, order) =>
          throw err if err
          customer = order.get('customer')
          assert.equal customer.get('order'), order
          done()

      test "belongsTo sets the inverse relation if the parent has already been loaded", (done) ->
        Customer.find 1, (err, customer) =>
          throw err if err
          Order.find 1, (err, order) =>
            throw err if err
            customer = order.get('customer')
            assert.equal customer.get('order'), order
            done()

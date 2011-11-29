{TestStorageAdapter} = if IN_NODE then require './model_helper' else window

suite "Batman.Model", ->
  suite "class finding", ->
    Product = false
    adapter = false

    setup ->
      class Product extends Batman.Model
        @encode 'name', 'cost'

      adapter = new TestStorageAdapter(Product)
      adapter.storage =
        'products1': {name: "One", cost: 10, id:1}
        'products2': {name: "Two", cost: 5, id:2}

      Product.persist adapter

    test "will error unless a callback is provided",  ->
      assert.throws => Product.find 1

    test "models will find an instance in the store", (done) ->
      Product.find 1, (err, product) ->
        throw err if err
        assert.equal product.get('name'), 'One'
        done()

    test "found models should end up in the loaded set", (done) ->
      Product.find 1, (err, firstProduct) =>
        throw err if err
        assert.equal Product.get('loaded').length, 1
        done()

    test "models will find the same instance if called twice", (done) ->
      Product.find 1, (err, firstProduct) =>
        throw err if err
        Product.find 1, (err, secondProduct) =>
          throw err if err
          assert.equal firstProduct, secondProduct
          assert.equal Product.get('loaded').length, 1
          done()

    test "find on models will return the same instance if called twice", (done) ->
      callbackFirstProduct = false
      callbackSecondProduct = false
      returnedFirstProduct = Product.find 1, (err, firstProduct) =>
        throw err if err
        callbackFirstProduct = firstProduct
        returnedSecondProduct = Product.find 1, (err, secondProduct) =>
          throw err if err
          callbackSecondProduct = secondProduct
          delay {done}, ->
            assert.equal returnedFirstProduct, callbackFirstProduct, 'find returns the same product'
            assert.equal returnedSecondProduct, callbackSecondProduct, 'find returns the same product'

    test "models will find instances even if the constructor is overridden", (done) ->
      class LiskovsEnemy extends Batman.Model
        @encode 'name', 'cost'
        constructor: (name, cost) ->
          super()
          @set 'name', name
          @set 'cost', cost

      adapter = new TestStorageAdapter(LiskovsEnemy)
      adapter.storage =
        'liskovs_enemies1': {name: "One", cost: 10, id:1}
        'liskovs_enemies2': {name: "Two", cost: 5, id:2}

      LiskovsEnemy.persist adapter

      LiskovsEnemy.find 1, (err, firstProduct) =>
        throw err if err
        LiskovsEnemy.find 1, (err, secondProduct) =>
          throw err if err
          assert.equal firstProduct, secondProduct
          assert.equal LiskovsEnemy.get('loaded').length, 1
          done()

  suite "class findOrCreating", ->
    Product = false
    setup ->
      class Product extends Batman.Model
        @encode 'name', 'cost'

      adapter = new TestStorageAdapter(Product)
      adapter.storage =
        'products1': {name: "One", cost: 10, id:1}

      Product.persist adapter

    test "models will create a fixture model", (done) ->
      Product.findOrCreate {id: 3, name: "three"}, (err, product) =>
        throw err if err
        assert.ok !product.isNew()
        assert.equal Product.get('loaded').length, 1, "the product is added to the identity map"
        done()

    test "models will find an already loaded model and update the data", (done) ->
      Product.find 1, (err, existingProduct) =>
        throw err if err
        assert.ok existingProduct

        Product.findOrCreate {id: 1, name: "three"}, (err, product) =>
          throw err if err
          assert.ok !product.isNew()
          assert.equal Product.get('loaded').length, 1, "the identity map is maintained"
          assert.equal product.get('id'), 1
          assert.equal product.get('name'), 'three'
          assert.equal product.get('cost'), 10
          done()

  suite "class loading", ->
    Product = false
    setup ->
      class Product extends Batman.Model
        @encode 'name', 'cost'

      adapter = new TestStorageAdapter(Product)
      adapter.storage =
        'products1': {name: "One", cost: 10, id:1}
        'products2': {name: "Two", cost: 5, id:2}

      Product.persist adapter

    test "models will load all their records", (done) ->
      Product.load (err, products) =>
        throw err if err
        assert.equal products.length, 2

        assert.equal Product.get('all.length'), 2
        done()

    test "Model.all will load all records", (done) ->
      set =  Product.get('all')
      delay {done}, ->
        assert.equal set.length, 2

    test "Model.all will get all without storage adapters", (done) ->
      class Order extends Batman.Model

      set = Order.get('all')
      assert.equal set.length, 0
      delay {done}, ->
        assert.equal set.length, 0

    test "classes fire their loading/loaded callbacks", (done) ->
      callOrder = []

      Product.on 'loading', -> callOrder.push 1
      Product.on 'loaded', -> callOrder.push 2

      Product.load (err, products) =>
        delay {done}, ->
          assert.deepEqual callOrder, [1,2]

    test "models will load all their records matching an options hash", (done) ->
      Product.load {name: 'One'}, (err, products) ->
        assert.equal products.length, 1
        done()

    test "models will maintain the all set", (done) ->
      Product.load {name: 'One'}, (err, products) =>
        assert.equal Product.get('all').length, 1, 'Products loaded are added to the set'

        Product.load {name: 'Two'}, (err, products) =>
          assert.equal Product.get('all').length, 2, 'Products loaded are added to the set'

          Product.load {name: 'Two'}, (err, products) =>
            assert.equal Product.get('all').length, 2, "Duplicate products aren't added to the set."

            done()

    test "models will maintain the all set if no callbacks are given", (done) ->
      Product.load {name: 'One'}
      delay {done}, =>
        assert.equal Product.get('all').length, 1, 'Products loaded are added to the set'
        Product.load {name: 'Two'}
        delay {done}, =>
          assert.equal Product.get('all').length, 2, 'Products loaded are added to the set'
          Product.load {name: 'Two'}
          delay {done}, =>
            assert.equal Product.get('all').length, 2, "Duplicate products aren't added to the set."

    test "loading the same models will return the same instances", (done) ->
      Product.load {name: 'One'}, (err, productsOne) =>
        assert.equal Product.get('all').length, 1

        Product.load {name: 'One'}, (err, productsTwo) =>
          assert.deepEqual productsOne, productsTwo
          assert.equal Product.get('all').length, 1
          done()

    test "models without storage adapters should throw errors when trying to be loaded",  ->
      class Silly extends Batman.Model
      try
        Silly.load()
      catch e
        assert.ok e

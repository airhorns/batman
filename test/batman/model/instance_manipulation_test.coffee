{TestStorageAdapter} = if IN_NODE then require './model_helper' else window

suite "Batman Model", ->
  suite "instance loading", ->
    Product = false
    adapter = false

    setup ->
      class Product extends Batman.Model
        @encode 'name', 'cost'

      adapter = new TestStorageAdapter(Product)
      adapter.storage =
        'products1': {name: "One", cost: 10, id:1}

      Product.persist adapter

    test "instantiated instances can load their values", (done) ->
      product = new Product(1)
      product.load (err, product) =>
        throw err if err
        assert.equal product.get('name'), 'One'
        assert.equal product.get('id'), 1
        done()

    test "instantiated instances can load their values", (done) ->
      product = new Product(1110000) # Non existant primary key.
      product.load (err, product) =>
        assert.ok err
        done()

    test "loading instances should add them to the all set", (done) ->
      product = new Product(1)
      product.load (err, product) =>
        assert.equal Product.get('all').length, 1
        done()

    test "loading instances should add them to the all set if no callbacks are given", (done) ->
      product = new Product(1)
      product.load()
      delay {done}, =>
        assert.equal Product.get('all').length, 1

  suite "instance saving", ->
    Product = false
    adapter = false

    setup ->
      class Product extends Batman.Model
        @encode 'name', 'cost'

      adapter = new TestStorageAdapter(Product)
      Product.persist adapter

    test "model instances should save",  ->
      product = new Product()
      product.save (err, product) =>
        throw err if err?
        assert.ok product.get('id') # We rely on the test storage adapter to add an ID, simulating what might actually happen IRL

    test "new instances should be added to the identity map",  ->
      product = new Product()
      assert.equal Product.get('loaded.length'), 0
      product.save (err, product) =>
        throw err if err?
        assert.equal Product.get('loaded').length, 1

    test "new instances should be added to the identity map even if no callback is given", (done) ->
      product = new Product()
      assert.equal Product.get('loaded.length'), 0
      product.save()
      delay {done}, =>
        throw err if err?
        assert.equal Product.get('loaded').length, 1

    test "existing instances shouldn't be re added to the identity map",  ->
      product = new Product(10)
      product.load (err, product) =>
        throw err if err
        assert.equal Product.get('all').length, 1
        product.save (err, product) =>
          throw err if err?
          assert.equal Product.get('all').length, 1

    test "existing instances should be updated with incoming attributes",  ->
      adapter.storage = {"products10": {name: "override"}}
      product = new Product(id: 10, name: "underneath")
      product.load (err, product) =>
        throw err if err
        assert.equal product.get('name'), 'override'

    test "model instances should throw if they can't be saved",  ->
      product = new Product()
      adapter.create = (record, options, callback) -> callback(new Error("couldn't save for some reason"))
      product.save (err, product) =>
        assert.ok err

    test "model instances shouldn't save if they don't validate",  ->
      Product.validate 'name', presence: yes
      product = new Product()
      product.save (err, product) ->
        assert.equal err.length, 1

    test "model instances shouldn't save if they have been destroyed",  ->
      p = new Product(10)
      p.destroy (err) =>
        throw err if err
        p.save (err) ->
          assert.ok err
        p.load (err) ->
          assert.ok err

    test "create method returns an instance of a model while saving it", (done) ->
      result = Product.create (err, product) =>
        assert.ok !err
        assert.ok product instanceof Product
        done()
      assert.ok result instanceof Product

    test "string ids are coerced into integers when possible",  ->
      product = new Product
      product.save()
      id = product.id
      Product.find ""+id, (err, foundProduct) ->
        assert.equal foundProduct, product

  suite "instance destruction", ->
    Product = false
    adapter = false

    setup ->
      class Product extends Batman.Model
        @encode 'name', 'cost'

      adapter = new TestStorageAdapter(Product)
      Product.persist adapter

    test "model instances should be destroyable", (done) ->
      Product.find 10, (err, product) =>
        throw err if err
        assert.equal Product.get('all').length, 1

        product.destroy (err) =>
          throw err if err
          assert.equal Product.get('all').length, 0, 'instances should be removed from the identity map upon destruction'
          done()

    test "model instances which don't exist in the store shouldn't be destroyable", (done) ->
      p = new Product(11000)
      p.destroy (err) =>
        assert.ok err
        done()

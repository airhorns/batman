{TestStorageAdapter} = if IN_NODE then require './model_helper' else window

suite "Batman.Model", ->
  suite "state transitions", ->
    setup ->
        class Product extends Batman.Model
          @persist TestStorageAdapter

    test "new instances start 'empty'",  ->
      product = new Product
      assert.ok product.isNew()
      assert.equal product.state(), 'empty'

    test "loaded instances start 'loaded'", (done) ->
      product = new Product(10)
      Batman.developer.suppress =>
        product.load (err, product) ->
          throw err if err
          assert.ok !product.isNew()
          assert.equal product.state(), 'loaded'
          done()

    test "instances have state transitions for observation",  ->
      product = new Product
      product.transition 'loading', 'loaded', spy = createSpy()
      product.loading()
      product.loaded()
      assert.ok spy.called

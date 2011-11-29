{TestStorageAdapter} = if IN_NODE then require './model_helper' else window

suite "Batman.Model", ->
  suite "dirty key tracking", ->
    Product = false
    setup ->
      class Product extends Batman.Model
        @persist TestStorageAdapter

    test "no keys are dirty upon creation",  ->
      product = new Product
      assert.equal product.get('dirtyKeys').length, 0

    test "old values are tracked in the dirty keys hash",  ->
      product = new Product
      product.set 'foo', 'bar'
      product.set 'foo', 'baz'
      assert.equal(product.get('dirtyKeys.foo'), 'bar')

    test "creating instances by passing attributes sets those attributes as dirty",  ->
      product = new Product foo: 'bar'
      assert.equal(product.get('dirtyKeys').length, 1)
      assert.equal(product.state(), 'dirty')

    test "saving clears dirty keys", (done) ->
      product = new Product foo: 'bar', id: 1
      product.save (err) ->
        throw err if err
        assert.equal(product.dirtyKeys.length, 0)
        assert.notEqual(product.state(), 'dirty')
        done()

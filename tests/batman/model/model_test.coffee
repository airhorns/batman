QUnit.module "Batman.Model",
  setup: ->
    class @Product extends Batman.Model

test "constructors should always be called with new", ->
  Product = @Product
  raises (-> product = Product()),
    (message) -> ok message; true

  Namespace = Product: Product
  raises (-> product = Namespace.Product()),
    (message) -> ok message; true

  product = new Namespace.Product()
  ok product instanceof Product

test "primary key is undefined on new models", ->
  product = new @Product
  ok product.isNew()
  equal typeof product.get('id'), 'undefined'

test "primary key is 'id' by default", ->
  product = new @Product(id: 10)
  equal product.get('id'), 10

test "integer string ids should be coerced into integers", 1, ->
  product = new @Product(id: "1234")
  strictEqual product.get('id'), 1234

test "non-integer string ids should not be coerced", 1, ->
  product = new @Product(id: "123d")
  strictEqual product.get('id'), "123d"

test "updateAttributes will update a model's attributes", ->
  product = new @Product(id: 10)
  product.updateAttributes {name: "foobar", id: 20}
  equal product.get('id'), 20
  equal product.get('name'), "foobar"

test "updateAttributes will returns the updated record", ->
  product = new @Product(id: 10)
  equal product, product.updateAttributes {name: "foobar", id: 20}

test "primary key can be changed by setting primary key on the model class", ->
  @Product.primaryKey = 'uuid'
  product = new @Product(uuid: "abc123")
  equal product.get('id'), 'abc123'

test 'the \'state\' key should be a valid attribute name', ->
  p = new @Product(state: "silly")
  equal p.get('state'), "silly"
  equal p.state(), "dirty"

test 'the \'batmanState\' key should be gettable and report the internal state', ->
  p = new @Product(state: "silly")
  equal p.state(), "dirty"
  equal p.get('batmanState'), "dirty"

test 'the instantiated storage adapter should be returned when persisting', ->
  returned = false
  class TestStorageAdapter extends Batman.StorageAdapter
    isTestStorageAdapter: true

  class Product extends Batman.Model
    returned = @persist TestStorageAdapter

  ok returned.isTestStorageAdapter

test 'the array of instantiated storage adapters should be returned when persisting', ->
  [a, b, c] = [false, false, false]
  class TestStorageAdapter extends Batman.StorageAdapter
    isTestStorageAdapter: true

  class Product extends Batman.Model
    [a,b,c] = @persist TestStorageAdapter, TestStorageAdapter, TestStorageAdapter

  for instance in [a,b,c]
    ok instance.isTestStorageAdapter

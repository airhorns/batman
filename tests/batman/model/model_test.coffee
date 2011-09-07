QUnit.module "Batman.Model",
  setup: ->
    class @Product extends Batman.Model

test "constructors should always be called with new", ->
  Product = @Product
  raises (-> product = Product()),
    (message) -> message is "constructors must be called with new"

  Namespace = Product: Product
  raises (-> product = Namespace.Product()),
    (message) -> message is "constructors must be called with new"

  product = new Namespace.Product()
  ok product instanceof Product

test "primary key is undefined on new models", ->
  product = new @Product
  ok product.isNew()
  equal typeof product.get('id'), 'undefined'

test "primary key is 'id' by default", ->
  product = new @Product(id: 10)
  equal product.get('id'), 10

test "primary key can be changed by setting primary key on the model class", ->
  @Product.primaryKey = 'uuid'
  product = new @Product(uuid: "abc123")
  equal product.get('id'), 'abc123'

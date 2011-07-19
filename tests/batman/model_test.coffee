QUnit.module "Batman.Model",
  setup: ->
    class @Product extends Batman.Model
      isProduct: true
      
      
test "is state machine", ->
  product = new @Product
  equal product.state(), 'empty'
  
  product.loading()
  equal product.state(), 'loading'
  
  product2 = new @Product
  equal product.state(), 'loading'
  equal product2.state(), 'empty'

test "has state transitions", 1, ->
  product = new @Product
  product.transition 'loading', 'loaded', ->
    ok(true, 'transition called')
  
  product.loading()
  product.loaded()

test "model tracks dirty keys", ->
  m = new Batman.Model
  ok(m.get('dirtyKeys'))
  
  product = new @Product
  product.foo = 'bar'
  product.set 'foo', 'baz'
  
  equal(product.get('dirtyKeys.foo'), 'bar')

test "saving clears dirty keys", ->
  product = new @Product foo: 'bar'
  # equal(product.dirtyKeys.length, 1) #FIXME: make length work with get
  equal(product.get('state'), 'dirty')
  
  product.save()
  equal(product.dirtyKeys.length, 0)
  notEqual(product.get('state'), 'dirty')

test "record lifecycle", ->
  callOrder = []
  
  product = new @Product
  product.beforeValidation -> callOrder.push(1)
  product.afterValidation -> callOrder.push(2)
  product.beforeSave -> callOrder.push(3)
  product.beforeCreate -> callOrder.push(4)
  product.afterCreate -> callOrder.push(6)
  product.afterSave -> callOrder.push(7)
  
  product.save(-> callOrder.push(5))
  deepEqual(callOrder, [1,2,3,4,5,6,7])

QUnit.module "Batman.Model: encoding/decoding to/from JSON"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'
      @accessor 'excitingName'
        get: -> @get('name').toUpperCase()
      
test "keys marked for encoding should be encoded", ->
  p = new @Product {name: "Cool Snowboard", cost: 12.99}
  deepEqual p.toJSON(), {name: "Cool Snowboard", cost: 12.99}

test "undefined keys marked for encoding shouldn't be encoded", ->
  p = new @Product {name: "Cool Snowboard"}
  deepEqual p.toJSON(), {name: "Cool Snowboard"}

test "accessor keys marked for encoding should be encoded", ->
  class TestProduct extends @Product
    @encode 'excitingName'

  p = new TestProduct {name: "Cool Snowboard", cost: 12.99}
  deepEqual p.toJSON(), {name: "Cool Snowboard", cost: 12.99, excitingName: 'COOL SNOWBOARD'}

test "keys marked for decoding should be decoded", ->
  p = new @Product 
  json = {name: "Cool Snowboard", cost: 12.99}

  p.fromJSON(json)
  equal p.get('name'), "Cool Snowboard"
  equal p.get('cost'), 12.99

test "keys not marked for encoding shouldn't be encoded", ->
  p = new @Product {name: "Cool Snowboard", cost: 12.99, wibble: 'wobble'}
  deepEqual p.toJSON(), {name: "Cool Snowboard", cost: 12.99}

test "keys not marked for decoding shouldn't be decoded", ->
  p = new @Product 
  json = {name: "Cool Snowboard", cost: 12.99, wibble: 'wobble'}

  p.fromJSON(json)
  equal p.get('name'), "Cool Snowboard"
  equal p.get('cost'), 12.99
  equal p.get('wibble'), undefined

test "models without any decoders should decode all keys with camelization", ->
  
  class TestProduct extends Batman.Model
    # No encoders.

  p = new TestProduct
  p.fromJSON {name: "Cool Snowboard", cost: 12.99}
  
  equal p.get 'name', "Cool Snowboard"
  equal p.get 'cost', 12.99


QUnit.module "Batman.Model: validations"

test "length", ->
  class Product extends Batman.Model
    @validate 'exact', length: 5
    @validate 'max', maxLength: 4
    @validate 'range', lengthWithin: [3, 5]
  
  p = new Product exact: '12345', max: '1234', range: '1234'
  ok p.isValid()
  
  p.set 'exact', '123'
  p.set 'max', '12345'
  p.set 'range', '12'
  ok !p.isValid()
  equal p.errors.length, 3

test "presence", ->
  class Product extends Batman.Model
    @validate 'name', presence: yes
  
  p = new Product name: 'nick'
  ok p.isValid()
  
  p.unset 'name'
  ok !p.isValid()

asyncTest "async", 2, ->
  hasFailed = no
  class Product extends Batman.Model
    @validate 'email', (validator, record, key, value) ->
      validator.wait()
      setTimeout (->
        if hasFailed
          validator.success()
        else
          validator.error 'email is already taken'
          hasFailed = yes
        
        validator.resume()
      ), 500
  
  p = new Product email: 'nick@shopify.com'
  p.afterValidation -> equal(p.errors.length, 1); start()
  ok !p.isValid()



QUnit.module "Batman.Model: storage"

asyncTest "local storage", 1, ->
  localStorage.clear()
  
  class Product extends Batman.Model
    @persist Batman.LocalStorage
    @encode 'foo'
  
  p = new Product foo: 'bar'
  
  p.afterSave ->
    copy = Product.find p.id
    copy.afterLoad ->
      equal copy.get('foo'), 'bar'
      start()
  
  p.save()

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
  product.afterCreate -> callOrder.push(5)
  product.afterSave -> callOrder.push(6)
  
  product.save()
  deepEqual(callOrder, [1,2,3,4,5,6])



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
    p = Product.find p.id
    p.afterLoad ->
      equal p.foo, 'bar'
      start()
  
  p.save()

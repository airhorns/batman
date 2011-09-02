QUnit.module "Batman.Model: validations"

asyncTest "validation shouldn leave the model in the same state it left it", ->
  class Product extends Batman.Model
    @validate 'name', presence: yes

  p = new Product
  oldState = p.state()
  p.validate (result, errors) ->
    equal p.state(), oldState
    QUnit.start()

asyncTest "length", 3, ->
  class Product extends Batman.Model
    @validate 'exact', length: 5
    @validate 'max', maxLength: 4
    @validate 'range', lengthWithin: [3, 5]

  p = new Product exact: '12345', max: '1234', range: '1234'
  p.validate (result) ->
    ok result

    p.set 'exact', '123'
    p.set 'max', '12345'
    p.set 'range', '12'

    p.validate (result, errors) ->
      ok !result
      equal errors.length, 3
      QUnit.start()

asyncTest "presence", 2, ->
  class Product extends Batman.Model
    @validate 'name', presence: yes

  p = new Product name: 'nick'
  p.validate (result, errors) ->
    ok result
    p.unset 'name'
    p.validate (result, errors) ->
      ok !result
      QUnit.start()

asyncTest "custom async validations", ->
  letItPass = true
  class Product extends Batman.Model
    @validate 'name', (errors, record, key, callback) ->
      setTimeout ->
        errors.get('name').add "didn't validate" unless letItPass
        callback()
      , 0
  p = new Product
  p.validate (result, errors) ->
    ok result
    letItPass = false
    p.validate (result, errors) ->
      ok !result
      QUnit.start()

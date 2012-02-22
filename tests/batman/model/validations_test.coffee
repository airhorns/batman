validationsTestSuite = ->
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

  asyncTest "presence", 3, ->
    class Product extends Batman.Model
      @validate 'name', presence: yes

    p = new Product name: 'nick'
    p.validate (result, errors) ->
      ok result
      p.unset 'name'
      p.validate (result, errors) ->
        ok !result
        p.set 'name', ''
        p.validate (result, errors) ->
          ok !result
          QUnit.start()

  asyncTest "presence and length", 4, ->
    class Product extends Batman.Model
      @validate 'name', {presence: yes, maxLength: 10, minLength: 3}

    p = new Product
    p.validate (result, errors) ->
      ok !result
      equal errors.length, 2

      p.set 'name', "beans"
      p.validate (result, errors) ->
        ok result
        equal errors.length, 0
        QUnit.start()

  asyncTest "custom async validations", ->
    letItPass = true
    class Product extends Batman.Model
      @validate 'name', (errors, record, key, callback) ->
        setTimeout ->
          errors.add 'name', "didn't validate" unless letItPass
          callback()
        , 0

    p = new Product
    p.validate (result, errors) ->
      ok result
      letItPass = false
      p.validate (result, errors) ->
        ok !result
        QUnit.start()

  asyncTest "numeric", ->
    class Product extends Batman.Model
      @validate 'number', numeric: yes

    p = new Product number: 5
    p.validate (result, errors) ->
      ok result
      p.set 'number', "not_a_number"
      p.validate (result, errors) ->
        ok !result
        QUnit.start()

QUnit.module "Batman.Model: validations"

validationsTestSuite()

QUnit.module "Batman.Model: Validations with I18N",
  setup: ->
    Batman.I18N.enable()
  teardown: ->
    Batman.I18N.disable()

validationsTestSuite()

QUnit.module "Batman.Model: binding to errors"
  setup: ->
    class @Product extends Batman.Model
      @validate 'name', {presence: true}

    @product = new @Product
    @someObject = Batman {product: @product}

asyncTest "errors set length should be observable", 4, ->
  count = 0
  errorsAtCount =
    0: 1
    1: 0

  @product.get('errors').observe 'length', (newLength, oldLength) ->
    equal newLength, errorsAtCount[count++]

  @product.validate (result, errors) =>
    equal errors.get('length'), 1
    @product.set 'name', 'Foo'
    @product.validate (result, errors) =>
      equal errors.get('length'), 0
      QUnit.start()

asyncTest "errors set contents should be observable", 3, ->
  x = @product.get('errors.name')
  x.observe 'length', (newLength, oldLength) ->
    equal newLength, 1

  @product.validate (result, errors) =>
    equal errors.get('length'), 1
    equal errors.length, 1
    QUnit.start()

asyncTest "errors set length should be bindable", 4, ->
  @someObject.accessor 'productErrorsLength', ->
    errors = @get('product.errors')
    errors.get('length')

  equal @someObject.get('productErrorsLength'), 0, 'the errors should start empty'

  @someObject.observe 'productErrorsLength', (newVal, oldVal) ->
    return if newVal == oldVal # Prevents the assertion below when the errors set is cleared and its length goes from 0 to 0
    equal newVal, 1, 'the foreign observer should fire when errors are added'

  @product.validate (result, errors) =>
    equal errors.length, 1, 'the validation shouldn\'t succeed'
    equal @someObject.get('productErrorsLength'), 1, 'the foreign key should have updated'
    QUnit.start()

asyncTest "errors set contents should be bindable", 4, ->
  @someObject.accessor 'productNameErrorsLength', ->
    errors = @get('product.errors.name.length')

  equal @someObject.get('productNameErrorsLength'), 0, 'the errors should start empty'

  @someObject.observe 'productNameErrorsLength', (newVal, oldVal) ->
    return if newVal == oldVal # Prevents the assertion below when the errors set is cleared and its length goes from 0 to 0
    equal newVal, 1, 'the foreign observer should fire when errors are added'

  @product.validate (result, errors) =>
    equal errors.length, 1, 'the validation shouldn\'t succeed'
    equal @someObject.get('productNameErrorsLength'), 1, 'the foreign key should have updated'
    QUnit.start()

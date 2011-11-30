validationsTestSuite = ->
  test "validation shouldn leave the model in the same state it left it", (done) ->
    class Product extends Batman.Model
      @validate 'name', presence: yes

    p = new Product
    oldState = p.state()
    p.validate (result, errors) ->
      assert.equal p.state(), oldState
      done()

  test "length", (done) ->
    class Product extends Batman.Model
      @validate 'exact', length: 5
      @validate 'max', maxLength: 4
      @validate 'range', lengthWithin: [3, 5]

    p = new Product exact: '12345', max: '1234', range: '1234'
    p.validate (result) ->
      assert.ok result

      p.set 'exact', '123'
      p.set 'max', '12345'
      p.set 'range', '12'

      p.validate (result, errors) ->
        assert.ok !result
        assert.equal errors.length, 3
        done()

  test "presence", (done) ->
    class Product extends Batman.Model
      @validate 'name', presence: yes

    p = new Product name: 'nick'
    p.validate (result, errors) ->
      assert.ok result
      p.unset 'name'
      p.validate (result, errors) ->
        assert.ok !result
        done()

  test "presence and length", (done) ->
    class Product extends Batman.Model
      @validate 'name', {presence: yes, maxLength: 10, minLength: 3}

    p = new Product
    p.validate (result, errors) ->
      assert.ok !result
      assert.equal errors.length, 2

      p.set 'name', "beans"
      p.validate (result, errors) ->
        assert.ok result
        assert.equal errors.length, 0
        done()

  test "custom async validations", (done) ->
    letItPass = true
    class Product extends Batman.Model
      @validate 'name', (errors, record, key, callback) ->
        setTimeout ->
          errors.add 'name', "didn't validate" unless letItPass
          callback()
        , 0

    p = new Product
    p.validate (result, errors) ->
      assert.ok result
      letItPass = false
      p.validate (result, errors) ->
        assert.ok !result
        done()

suite "Batman Model", ->
  suite "Validations", ->
    validationsTestSuite()

  suite "Validations with I18N", ->
    setup -> Batman.I18N.enable()
    teardown -> Batman.I18N.disable()

    validationsTestSuite()

  suite "binding to errors", ->
    Product = false
    product = false
    someObject = false

    setup ->
      class Product extends Batman.Model
        @validate 'name', presence: yes

      product = new Product
      someObject = Batman product: product

    test "errors set length should be observable", (done) ->
      product.get('errors').observe 'length', (newLength, oldLength) ->
        return if newLength == oldLength # Prevents the assertion below when the errors set is cleared and its length goes from 0 to 0
        assert.equal newLength, 1

      product.validate (result, errors) ->
        assert.equal errors.get('length'), 1
        assert.equal errors.length, 1
        done()

    test "errors set contents should be observable", (done) ->
      x = product.get('errors.name')
      x.observe 'length', (newLength, oldLength) ->
        assert.equal newLength, 1

      product.validate (result, errors) =>
        assert.equal errors.get('length'), 1
        assert.equal errors.length, 1
        x
        done()

    test "errors set length should be bindable", (done) ->
      someObject.accessor 'productErrorsLength', ->
        errors = @get('product.errors')
        errors.get('length')

      assert.equal someObject.get('productErrorsLength'), 0, 'the errors should start empty'

      someObject.observe 'productErrorsLength', (newVal, oldVal) ->
        return if newVal == oldVal # Prevents the assertion below when the errors set is cleared and its length goes from 0 to 0
        assert.equal newVal, 1, 'the foreign observer should fire when errors are added'

      product.validate (result, errors) =>
        assert.equal errors.length, 1, 'the validation shouldn\'t succeed'
        assert.equal someObject.get('productErrorsLength'), 1, 'the foreign key should have updated'
        done()

    test "errors set contents should be bindable", (done) ->
      someObject.accessor 'productNameErrorsLength', ->
        errors = @get('product.errors.name.length')

      assert.equal someObject.get('productNameErrorsLength'), 0, 'the errors should start empty'

      someObject.observe 'productNameErrorsLength', (newVal, oldVal) ->
        return if newVal == oldVal # Prevents the assertion below when the errors set is cleared and its length goes from 0 to 0
        assert.equal newVal, 1, 'the foreign observer should fire when errors are added'

      product.validate (result, errors) =>
        assert.equal errors.length, 1, 'the validation shouldn\'t succeed'
        assert.equal someObject.get('productNameErrorsLength'), 1, 'the foreign key should have updated'
        done()

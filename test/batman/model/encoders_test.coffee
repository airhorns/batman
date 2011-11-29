suite "Batman.Model", ->
  suite "encoding/decoding", ->
    Product = false
    FlakyProduct = false

    setup ->
      class Product extends Batman.Model
        @encode 'name', 'cost'
        @accessor 'excitingName'
          get: -> @get('name').toUpperCase()

      class FlakyProduct extends Product
        @encode 'broken?'

    test "keys marked for encoding should be encoded",  ->
      p = new Product {name: "Cool Snowboard", cost: 12.99}
      assert.deepEqual p.toJSON(), {name: "Cool Snowboard", cost: 12.99}

    test "undefined keys marked for encoding shouldn't be encoded",  ->
      p = new Product {name: "Cool Snowboard"}
      assert.deepEqual p.toJSON(), {name: "Cool Snowboard"}

    test "accessor keys marked for encoding should be encoded",  ->
      class TestProduct extends Product
        @encode 'excitingName'

      p = new TestProduct {name: "Cool Snowboard", cost: 12.99}
      assert.deepEqual p.toJSON(), {name: "Cool Snowboard", cost: 12.99, excitingName: 'COOL SNOWBOARD'}

    test "keys marked for decoding should be decoded",  ->
      p = new Product
      json = {name: "Cool Snowboard", cost: 12.99}

      p.fromJSON(json)
      assert.equal p.get('name'), "Cool Snowboard"
      assert.equal p.get('cost'), 12.99

    test "falsy keys marked for decoding should be decoded",  ->
      p = new Product
      json = {cost: 0}

      p.fromJSON(json)
      assert.equal p.get('cost'), 0

    test "keys not marked for encoding shouldn't be encoded",  ->
      p = new Product {name: "Cool Snowboard", cost: 12.99, wibble: 'wobble'}
      assert.deepEqual p.toJSON(), {name: "Cool Snowboard", cost: 12.99}

    test "keys not marked for decoding shouldn't be decoded",  ->
      p = new Product
      json = {name: "Cool Snowboard", cost: 12.99, wibble: 'wobble'}

      p.fromJSON(json)
      assert.equal p.get('name'), "Cool Snowboard"
      assert.equal p.get('cost'), 12.99
      assert.equal p.get('wibble'), undefined

    test "models shouldn't encode their primary keys by default",  ->
      p = new Product {id: 10, name: "Cool snowboard"}
      assert.deepEqual p.toJSON(), {name: "Cool snowboard"}

    test "models without any decoders should decode all keys",  ->
      class TestProduct extends Batman.Model

      # No encoders.
      oldDecoders = Batman.Model::_batman.decoders
      Batman.Model::_batman.decoders = new Batman.SimpleHash
      p = new TestProduct
      Batman.developer.suppress ->
        p.fromJSON {name: "Cool Snowboard", cost: 12.99, rails_is_silly: "yup"}

      assert.equal p.get('name'), "Cool Snowboard"
      assert.equal p.get('cost'), 12.99
      assert.equal p.get('rails_is_silly'), 'yup'
      Batman.Model::_batman.decoders = oldDecoders

    test "key ending with ? marked for encoding should be encoded",  ->
      p = new FlakyProduct {name: "Vintage Snowboard", cost: 122.99, "broken?": true}
      assert.deepEqual p.toJSON(), {name: "Vintage Snowboard", cost: 122.99, "broken?": true}

    test "key ending with ? marked for decoding should be decoded",  ->
      p = new FlakyProduct
      json = {name: "Vintage Snowboard", cost: 122.99, "broken?": true}

      p.fromJSON(json)
      assert.ok p.get('broken?'), "Cool Snowboard"

    suite "custom encoders/decoders", ->
      Product = false
      setup ->
        class Product extends Batman.Model
          @encode 'name', (unencoded) -> unencoded.toUpperCase()

          @encode 'date',
            encode: (unencoded) -> "zzz"
            decode: (encoded) -> "yyy"

      test "custom encoders with an encode and a decode implementation should be recognized",  ->
        p = new Product(date: "clobbered")
        assert.deepEqual p.toJSON(), {date: "zzz"}

        json =   p = new Product
        p.fromJSON({date: "clobbered"})
        assert.equal p.get('date'), "yyy"

      test "custom encoders should receive the value to be encoded, the key it's from, the JSON being built, and the source object",  ->
        Product.encode 'date',
          encode: (val, key, object, record) ->
            assert.equal val, "some date"
            assert.equal key, "date"
            assert.deepEqual object, {}
            assert.equal record, p
            return 'foo bar'

        p = new Product(date: "some date")
        p.toJSON()

      test "custom decoders should receive the value to decode, the key in the data it's from, the JSON being decoded, the object about to be mixed in, and the record",  ->
        Product.encode 'date',
          decode: (val, key, json, object, record) ->
            assert.equal val, "some date"
            assert.equal key, 'date'
            assert.deepEqual json, {date: "some date"}
            assert.deepEqual object, {}
            assert.equal record, p

        p = new Product()
        p.fromJSON(date: "some date")

      test "passing a function should shortcut to passing an encoder",  ->
        p = new Product(name: "snowboard")
        assert.deepEqual p.toJSON(), {name: "SNOWBOARD"}

      test "passing false should not attach an encoder or decoder for that key",  ->
        class TestProduct extends Batman.Model
          @encode 'name',
            encode: false
            decode: (x) -> x

          @encode 'date',
            encode: (x) -> x
            decode: false

        decoded = new TestProduct()
        decoded.fromJSON(name: "snowboard", date: "10/10/2010")
        assert.equal decoded.get('date'), undefined
        assert.equal decoded.get('name'), "snowboard"

        encoded = new TestProduct(name: "snowboard", date: "10/10/2010")
        assert.deepEqual encoded.toJSON(), {date: "10/10/2010"}

QUnit.module "Batman.Model: encoding/decoding to/from JSON"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', 'cost'
      @accessor 'excitingName'
        get: -> @get('name').toUpperCase()
    class @FlakyProduct extends @Product
      @encode 'broken?'

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

test "models shouldn't encode their primary keys by default", ->
  p = new @Product {id: 10, name: "Cool snowboard"}
  deepEqual p.toJSON(), {name: "Cool snowboard"}

test "models without any decoders should decode all keys", ->

  class TestProduct extends Batman.Model

  # No encoders.
  oldDecoders = Batman.Model::_batman.decoders
  Batman.Model::_batman.decoders = new Batman.SimpleHash
  p = new TestProduct
  Batman.developer.suppress ->
    p.fromJSON {name: "Cool Snowboard", cost: 12.99, rails_is_silly: "yup"}

  equal p.get('name'), "Cool Snowboard"
  equal p.get('cost'), 12.99
  equal p.get('rails_is_silly'), 'yup'
  Batman.Model::_batman.decoders = oldDecoders

test "key ending with ? marked for encoding should be encoded", ->
  p = new @FlakyProduct {name: "Vintage Snowboard", cost: 122.99, "broken?": true}
  deepEqual p.toJSON(), {name: "Vintage Snowboard", cost: 122.99, "broken?": true}

test "key ending with ? marked for decoding should be decoded", ->
  p = new @FlakyProduct
  json = {name: "Vintage Snowboard", cost: 122.99, "broken?": true}

  p.fromJSON(json)
  ok p.get('broken?'), "Cool Snowboard"

QUnit.module "Batman.Model: encoding: custom encoders/decoders"
  setup: ->
    class @Product extends Batman.Model
      @encode 'name', (unencoded) -> unencoded.toUpperCase()

      @encode 'date',
        encode: (unencoded) -> "zzz"
        decode: (encoded) -> "yyy"

test "custom encoders with an encode and a decode implementation should be recognized", ->
  p = new @Product(date: "clobbered")
  deepEqual p.toJSON(), {date: "zzz"}

  json =   p = new @Product
  p.fromJSON({date: "clobbered"})
  equal p.get('date'), "yyy"

test "passing a function should shortcut to passing an encoder", ->
  p = new @Product(name: "snowboard")
  deepEqual p.toJSON(), {name: "SNOWBOARD"}

test "passing false should not attach an encoder or decoder for that key", ->
  class TestProduct extends Batman.Model
    @encode 'name',
      encode: false
      decode: (x) -> x

    @encode 'date',
      encode: (x) -> x
      decode: false

  decoded = new TestProduct()
  decoded.fromJSON(name: "snowboard", date: "10/10/2010")
  equal decoded.get('date'), undefined
  equal decoded.get('name'), "snowboard"

  encoded = new TestProduct(name: "snowboard", date: "10/10/2010")
  deepEqual encoded.toJSON(), {date: "10/10/2010"}

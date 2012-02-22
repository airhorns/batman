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

test "falsy keys marked for decoding should be decoded", ->
  p = new @Product
  json = {cost: 0}

  p.fromJSON(json)
  equal p.get('cost'), 0

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

QUnit.module "Batman.Model: encoding/decoding to/from JSON with custom primary Key"
  setup: ->
    class @Product extends Batman.Model
      @set 'primaryKey', '_id'

test "undefined primaryKey shouldn't be encoded", ->
  p = new @Product
  deepEqual p.toJSON(), {}

test "defined primaryKey shouldn't be encoded", ->
  p = new @Product("deadbeef")
  deepEqual p.toJSON(), {}

test "defined primaryKey should be decoded", ->
  json = {_id: "deadbeef"}
  p = new @Product()
  p.fromJSON(json)
  equal p.get('id'), "deadbeef"
  equal p.get('_id'), "deadbeef"

test "the old primaryKey should not be decoded", ->
  json = {id: 10}
  p = new @Product()
  p.fromJSON(json)
  equal p.get('id'), undefined
  equal p.get('_id'), undefined

test "primary key encoding can be opted into", ->
  @Product.encode '_id' # Tell the product to both encode and decode '_id'
  p = new @Product("deadbeef")
  deepEqual p.toJSON(), {_id: "deadbeef"}

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

test "custom encoders should receive the value to be encoded, the key it's from, the JSON being built, and the source object", 4, ->
  @Product.encode 'date',
    encode: (val, key, object, record) ->
      equal val, "some date"
      equal key, "date"
      deepEqual object, {}
      equal record, p
      return 'foo bar'

  p = new @Product(date: "some date")
  p.toJSON()

test "custom decoders should receive the value to decode, the key in the data it's from, the JSON being decoded, the object about to be mixed in, and the record", 5, ->
  @Product.encode 'date',
    decode: (val, key, json, object, record) ->
      equal val, "some date"
      equal key, 'date'
      deepEqual json, {date: "some date"}
      deepEqual object, {}
      equal record, p

  p = new @Product()
  p.fromJSON(date: "some date")

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

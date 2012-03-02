Batman = require '../../../../lib/batman'
Watson = require 'watson'
TestStorageAdapter = require '../lib/test_storage_adapter'

Watson.ensureCommitted 'v0.6.1', ->
  class Product extends Batman.Model
    constructor: ->
      super
      @set 'name', "Cool Snowboard"
      @set 'cost', 10

    @encode 'name', 'cost'
    @persist TestStorageAdapter

  Watson.trackMemory 'model memory usage', 2000, (i) ->
    (new Product).save (err) -> throw err if err
    if i % 500 == 0
      Product.get('loaded').forEach (p) -> p.destroy (err) -> throw err if err

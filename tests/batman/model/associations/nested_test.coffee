{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter} = if typeof require isnt 'undefined' then require '../model_helper' else window
helpers = if typeof require is 'undefined' then window.viewHelpers else require '../../view/view_helper'

QUnit.module "Batman.Model nested associations"
  setup: ->
    namespace = @

    class @Store extends Batman.Model
      @encode 'id', 'name'
      @hasOne 'product', namespace: namespace

    @storeAdapter = createStorageAdapter @Store, AsyncTestStorageAdapter,
      'stores1': {name: "Store One", id: 1}
      'stores2':
        name: "Store Two"
        id: 2,
        product:
          id:2
          name:"JSON Product"
          variant:
            id: 2
            name: "JSON Variant 2"

    class @Product extends Batman.Model
      @encode 'id', 'name'
      @hasOne 'variant', namespace: namespace

    @productAdapter = createStorageAdapter @Product, AsyncTestStorageAdapter,
      'products1': {name: "Product One", id: 1, store_id: 1}

    class @Variant extends Batman.Model
      @encode 'id', 'name'

    @variantAdapter = createStorageAdapter @Variant, AsyncTestStorageAdapter,
      'variants1': {id: 1, name: "Variant 1", product_id: 1}

asyncTest "nested association URLs using IDs", ->
  @Store.find 1, (err, store) =>
    url = store.relationURL('product.variant')
    equal url, "/stores/1/products/1/variants/1"
    QUnit.start()

asyncTest "nested association URLs using inline JSON", ->
  @Store.find 2, (err, store) =>
    url = store.relationURL('product.variant')
    equal url, "/stores/2/products/2/variants/2"
    QUnit.start()


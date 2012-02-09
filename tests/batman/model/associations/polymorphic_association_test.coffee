{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter} = if typeof require isnt 'undefined' then require '../model_helper' else window
helpers = if typeof require is 'undefined' then window.viewHelpers else require '../../view/view_helper'

QUnit.module "Batman.Model polymorphic belongsTo and hasMany Associations"
  setup: ->
    namespace = @namespace = {}
    namespace.Metafield = class @Metafield extends Batman.Model
      @belongsTo 'subject', {polymorphic: true, namespace}
      @encode 'id', 'key'

    @metafieldAdapter = createStorageAdapter @Metafield, AsyncTestStorageAdapter,
      'metafields1':
        id: 1
        subject_id: 1
        subject_type: 'Store'
        key: 'Store metafield'
      'metafields2':
        id: 2
        subject_id: 1
        subject_type: 'Product'
        key: 'Product metafield'
      'metafields3':
        id: 3
        subject_id: 1
        subject_type: 'Store'
        key: 'Store metafield 2'
      'metafields4':
        id: 4
        key: 'Product metafield 2'
        subject_type: 'Product'
        subject:
          name: "Product 5"
          id: 5

    namespace.Store = class @Store extends Batman.Model
      @encode 'id', 'name'
      @hasMany 'metafields', {as: 'subject', namespace}

    @storeAdapter = createStorageAdapter @Store, AsyncTestStorageAdapter,
      'stores1':
        name: "Store One"
        id: 1
      'stores2':
        name: "Store Two"
        id: 2
        metafields: [{
          id: 5
          key: "SEO Title"
        }]

    namespace.Product = class @Product extends Batman.Model
      @encode 'id', 'name'
      @hasMany 'metafields', {as: 'subject', namespace}

    @productAdapter = createStorageAdapter @Product, AsyncTestStorageAdapter,
      'products1':
        name: "Product One"
        id: 1
        store_id: 1
      'products4':
        name: "Product One"
        id: 1
        metafields: [{
          id: 6
          key: "SEO Title"
        }]

asyncTest "belongsTo associations are loaded from remote", 4, ->
  @Metafield.find 1, (err, metafield) =>
    throw err if err
    metafield.get('subject').load (err, store) =>
      throw err if err
      ok store instanceof @Store
      equal store.get('id'), 1
      @Metafield.find 2, (err, metafield) =>
        throw err if err
        metafield.get('subject').load (err, product) =>
          throw err if err
          ok product instanceof @Product
          equal product.get('id'), 1
          QUnit.start()

asyncTest "belongsTo associations are loaded from inline json", 2, ->
  @Metafield.find 4, (err, metafield) =>
    throw err if err
    product = metafield.get('subject')
    equal product.get('name'), "Product 5"
    equal product.get('id'), 5
    QUnit.start()

asyncTest "hasMany associations are loaded from remote", 5, ->
  @Store.find 1, (err, store) =>
    throw err if err
    metafields = store.get('metafields')
    delay =>
      array = metafields.toArray()
      equal array.length, 2
      equal array[0].get('key'), "Store metafield"
      equal array[0].get('id'), 1
      equal array[1].get('key'), "Store metafield 2"
      equal array[1].get('id'), 3

asyncTest "hasMany associations are loaded from inline json", 3, ->
  @Store.find 2, (err, store) =>
    throw err if err
    metafields = store.get('metafields')
    array = metafields.toArray()
    equal array.length, 1
    equal array[0].get('key'), 'SEO Title'
    equal array[0].get('id'), 5
    QUnit.start()

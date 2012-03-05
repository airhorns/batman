{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter, generateSorterOnProperty} = if typeof require isnt 'undefined' then require '../model_helper' else window
helpers = if typeof require is 'undefined' then window.viewHelpers else require '../../view/view_helper'

baseSetup = ->
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
      'metafields7':
        id: 7
        key: 'Product metafield 2.1'
        subject_type: 'Product'
        subject:
          name: "Product 5"
          id: 5
      'metafields20':
          id: 20
          key: "SEO Title"
      'metafields30':
          id: 30
          key: "SEO Title"

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
      'products5':
        name: "Product 5"
        id: 5
      'products6':
        name: "Product Six"
        id: 6
        metafields: [{
          id: 20
          key: "SEO Title"
        },{
          id: 30
          key: "SEO Title"
        }]

QUnit.module "Batman.Model polymorphic belongsTo associations"
  setup: baseSetup

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

asyncTest "belongsTo associations are saved", ->
  metafield = new @Metafield id: 10, key: "SEO Title"
  store = new @Store id: 11, name: "Store 11"
  metafield.set 'subject', store
  metafield.save (err, record) =>
    throw err if err
    equal record.get('subject_id'), 11
    equal record.get('subject_type'), 'Store'
    storedJSON = @metafieldAdapter.storage["metafields10"]
    deepEqual storedJSON, metafield.toJSON()
    QUnit.start()

asyncTest "belongsTo supports inline saving", 1, ->
  namespace = @namespace
  class @InlineMetafield extends Batman.Model
    @encode 'key'
    @belongsTo 'subject', {namespace, saveInline: true, polymorphic: true}

  namespace.Store = class @Store extends Batman.Model
    @encode 'name'

  storageAdapter = createStorageAdapter @InlineMetafield, AsyncTestStorageAdapter

  metafield = new @InlineMetafield key: "SEO Title"
  store = new @Store name: "Inline Store"
  metafield.set 'subject', store
  metafield.save (err, record) =>
    deepEqual storageAdapter.storage["inline_metafields#{record.get('id')}"],
      key: "SEO Title"
      subject: {name: "Inline Store"}
      subject_type: 'Store'
    QUnit.start()

asyncTest "belongsTo parent models are added to the identity map", 1, ->
  @Metafield.find 4, (err, metafield) =>
    throw err if err
    equal @Product.get('loaded').length, 1
    QUnit.start()

asyncTest "belongsTo parent models are passed through the identity map", 2, ->
  @Product.find 5, (err, product) =>
    throw err if err
    @Metafield.find 4, (err, metafield) =>
      equal @Product.get('loaded').length, 1
      ok metafield.get('subject') == product
      QUnit.start()

asyncTest "belongsTo supports custom foreign keys", 2, ->
  namespace = @namespace
  class SillyMetafield extends Batman.Model
    @encode 'id', 'key'
    @belongsTo 'doodad', {namespace, foreignKey: 'subject_id', polymorphic: true}

  sillyMetafieldAdapter = createStorageAdapter SillyMetafield, AsyncTestStorageAdapter,
    'silly_metafields1':
      id: 1
      key: 'SEO Title'
      subject_id: 1
      doodad_type: 'Store'

  SillyMetafield.find 1, (err, metafield) ->
    store = metafield.get('doodad')
    delay ->
      equal store.get('id'), 1
      equal store.get('name'), 'Store One'

asyncTest "belongsTo supports custom type keys", 2, ->
  namespace = @namespace
  class SillyMetafield extends Batman.Model
    @encode 'id', 'key'
    @belongsTo 'subject', {namespace, foreignTypeKey: 'doodad_type', polymorphic: true}

  sillyMetafieldAdapter = createStorageAdapter SillyMetafield, AsyncTestStorageAdapter,
    'silly_metafields1':
      id: 1
      key: 'SEO Title'
      subject_id: 1
      doodad_type: 'Store'

  SillyMetafield.find 1, (err, metafield) ->
    store = metafield.get('subject')
    delay ->
      equal store.get('id'), 1
      equal store.get('name'), 'Store One'

QUnit.module "Batman.Model polymorphic belongsTo associations with inverseof to a hasMany"
  setup: ->
    baseSetup.call(@)
    namespace = @namespace
    # Redefine models with the inverseof relationship inplace from the start.
    namespace.Metafield = class @Metafield extends Batman.Model
      @encode 'key'
      @belongsTo 'subject', {namespace, polymorphic: true, inverseOf: 'metafields'}
    @Metafield.persist @metafieldAdapter
    namespace.Product = class @Product extends Batman.Model
        @encode 'id', 'name'
        @hasMany 'metafields', {as: 'subject', namespace}
    @Product.persist @productAdapter

asyncTest "belongsTo sets the foreign key on itsself so the parent relation SetIndex adds it, if the parent hasn't been loaded", 1, ->
  @Metafield.find 4, (err, metafield) =>
    throw err if err
    product = metafield.get('subject')
    delay ->
      ok product.get('metafields').has(metafield)

asyncTest "belongsTo sets the foreign key on itself so the parent relation SetIndex adds it, if the parent has already been loaded", 1, ->
  @Product.find 5, (err, product) =>
    throw err if err
    @Metafield.find 4, (err, metafield) =>
      throw err if err
      product = metafield.get('subject')
      delay ->
        ok product.get('metafields').has(metafield)

asyncTest "belongsTo sets the foreign key foreign key on itself such that many loads are picked up by the parent", 3, ->
  @Product.find 5, (err, product) =>
    throw err if err
    @Metafield.find 4, (err, metafield) =>
      throw err if err
      equal product.get('metafields').length, 1
      @Metafield.find 7, (err, metafield) =>
        throw err if err
        equal product.get('metafields').length, 2
        equal @Product.get('loaded').length, 1, 'Only one parent record should be created'
        QUnit.start()

QUnit.module "Batman.Model polymorphic hasMany associations"
  setup: baseSetup

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

asyncTest "hasMany associations are saved via the parent model", 7, ->
  store = new @Store name: 'Zellers'
  metafield1 = new @Metafield key: 'Gizmo'
  metafield2 = new @Metafield key: 'Gadget'
  store.set 'metafields', new Batman.Set(metafield1, metafield2)

  storeSaveSpy = spyOn store, 'save'
  store.save (err, record) =>
    throw err if err
    equal storeSaveSpy.callCount, 1
    equal metafield1.get('subject_id'), record.id
    equal metafield1.get('subject_type'), 'Store'
    equal metafield2.get('subject_id'), record.id
    equal metafield2.get('subject_type'), 'Store'

    @Store.find record.id, (err, store2) =>
      throw err if err
      storedJSON = @storeAdapter.storage["stores#{record.id}"]
      deepEqual store2.toJSON(), storedJSON
      # hasMany saves inline by default
      sorter = generateSorterOnProperty('key')
      deepEqual sorter(storedJSON.metafields), sorter([
        {key: "Gizmo", subject_id: record.id, subject_type: 'Store'}
        {key: "Gadget", subject_id: record.id, subject_type: 'Store'}
      ])
      QUnit.start()

asyncTest "hasMany associations are saved via the child model", 3, ->
  @Store.find 1, (err, store) =>
    throw err if err
    metafield = new @Metafield key: 'Store Metafield'
    metafield.set 'subject', store
    metafield.save (err, savedMetafield) ->
      throw err if err
      equal savedMetafield.get('subject_id'), store.id
      equal savedMetafield.get('subject_type'), 'Store'
      metafields = store.get('metafields')
      ok metafields.has(savedMetafield)
      QUnit.start()

asyncTest "hasMany associations should index the loaded set", 3, ->
  @Product.find 4, (err, product) =>
    throw err if err
    metafields = product.get('metafields')
    ok metafields instanceof Batman.AssociationSet
    equal metafields.get('length'), 1
    metafield = new @Metafield(subject_id: 4, subject_type: 'Product', key: "Test Metafield")
    metafield.save (err) ->
      throw err if err
      equal metafields.get('length'), 2
      QUnit.start()

asyncTest "hasMany child models are added to the identity map", 2, ->
  equal @Metafield.get('loaded').length, 0
  @Product.find 4, (err, product) =>
    equal @Metafield.get('loaded').length, 1
    QUnit.start()

asyncTest "unsaved hasMany models should accept associated children", 2, ->
  product = new @Product
  metafields = product.get('metafields')
  delay =>
    equal metafields.length, 0
    metafield = new @Metafield
    metafields.add metafield
    equal metafields.length, 1

asyncTest "unsaved hasMany models should save their associated children", 4, ->
  product = new @Product(name: "Hello!")
  metafields = product.get('metafields')
  metafield = new @Metafield(key: "test")
  metafields.add metafield

  # Mock out what a realbackend would do: assign ids to the child records
  # The TestStorageAdapter is smart enough to do this for the parent, but not the children.
  @productAdapter.create = (record, options, callback) ->
    id = record.set('id', @counter++)
    if id
      @storage[@storageKey(record) + id] = record.toJSON()
      record.fromJSON
        id: id
        metafields: [{
          key: "test"
          id: 12
        }]
      callback(undefined, record)
    else
      callback(new Error("Couldn't get record primary key."))

  product.save (err, product) =>
    throw err if err
    storedJSON = @productAdapter.storage["products#{product.get('id')}"]
    deepEqual storedJSON,
      id: 11
      name: "Hello!"
      metafields:[
        {key: "test", subject_id: product.get('id'), subject_type: 'Product'}
      ]

    ok !product.isNew()
    ok !metafield.isNew()
    equal metafield.get('subject_id'), product.get('id')
    QUnit.start()

asyncTest "unsaved hasMany models should reflect their associated children after save", 3, ->
  product = new @Product(name: "Hello!")
  metafields = product.get('metafields')
  metafield = new @Metafield(key: "test")
  metafields.add metafield

  # Mock out what a realbackend would do: assign ids to the child records
  # The TestStorageAdapter is smart enough to do this for the parent, but not the children.
  @productAdapter.create = (record, options, callback) ->
    id = record.set('id', @counter++)
    if id
      @storage[@storageKey(record) + id] = record.toJSON()
      record.fromJSON
        id: id
        metafields: [{
          key: "test"
          id: 12
        }]
      callback(undefined, record)
    else
      callback(new Error("Couldn't get record primary key."))

  product.save (err, product) =>
    throw err if err
    # Mock out what a realbackend would do: assign ids to the child records
    # The TestStorageAdapter is smart enough to do this for the parent, but not the children.
    equal product.get('metafields.length'), 1
    ok product.get('metafields').has(metafield)
    equal metafields.get('length'), 1
    QUnit.start()

asyncTest "hasMany sets the foreign key on the inverse relation if the children haven't been loaded", 3, ->
  @Product.find 6, (err, product) =>
    throw err if err
    metafields = product.get('metafields')
    delay ->
      metafields = metafields.toArray()
      equal metafields.length, 2
      ok metafields[0].get('subject') == product
      ok metafields[1].get('subject') == product

asyncTest "hasMany sets the foreign key on the inverse relation if the children have already been loaded", 3, ->
  @Metafield.load (err, metafields) =>
    throw err if err
    @Product.find 6, (err, product) =>
      throw err if err
      metafields = product.get('metafields')
      delay ->
        metafields = metafields.toArray()
        equal metafields.length, 2
        ok metafields[0].get('subject') == product
        ok metafields[1].get('subject') == product


{createStorageAdapter, TestStorageAdapter, AsyncTestStorageAdapter} = if typeof require isnt 'undefined' then require '../model_helper' else window
helpers = if typeof require is 'undefined' then window.viewHelpers else require '../../view/view_helper'

QUnit.module "Batman.Model Associations",
  setup: ->
    @oldApp = Batman.currentApp

  teardown: ->
    Batman.currentApp = @oldApp

test "association macros without options", ->
  app = Batman.currentApp = {}
  class app.Card extends Batman.Model
    @belongsTo 'deck'
  class app.Deck extends Batman.Model
    @hasMany 'cards'
    @belongsTo 'player'
  class app.Player extends Batman.Model
    @hasOne 'deck'

  player = new app.Player
  deck = new app.Deck
  card = new app.Card

  ok player.get('deck') instanceof Batman.HasOneProxy
  ok deck.get('player') instanceof Batman.BelongsToProxy
  ok deck.get('cards') instanceof Batman.AssociationSet
  ok card.get('deck') instanceof Batman.BelongsToProxy

asyncTest "support custom model namespaces and class names", 2, ->
  namespace = {}
  class namespace.Walmart extends Batman.Model
    @encode 'name', 'id'

  class Product extends Batman.Model
    @belongsTo 'store',
      namespace: namespace
      name: 'Walmart'
    @encode 'name', 'id'

  productAdapter = createStorageAdapter Product, AsyncTestStorageAdapter,
    'products2': {name: "Product Two", id: 2, store: {id:3, name:"JSON Store"}}

  Product.find 2, (err, product) ->
    store = product.get('store')
    ok store instanceof namespace.Walmart
    equal store.get('id'), 3
    QUnit.start()

asyncTest "associations can be inherited", 2, ->
  namespace = {}
  class namespace.Store extends Batman.Model
    @encode 'name', 'id'

  class namespace.TestModel extends Batman.Model
    @belongsTo 'store', {namespace: namespace, autoload: false}

  class namespace.Product extends namespace.TestModel
    @encode 'name', 'id'

  storeAdapter = createStorageAdapter namespace.Store, AsyncTestStorageAdapter,
    'stores2': {name: "Store Two", id: 2}

  product = new namespace.Product({id: 2, store_id: 2})
  product.get('store').load (err, store) ->
    throw err if err
    ok store instanceof namespace.Store
    equal store.get('name'), "Store Two"
    QUnit.start()

asyncTest "support model classes that haven't been loaded yet", 2, ->
  namespace = this
  class @Blog extends Batman.Model
    @encode 'id', 'name'
    @hasOne 'customer', namespace: namespace
  blogAdapter = createStorageAdapter @Blog, AsyncTestStorageAdapter,
    'blogs1': {name: "Blog One", id: 1}

  setTimeout (=>
    class @Customer extends Batman.Model
      @encode 'id', 'name'
      @belongsTo 'blog'
    customerAdapter = new AsyncTestStorageAdapter @Customer
    customerAdapter.storage =
      'customer1': {name: "Customer One", id: 1, blog_id: 1}
    @Customer.persist customerAdapter

    @Blog.find 1, (err, blog) =>
      customer = blog.get 'customer'
      delay ->
        equal customer.get('id'), 1
        equal customer.get('name'), 'Customer One'
  ), ASYNC_TEST_DELAY

asyncTest "models can save while related records are loading", 1, ->
  namespace = this
  class @Store extends Batman.Model
    @hasOne 'product', namespace: namespace
  storeAdapter = createStorageAdapter @Store, AsyncTestStorageAdapter,
    "stores1": {id: 1, name: "Store One", product: {id: 1, name: "JSON product"}}

  class @Product extends Batman.Model
    @encode 'name'

  productAdapter = createStorageAdapter @Product, AsyncTestStorageAdapter

  Batman.developer.suppress =>
    @Store.find 1, (err, store) ->
      product  = store.get 'product'
      product._batman.state = 'loading'
      store.save (err, savedStore) ->
        ok !err
        QUnit.start()

asyncTest "inline saving can be disabled", 1, ->
  namespace = this

  class @Store extends Batman.Model
    @hasMany 'products',
      namespace: namespace
      saveInline: false

  @storeAdapter = createStorageAdapter @Store, AsyncTestStorageAdapter,
    "stores1": {id: 1, name: "Store One"}

  class @Product extends Batman.Model
    @encode 'name'

  @productAdapter = createStorageAdapter @Product, AsyncTestStorageAdapter

  @Store.find 1, (err, store) =>
    store.set 'products', new Batman.Set(new @Product)
    store.save (err, savedStore) =>
      equal @storeAdapter.storage.stores1["products"], undefined
      QUnit.start()

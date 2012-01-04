QUnit.module 'Batman.Dispatcher getting paths'
  setup: ->
    class @App extends Batman.App
      @resources 'products'
      @route 'foo/bar/:id'

    class @App.Product extends Batman.Model

    @dispatcher = new Batman.Dispatcher(@App)

test "paramsFromArgument gets record params", ->
  deepEqual Batman.Dispatcher.paramsFromArgument(new @App.Product(id: 1)), {resource: 'products', action: 'show', id: 1}

test "paramsFromArgument gets model params", ->
  deepEqual Batman.Dispatcher.paramsFromArgument(@App.Product), {resource: 'products', action: 'index'}

test "paramsFromArgument gets record proxy params", ->
  proxy = new Batman.AssociationProxy({}, @App.Product)
  proxy.accessor 'target', => new @App.Product(id: 2)
  proxy.set 'loaded', true
  deepEqual Batman.Dispatcher.paramsFromArgument(proxy), {resource: 'products', action: 'show', id: 2}

test "paramsFromArgument leaves strings alone", ->
  deepEqual Batman.Dispatcher.paramsFromArgument("/products/1"), "/products/1"

test "paramsFromArgument leaves objects alone", ->
  deepEqual Batman.Dispatcher.paramsFromArgument({controller: "products", action: "new"}), {controller: "products", action: "new"}

QUnit.module 'Batman.Dispatcher defining routes',
  setup: ->
    class @App extends Batman.App
      @layout: null
      @test: (url) ->
        @run() if not @hasRun
        {controller, action} = @dispatcher.findRoute(url).get('action')
        @controllers.get("#{controller}.#{action}")

    class @App.TestController extends Batman.Controller
      index: -> @render false
      index2: -> @render false

    class @App.Product extends Batman.Model
    class @App.ProductsController extends Batman.Controller
      index: -> @render false
      show: (params) ->
        equal params.id, 1, 'id is correct'
        @render false
        QUnit.start()
      edit: -> @render false
  teardown: ->
    @App.stop()

test 'controller aliases', ->
  @App.dispatcher = new Batman.Dispatcher @App
  equal @App.get('controllers.products'), @App.ProductsController.get('sharedController')

test 'simple route match', ->
  @App.route 'products', 'test#index'
  @App.route '/products2', 'test#index2'
  @App.route 'products3', 'test'

  equal @App.test('products'), @App.TestController::index
  equal @App.test('/products2'), @App.TestController::index2
  equal @App.test('products3'), @App.TestController::index

test 'simple root match', ->
  @App.root 'test#index'
  equal @App.test('/'), @App.TestController::index

asyncTest 'redirecting', 1, ->
  @App.route 'foo', ->
    ok true, 'route called'
    QUnit.start()
  @App.run()

  $redirect '/foo'

asyncTest 'redirecting with params', ->
  @App.route 'products/:id', 'products#show'
  @App.run()
  $redirect controller: 'products', action: 'show', id: '1'

asyncTest 'redirecting to a record', 1, ->
  @App.resources 'products'
  @App.run()
  @product = new @App.Product(id: 1)

  $redirect @product

asyncTest 'redirecting to a model class', 1, ->
  @App.resources 'products'
  @App.run()

  @App.ProductsController::index = ->
    @render false
    ok 'index redirected to'
    QUnit.start()

  $redirect @App.Product

asyncTest 'param matching', ->
  @App.route 'test/:id', 'products#show'
  equal @App.test('test/1'), @App.ProductsController::show

  $redirect 'test/1'

asyncTest 'splat matching', ->
  @App.route '/*first/fixed/:id/*last', (params) ->
    equal params.url, url
    equal params.first, 'x/y'
    equal params.id, '10'
    equal params.last, 'foo/bar'
    QUnit.start()
  @App.run()

  $redirect url = '/x/y/fixed/10/foo/bar'

asyncTest 'query params', 7, ->
  hasCalledRoute = no
  @App.root (params) ->

    equal params.url, '/'
    equal params.foo, 'bar'
    equal params.x, 'true'

    if hasCalledRoute
      equal params.bar, 'baz'
      QUnit.start()
    else
      hasCalledRoute = yes
      params.bar = 'baz'
      $redirect params

  @App.run()

  $redirect '/?foo=bar&x=true'

asyncTest 'route match with default params', 2, ->
  @App.root controller: 'test', action: 'index'
  @App.route 'show', controller: 'products', action: 'show', id: 1

  equal @App.test('/'), @App.TestController::index
  $redirect '/show'

asyncTest 'resources', ->
  class @App.ImagesController extends Batman.Controller
    index: (params) ->
      equal params.productId, 1, 'index correct'
      @redirect 'products/1/images/2'
    show: (params) ->
      equal params.productId, 1, 'show product correct'
      equal params.id, 2, 'show image correct'
      @redirect 'products/1'

  @App.resources 'products', ->
    @resources 'images'
    @collection ->
      @route 'testCollection'
    @member ->
      @route 'test', 'testMember'

  @App.ProductsController::testCollection = -> @render false
  @App.ProductsController::testMember = -> @render false

  equal @App.test('products'), @App.ProductsController::index
  equal @App.test('products/new'), null
  equal @App.test('products/1'), @App.ProductsController::show
  equal @App.test('products/1/edit'), @App.ProductsController::edit

  equal @App.test('products/testCollection'), @App.ProductsController::testCollection
  equal @App.test('products/1/test'), @App.ProductsController::testMember

  $redirect 'products/1/images'

test 'multiple resources', 2, ->
  tracker =
    products: false
    images: false

  @App.resources 'products', 'images', ->
    tracker[@resource] = true

  ok tracker.products
  ok tracker.images

asyncTest 'hash history', 1, ->
  Batman.config.usePushState = false
  class @App extends Batman.App
  @App.route 'test', ->
    window.location.hash = '#!/test2'
  @App.route 'test2', ->
    ok true, 'routes called'
    QUnit.start()

  @App.run()

  window.location.hash = '#!/test'

if Batman.PushStateNavigator.isSupported()
  asyncTest 'state history', 1, ->
    @App.route 'test', ->
      Batman.redirect "/test2"
    @App.route 'test2', ->
      ok true, 'routes called'
      QUnit.start()
    @App.run()

    Batman.redirect '/test'

asyncTest '404', 1, ->
  @App.route '404', ->
    ok true, '404 called'
    QUnit.start()
  @App.run()

  $redirect 'something/random'

asyncTest '404 when redirecting to a record', 1, ->
  @App.route '404', ->
    ok true, '404 called'
    QUnit.start()
  @App.run()
  @product = new @App.Product(id: 1)
  $redirect @product

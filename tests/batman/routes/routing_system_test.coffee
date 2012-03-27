QUnit.module 'Batman.Route: all together now',
  setup: ->
    class @App extends Batman.App
      @layout: null
      @test: (url) ->
        route = @get('dispatcher').routeForParams(url)
        @get("controllers.#{route.get('controller')}.#{route.get('action')}")

    class @App.TestController extends Batman.Controller
      index: -> @render false
      index2: -> @render false

    class @App.Product extends Batman.Model
    class @App.ProductsController extends Batman.Controller
      index: -> @render false
      show: (params) ->
        equal params.id, '1', 'id is correct'
        @render false
        QUnit.start()
      edit: -> @render false

  teardown: ->
    @App.stop()

test 'simple route match', ->
  @App.route 'products', 'test#index'
  @App.route '/products2', 'test#index2'
  @App.route 'products3', 'test'

  equal @App.test('/products'), @App.TestController::index
  equal @App.test('/products2'), @App.TestController::index2
  equal @App.test('/products3'), @App.TestController::index

test 'simple root match', ->
  @App.root 'test#index'
  equal @App.test('/'), @App.TestController::index

asyncTest 'redirecting', 1, ->
  @App.route 'foo', ->
    ok true, 'route called'
    QUnit.start()
  @App.run()

  Batman.redirect '/foo'

asyncTest 'redirecting with params', ->
  @App.route 'products/:id', 'products#show'
  @App.run()
  Batman.redirect controller: 'products', action: 'show', id: '1'

asyncTest 'redirecting to a record', 1, ->
  @App.resources 'products'
  @App.run()
  @product = new @App.Product(id: 1)

  Batman.redirect @product

asyncTest 'redirecting to a model class', 1, ->
  @App.resources 'products'
  @App.run()

  @App.ProductsController::index = ->
    @render false
    ok 'index redirected to'
    QUnit.start()

  Batman.redirect @App.Product

test 'param matching', ->
  @App.route '/test/:id', 'products#show'
  equal @App.test('/test/1'), @App.ProductsController::show

asyncTest 'splat matching', ->
  @App.route '/*first/fixed/:id/*last', (params) ->
    equal params.path, path
    equal params.first, 'x/y'
    equal params.id, '10'
    equal params.last, 'foo/bar'
    QUnit.start()

  @App.run()

  Batman.redirect path = '/x/y/fixed/10/foo/bar'

asyncTest 'query params', 7, ->
  hasCalledRoute = no
  @App.root (params) ->

    equal params.path, '/'
    equal params.foo, 'bar'
    equal params.x, 'true'

    if hasCalledRoute
      equal params.bar, 'baz'
      QUnit.start()
    else
      hasCalledRoute = yes
      params.bar = 'baz'
      Batman.redirect params

  @App.run()

  Batman.redirect '/?foo=bar&x=true'

asyncTest 'route match with default params', 2, ->
  @App.root controller: 'test', action: 'index'
  @App.route 'show', controller: 'products', action: 'show', id: 1
  @App.run()
  equal @App.test('/'), @App.TestController::index
  Batman.redirect '/show'

asyncTest 'resources', ->
  class @App.ImagesController extends Batman.Controller
    index: (params) ->
      equal params.productId, '1', 'index correct'
      @redirect '/products/1/images/2'
    show: (params) ->
      equal params.productId, '1', 'show product correct'
      equal params.id, '2', 'show image correct'
      @redirect '/saved_searches/5'

  class @App.SavedSearchesController extends Batman.Controller
    index: ->

    show: (params) ->
      equal params.id, '5'
      @redirect '/products/1'

  @App.resources 'products', ->
    @resources 'images'
    @collection 'testCollection'
    @member 'test', 'testMember', {action: 'testMember'}

  @App.resources 'saved_searches'

  @App.ProductsController::testCollection = -> @render false
  @App.ProductsController::testMember = -> @render false

  equal @App.test('/products'), @App.ProductsController::index
  equal typeof @App.test('/products/new'), 'undefined'
  equal @App.test('/products/1'), @App.ProductsController::show
  equal @App.test('/products/1/edit'), @App.ProductsController::edit

  equal @App.test('/saved_searches'), @App.SavedSearchesController::index
  equal @App.test('/saved_searches/10'), @App.SavedSearchesController::show

  equal @App.test('/products/testCollection'), @App.ProductsController::testCollection
  equal @App.test('/products/1/testMember'), @App.ProductsController::testMember
  equal @App.test('/products/1/test'), @App.ProductsController::testMember

  @App.run()

  setTimeout ->
    Batman.redirect '/products/1/images'
  , ASYNC_TEST_DELAY

asyncTest 'hash history', 1, ->
  Batman.config.usePushState = false

  setTimeout =>
    class @App extends Batman.App
    @App.route 'test', ->
      window.location.hash = '#!/test2'

    @App.route 'test2', ->
      ok true, 'routes called'
      QUnit.start()

    window.location.hash = '#!/test'

    @App.run()
  , ASYNC_TEST_DELAY

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

  Batman.redirect 'something/random'

asyncTest '404 when redirecting to a record', 1, ->
  @App.route '404', ->
    ok true, '404 called'
    QUnit.start()
  @App.run()
  @product = new @App.Product(id: 1)
  Batman.redirect @product

